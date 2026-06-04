#!/usr/bin/env node
/**
 * check-skill-descriptions.js
 *
 * Lint over .claude/skills/<name>/SKILL.md frontmatter metadata.
 * Blocks major policy findings and leaves minor description guidance non-blocking.
 * Surfaces patterns that hurt agent routing or skill listing budget:
 *
 *   - "Use this when..." / "Use this skill..." (instructional, not capability-led)
 *   - Maintainer-only markers ([KAI], "maintainer-only", etc.)
 *   - TODO / FIXME / XXX / WIP markers
 *   - Very short (<50 chars) or very long (>512 chars) descriptions
 *   - Missing `description:` field entirely (auto-emitted as a major-severity
 *     finding with rule id `missing-description`; allowlistable like any other rule)
 *   - Missing `user-invocable: true` on shipped skills
 *   - `disable-model-invocation: true` on shipped skills
 *   - Missing or risky project skill listing budget settings
 *   - Project settings that hide skills with `skillOverrides`
 *
 * Allowlist (`scripts/skill-description-lint-allowlist.json`) lets specific
 * skills opt out of specific rules with required `reason`. Rule IDs in
 * allowlist entries are validated at load time — unknown IDs error out
 * (catches typos like "too_short" vs "too-short").
 *
 * Usage: node scripts/check-skill-descriptions.js
 * Exit 1 on major policy findings; exit 0 for minor guidance only.
 */

'use strict';

const { readFileSync, readdirSync, lstatSync } = require('fs');
const path = require('path');
const { validateReason } = require('./lib/validate-allowlist-reason.js');

const repoRoot = path.resolve(__dirname, '..');
const claudeDir = repoRoot;
const allowlistPath = path.join(__dirname, 'skill-description-lint-allowlist.json');
const settingsPath = path.join(claudeDir, 'settings.json');

const RECOMMENDED_DESC_CHARS = 200;
const MAX_LISTING_DESC_CHARS = 512;
const MIN_SKILL_LISTING_BUDGET_FRACTION = 0.03;
const CONTEXT_FLOOR_TOKENS = 200_000;
const CHARS_PER_TOKEN = 4;

const RULES = [
  {
    id: 'use-this-prefix',
    severity: 'minor',
    test: (desc) => /^\s*Use\s+this\s+(when|skill|for|to)\b/i.test(desc),
    message:
      'Starts with "Use this when/skill/for/to" — instructional, not capability-led. Lead with what the skill DOES ("Build X", "Run Y", "Analyze Z").',
  },
  {
    id: 'maintainer-marker',
    severity: 'major',
    test: (desc) => /\[KAI\]|maintainer[- ]only|for\s+kai\b|kai[- ]only/i.test(desc),
    message:
      'Contains maintainer-only marker. If shipped to all users, drop the marker. If genuinely maintainer-only, move it out of the shipped skills catalog.',
  },
  {
    id: 'todo-marker',
    severity: 'major',
    test: (desc) => /\b(TODO|FIXME|XXX|WIP)\b/.test(desc),
    message: 'Contains TODO/FIXME/XXX/WIP. Resolve or remove before shipping.',
  },
  {
    id: 'too-short',
    severity: 'minor',
    test: (desc) => desc.trim().length < 50,
    message:
      'Very short (<50 chars). Add trigger keywords or example use cases so users can match intent.',
  },
  {
    id: 'too-long',
    severity: 'minor',
    test: (desc) => desc.trim().length > MAX_LISTING_DESC_CHARS,
    message:
      `Very long (>${MAX_LISTING_DESC_CHARS} chars). Hosts may truncate or omit it from the skill listing; trim to the routing signal.`,
  },
];

function findFiles(dir, predicate) {
  const results = [];
  let entries;
  try {
    entries = readdirSync(dir);
  } catch {
    return results;
  }
  for (const entry of entries) {
    const full = path.join(dir, entry);
    let stat;
    try {
      stat = lstatSync(full);
    } catch {
      continue;
    }
    if (stat.isSymbolicLink()) continue;
    if (stat.isDirectory()) {
      results.push(...findFiles(full, predicate));
    } else if (predicate(entry, full)) {
      results.push(full);
    }
  }
  return results;
}

