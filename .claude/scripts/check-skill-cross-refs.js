#!/usr/bin/env node
/**
 * check-skill-cross-refs.js
 *
 * CI gate: verifies that explicit skill:<name> references in markdown files
 * point to a registered skill name from SKILL.md frontmatter.
 *
 * Usage: node scripts/check-skill-cross-refs.js
 * Exit 0 = all references valid (or no references found)
 * Exit 1 = broken references or collisions found
 */

'use strict';

const { readFileSync, readdirSync, lstatSync } = require('fs');
const path = require('path');

const repoRoot = path.resolve(__dirname, '..');
const claudeDir = repoRoot;

// Optional explicit cross-reference marker for docs that need validation.
const SKILL_REF_RE = /skill:([a-z][a-z0-9-]*)/g;

/**
 * Recursively collect all files matching a predicate under a directory.
 */
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
    // Skip symlinks to prevent traversal outside the repo
    if (stat.isSymbolicLink()) continue;
    if (stat.isDirectory()) {
      results.push(...findFiles(full, predicate));
    } else if (predicate(entry, full)) {
      results.push(full);
    }
  }
  return results;
}

/**
 * Parses YAML frontmatter from a SKILL.md file and extracts the `name:` field.
 * Returns null if not found.
 */
function extractSkillName(content) {
  // Match YAML frontmatter block: --- ... ---
  const fmMatch = content.match(/^---\s*\n([\s\S]*?)\n---/);
  if (!fmMatch) return null;

  const frontmatter = fmMatch[1];
  // Extract name: value (unquoted or single/double quoted)
  const nameMatch = frontmatter.match(/^name:\s*['"]?([^\s'"]+)['"]?\s*$/m);
  if (!nameMatch) return null;

  return nameMatch[1].trim();
}

/**
 * Builds the canonical skill registry from all skills/<skillname>/SKILL.md files.
 * Returns { registry: Set<string>, duplicates: Array<{name, file}> }
 */
function buildSkillRegistry() {
  const skillsDir = path.join(claudeDir, 'skills');
  const skillFiles = findFiles(skillsDir, (entry) => entry === 'SKILL.md');

  const registry = new Set();
  const duplicates = [];

  for (const filePath of skillFiles) {
    let content;
    try {
      content = readFileSync(filePath, 'utf8');
    } catch (err) {
      console.error(`[!] Could not read ${filePath}: ${err.message}`);
      continue;
    }

    const rawName = extractSkillName(content);
    if (!rawName) {
      // No name in frontmatter — skip silently (not our concern here)
      continue;
    }

    const name = rawName;
    if (registry.has(name)) {
      duplicates.push({ name, file: path.relative(repoRoot, filePath) });
    }
    registry.add(name);
  }

  return { registry, duplicates };
}

/**
 * Scans all .md files and collects explicit skill:<name> references.
 * Returns Array<{ ref: string, file: string, line: number }>
 */
function collectSkillReferences() {
  const mdFiles = findFiles(claudeDir, (entry) => entry.endsWith('.md'));
  const refs = [];

  for (const filePath of mdFiles) {
    let content;
    try {
      content = readFileSync(filePath, 'utf8');
    } catch (err) {
      console.error(`[!] Could not read ${filePath}: ${err.message}`);
      continue;
    }

    const lines = content.split('\n');
    lines.forEach((line, idx) => {
      let match;
      // Reset lastIndex for global regex reuse
      SKILL_REF_RE.lastIndex = 0;
      while ((match = SKILL_REF_RE.exec(line)) !== null) {
        refs.push({
          ref: match[1],
          file: path.relative(repoRoot, filePath),
          line: idx + 1,
        });
      }
    });
  }

  return refs;
}

function main() {
  const { registry, duplicates } = buildSkillRegistry();
  const allRefs = collectSkillReferences();

  let hasErrors = false;

  // Report duplicate skill identifiers
  if (duplicates.length > 0) {
    hasErrors = true;
    console.error('[X] Duplicate skill name(s):');
    for (const { name, file } of duplicates) {
      console.error(`  - ${name}  (defined in ${file})`);
    }
    console.error('');
  }

  // Check each reference against registry
  const broken = allRefs.filter(({ ref }) => !registry.has(ref));

  if (broken.length > 0) {
    hasErrors = true;
    console.error('[X] Broken skill references (not registered in any SKILL.md):');
    for (const { ref, file, line } of broken) {
      console.error(`  - ${ref}  at ${file}:${line}`);
    }
    console.error('');
    console.error('Registered skills:', [...registry].sort().join(', ') || '(none)');
  }

  if (!hasErrors) {
    const refCount = allRefs.length;
    const skillCount = registry.size;
    console.log(`[OK] skill-cross-refs: ${skillCount} skill(s) registered, ${refCount} reference(s) checked — all valid.`);
    process.exit(0);
  }

  process.exit(1);
}

main();