// Sentinel returned when frontmatter block (---...---) is absent or unclosed.
// Distinct from `null` which means "block parsed but field missing" — lets
// the caller emit a `frontmatter-parse-error` finding instead of the
// generic `missing-description` one.
const FRONTMATTER_PARSE_ERROR = Symbol('frontmatter-parse-error');

function extractFrontmatterField(content, field) {
  const fmMatch = content.match(/^---\s*\n([\s\S]*?)\n---/);
  if (!fmMatch) return FRONTMATTER_PARSE_ERROR;
  const fm = fmMatch[1];
  // Match `field:` followed by the value. Supports:
  //   field: value
  //   field: "value"
  //   field: 'value'
  //   field: >- / > (folded scalar — newlines collapse to spaces)
  //   field: |- / |  (literal block scalar — newlines preserved, joined with space here
  //                   since description is rendered as a single line)
  const re = new RegExp(`^${field}:\\s*(.*)$`, 'm');
  const m = fm.match(re);
  if (!m) return null;
  let value = m[1].trim();

  // Block scalar (folded `>`/`>-` or literal `|`/`|-`): collect indented continuation
  // lines. For a single-line description rendering, both styles join with spaces.
  if (value === '>-' || value === '>' || value === '|-' || value === '|') {
    const lines = fm.split('\n');
    const idx = lines.findIndex((l) => l.match(re));
    const collected = [];
    for (let i = idx + 1; i < lines.length; i++) {
      const line = lines[i];
      if (/^\S/.test(line)) break; // unindented = next field
      collected.push(line.trim());
    }
    return collected.join(' ').trim();
  }

  // Strip surrounding quotes if present
  if (
    (value.startsWith('"') && value.endsWith('"')) ||
    (value.startsWith("'") && value.endsWith("'"))
  ) {
    value = value.slice(1, -1);
  }
  return value;
}

function extractName(content) {
  const raw = extractFrontmatterField(content, 'name');
  if (!raw || raw === FRONTMATTER_PARSE_ERROR) return null;
  return normalizeSkillName(raw);
}

// Known rule IDs (RULES array + auto-emitted findings).
// Used to validate allowlist entries — typo'd rule IDs error out instead of
// silently being ignored.
const KNOWN_RULE_IDS = new Set([
  ...RULES.map((r) => r.id),
  'missing-description',
  'missing-when-to-use',
  'frontmatter-parse-error',
  'missing-user-invocable-visibility',
  'disabled-model-invocation',
  'missing-skill-listing-budget',
  'low-skill-listing-budget',
  'missing-skill-description-cap',
  'high-skill-description-cap',
  'forbidden-skill-overrides',
]);

function loadAllowlist() {
  let raw;
  try {
    raw = readFileSync(allowlistPath, 'utf8');
  } catch {
    return new Map();
  }
  let parsed;
  try {
    parsed = JSON.parse(raw);
  } catch (err) {
    console.error(`[X] Invalid JSON in allowlist: ${err.message}`);
    process.exit(1);
  }
  // Map<skillName, Set<ruleId>>
  const map = new Map();
  if (Array.isArray(parsed.allowed)) {
    for (const entry of parsed.allowed) {
      if (!entry || typeof entry.skill !== 'string') continue;
      if (!Array.isArray(entry.rules)) continue;
      const reasonResult = validateReason(entry.reason);
      if (!reasonResult.ok) {
        console.error(`[X] Allowlist entry "${entry.skill}" ${reasonResult.error}`);
        process.exit(1);
      }
      // Validate rule IDs — catch typos before they silently allow nothing.
      const unknown = entry.rules.filter((id) => !KNOWN_RULE_IDS.has(id));
      if (unknown.length > 0) {
        console.error(
          `[X] Allowlist entry "${entry.skill}" lists unknown rule ID(s): ${unknown.join(', ')}`
        );
        console.error(`    Known rule IDs: ${[...KNOWN_RULE_IDS].sort().join(', ')}`);
        process.exit(1);
      }
      map.set(entry.skill, new Set(entry.rules));
    }
  }
  return map;
}

function normalizeSkillName(rawName) {
  if (!rawName || rawName === FRONTMATTER_PARSE_ERROR) return null;
  return rawName;
}

function formatSkillLabel(rawName, normalizedName) {
  return rawName || normalizedName;
}

function readSettings() {
  try {
    return JSON.parse(readFileSync(settingsPath, 'utf8'));
  } catch (err) {
    return { __readError: err.message };
  }
}

function isValidBudgetFraction(value) {
  return typeof value === 'number' && value > 0 && value <= 1;
}

function isValidMaxDescChars(value) {
  return Number.isInteger(value) && value > 0;
}

function estimateListingChars(skills, maxDescChars) {
  if (skills.length === 0) return 0;
  return skills.reduce((sum, skill) => {
    return sum + skill.name.length + 4 + Math.min(skill.description.length, maxDescChars);
  }, skills.length - 1);
}

function combineListingText(description, whenToUse) {
  if (!whenToUse || whenToUse === FRONTMATTER_PARSE_ERROR) return description;
  return `${description} ${whenToUse}`.trim();
}

function requiredBudgetFraction(listingChars) {
  if (listingChars <= 0) return MIN_SKILL_LISTING_BUDGET_FRACTION;
  const raw = listingChars / (CONTEXT_FLOOR_TOKENS * CHARS_PER_TOKEN);
  return Math.min(
    1,
    Math.max(MIN_SKILL_LISTING_BUDGET_FRACTION, Math.ceil(raw * 1000) / 1000)
  );
}

function formatPercent(fraction) {
  return `${Number((fraction * 100).toFixed(1))}%`;
}

function validateSkillListingSettings(settings, skills) {
  const findings = [];
  const file = path.relative(repoRoot, settingsPath);

  if (settings.__readError) {
    findings.push({
      label: '.claude/settings.json',
      file,
      ruleId: 'missing-skill-listing-budget',
      severity: 'major',
      message: `Could not read skill listing settings: ${settings.__readError}`,
      snippet: '',
    });
    return findings;
  }

  if (Object.prototype.hasOwnProperty.call(settings, 'skillOverrides')) {
    findings.push({
      label: '.claude/settings.json',
      file,
      ruleId: 'forbidden-skill-overrides',
      severity: 'major',
      message:
        'Do not configure skillOverrides for shipped Engineer skills. Keep skills user-invocable and manage listing pressure with budget settings and bounded descriptions.',
      snippet: '',
    });
  }

  const maxDescForEstimate = isValidMaxDescChars(settings.skillListingMaxDescChars)
    ? Math.min(settings.skillListingMaxDescChars, MAX_LISTING_DESC_CHARS)
    : MAX_LISTING_DESC_CHARS;
  const projectedListingChars = estimateListingChars(skills, maxDescForEstimate);
  const requiredFraction = requiredBudgetFraction(projectedListingChars);
  const budgetFraction = settings.skillListingBudgetFraction;
  if (budgetFraction === undefined) {
    findings.push({
      label: '.claude/settings.json',
      file,
      ruleId: 'missing-skill-listing-budget',
      severity: 'major',
      message: `Missing skillListingBudgetFraction. Default to ${requiredFraction} so shipped Engineer skills fit a ${CONTEXT_FLOOR_TOKENS.toLocaleString()} token context floor.`,
      snippet: '',
    });
  } else if (!isValidBudgetFraction(budgetFraction) || budgetFraction < requiredFraction) {
    findings.push({
      label: '.claude/settings.json',
      file,
      ruleId: 'low-skill-listing-budget',
      severity: 'major',
      message: `skillListingBudgetFraction must be >= ${requiredFraction}; got ${JSON.stringify(budgetFraction)}. Projected shipped skill listing is ${projectedListingChars} chars (~${Math.ceil(projectedListingChars / CHARS_PER_TOKEN)} tokens), ${formatPercent(requiredFraction)} of a ${CONTEXT_FLOOR_TOKENS.toLocaleString()} token context floor.`,
      snippet: '',
    });
  }

  const maxDescChars = settings.skillListingMaxDescChars;
  if (maxDescChars === undefined) {
    findings.push({
      label: '.claude/settings.json',
      file,
      ruleId: 'missing-skill-description-cap',
      severity: 'major',
      message: `Missing skillListingMaxDescChars. Default to ${MAX_LISTING_DESC_CHARS} to keep individual descriptions bounded.`,
      snippet: '',
    });
  } else if (
    !isValidMaxDescChars(maxDescChars) ||
    maxDescChars > MAX_LISTING_DESC_CHARS
  ) {
    findings.push({
      label: '.claude/settings.json',
      file,
      ruleId: 'high-skill-description-cap',
      severity: 'major',
      message: `skillListingMaxDescChars must be a positive integer <= ${MAX_LISTING_DESC_CHARS}; got ${JSON.stringify(maxDescChars)}.`,
      snippet: '',
    });
  }

  return findings;
}

function main() {
  const skillsDir = path.join(claudeDir, 'skills');
  const skillFiles = findFiles(skillsDir, (entry) => entry === 'SKILL.md');
  const allowlist = loadAllowlist();
  const settings = readSettings();

  const findings = []; // {skill, file, ruleId, severity, message, snippet}
  let scanned = 0;
  const descriptions = [];
  const skillEntries = [];

  for (const filePath of skillFiles) {
    let content;
    try {
      content = readFileSync(filePath, 'utf8');
    } catch (err) {
      console.error(`[!] Could not read ${filePath}: ${err.message}`);
      continue;
    }
    const rawName = extractFrontmatterField(content, 'name');
    const name = normalizeSkillName(rawName);
    if (!name) {
      // Could be a non-shipped skill OR malformed frontmatter. Distinguish: try
      // to read the name field directly. If extractFrontmatterField returns
      // the sentinel, the frontmatter block itself failed to parse — emit a
      // distinct finding so authors can debug instead of silently skipping.
      if (rawName === FRONTMATTER_PARSE_ERROR) {
        findings.push({
          label: path.basename(path.dirname(filePath)),
          file: path.relative(repoRoot, filePath),
          ruleId: 'frontmatter-parse-error',
          severity: 'major',
          message:
            'Frontmatter block missing or unclosed. Expected `---`-delimited block at top of file.',
          snippet: '',
        });
        scanned++;
      }
      continue;
    }

    const description = extractFrontmatterField(content, 'description');
    if (description === FRONTMATTER_PARSE_ERROR) {
      // Defensive — extractName already handled this above, but keep the
      // branch for clarity if call order ever changes.
      findings.push({
        label: formatSkillLabel(rawName, name),
        file: path.relative(repoRoot, filePath),
        ruleId: 'frontmatter-parse-error',
        severity: 'major',
        message: 'Frontmatter block missing or unclosed.',
        snippet: '',
      });
      scanned++;
      continue;
    }
    if (!description) {
      findings.push({
        label: formatSkillLabel(rawName, name),
        file: path.relative(repoRoot, filePath),
        ruleId: 'missing-description',
        severity: 'major',
        message: 'No `description:` field in frontmatter.',
        snippet: '',
      });
      scanned++;
      continue;
    }
    scanned++;
    const whenToUse = extractFrontmatterField(content, 'when_to_use');
    if (!whenToUse || whenToUse === FRONTMATTER_PARSE_ERROR) {
      findings.push({
        label: formatSkillLabel(rawName, name),
        file: path.relative(repoRoot, filePath),
        ruleId: 'missing-when-to-use',
        severity: 'major',
        message:
          'Shipped skills must set concise `when_to_use` metadata so agent routing context stays explicit and budgeted.',
        snippet: '',
      });
    }
    const listingText = combineListingText(description, whenToUse);
    descriptions.push(listingText);
    skillEntries.push({ name: rawName, description: listingText });

    const skillAllowed = allowlist.get(name) || new Set();
    const userInvocable = extractFrontmatterField(content, 'user-invocable');
    if (!skillAllowed.has('missing-user-invocable-visibility') && userInvocable !== 'true') {
      findings.push({
        label: formatSkillLabel(rawName, name),
        file: path.relative(repoRoot, filePath),
        ruleId: 'missing-user-invocable-visibility',
        severity: 'major',
        message:
          'Shipped skills must set `user-invocable: true`; control listing pressure with budget settings and bounded descriptions, not hidden skills.',
        snippet: '',
      });
    }
    const disableModelInvocation = extractFrontmatterField(content, 'disable-model-invocation');
    if (
      !skillAllowed.has('disabled-model-invocation') &&
      disableModelInvocation === 'true'
    ) {
      findings.push({
        label: formatSkillLabel(rawName, name),
        file: path.relative(repoRoot, filePath),
        ruleId: 'disabled-model-invocation',
        severity: 'major',
        message:
          'Shipped skills must stay agent-invocable; omit `disable-model-invocation` or set it to false.',
        snippet: '',
      });
    }

    for (const rule of RULES) {
      if (skillAllowed.has(rule.id)) continue;
      if (rule.test(listingText)) {
        findings.push({
          label: formatSkillLabel(rawName, name),
          file: path.relative(repoRoot, filePath),
          ruleId: rule.id,
          severity: rule.severity,
          message: rule.message,
          snippet: listingText.slice(0, 100) + (listingText.length > 100 ? '...' : ''),
        });
      }
    }
  }

  findings.push(...validateSkillListingSettings(settings, skillEntries));

  // Group by severity
  const major = findings.filter((f) => f.severity === 'major');
  const minor = findings.filter((f) => f.severity === 'minor');
  const totalDescChars = descriptions.reduce((sum, desc) => sum + desc.length, 0);
  const cappedDescChars = descriptions.reduce(
    (sum, desc) => sum + Math.min(desc.length, settings.skillListingMaxDescChars || desc.length),
    0
  );
  const projectedListingChars = estimateListingChars(
    skillEntries,
    isValidMaxDescChars(settings.skillListingMaxDescChars)
      ? Math.min(settings.skillListingMaxDescChars, MAX_LISTING_DESC_CHARS)
      : MAX_LISTING_DESC_CHARS
  );
  const requiredFraction = requiredBudgetFraction(projectedListingChars);
  const overRecommended = descriptions.filter((desc) => desc.length > RECOMMENDED_DESC_CHARS).length;
  const overCap = descriptions.filter((desc) => desc.length > MAX_LISTING_DESC_CHARS).length;

  console.log(
    `[i] skill inventory: ${scanned} skill description(s), ${totalDescChars} char(s) total, ${overRecommended} over ${RECOMMENDED_DESC_CHARS} chars, ${overCap} over ${MAX_LISTING_DESC_CHARS} chars.`
  );
  console.log(
    `[i] skill listing settings: skillListingBudgetFraction=${JSON.stringify(settings.skillListingBudgetFraction)}, skillListingMaxDescChars=${JSON.stringify(settings.skillListingMaxDescChars)}, projected listed description chars=${cappedDescChars}, projected listing chars=${projectedListingChars} (~${Math.ceil(projectedListingChars / CHARS_PER_TOKEN)} tokens), requiredFractionFor200k=${requiredFraction}.\n`
  );

  if (findings.length === 0) {
    console.log(
      `[OK] skill-descriptions: ${scanned} skill description(s) scanned — no warnings.`
    );
    process.exit(0);
  }

  console.log(
    `[i] skill-descriptions: ${scanned} description(s) scanned, ${findings.length} warning(s) (${major.length} major, ${minor.length} minor).\n`
  );

  if (major.length > 0) {
    console.log(`[!] Major warnings (${major.length}):`);
    for (const f of major) {
      console.log(`  - ${f.label}  [${f.ruleId}]  ${f.message}`);
      console.log(`    ${f.file}`);
      if (f.snippet) console.log(`    > ${f.snippet}`);
    }
    console.log('');
  }

  if (minor.length > 0) {
    console.log(`[i] Minor warnings (${minor.length}):`);
    for (const f of minor) {
      console.log(`  - ${f.label}  [${f.ruleId}]  ${f.message}`);
      console.log(`    ${f.file}`);
      if (f.snippet) console.log(`    > ${f.snippet}`);
    }
    console.log('');
  }

  console.log(
    major.length > 0
      ? 'Major policy findings are blocking. Minor description warnings remain non-blocking.'
      : 'Minor description warnings are non-blocking.'
  );

  process.exit(major.length > 0 ? 1 : 0);
}

if (require.main === module) {
  main();
}

module.exports = {
  RULES,
  KNOWN_RULE_IDS,
  FRONTMATTER_PARSE_ERROR,
  CONTEXT_FLOOR_TOKENS,
  CHARS_PER_TOKEN,
  MAX_LISTING_DESC_CHARS,
  MIN_SKILL_LISTING_BUDGET_FRACTION,
  combineListingText,
  estimateListingChars,
  requiredBudgetFraction,
  validateSkillListingSettings,
  extractFrontmatterField,
  extractName,
};
