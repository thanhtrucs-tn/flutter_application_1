'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');

const {
  RULES,
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
  KNOWN_RULE_IDS,
} = require('./check-skill-descriptions.js');

const useThisRule = RULES.find((r) => r.id === 'use-this-prefix');
const tooLongRule = RULES.find((r) => r.id === 'too-long');

test('use-this-prefix: catches "Use this when"', () => {
  assert.equal(useThisRule.test('Use this when X happens'), true);
});

test('use-this-prefix: catches "Use this skill"', () => {
  assert.equal(useThisRule.test('Use this skill for X'), true);
});

test('use-this-prefix: catches widened "Use this for"', () => {
  assert.equal(useThisRule.test('Use this for building X'), true);
});

test('use-this-prefix: catches widened "Use this to"', () => {
  assert.equal(useThisRule.test('Use this to do X'), true);
});

test('use-this-prefix: does NOT catch capability-led prefix', () => {
  assert.equal(useThisRule.test('Build X with Y'), false);
  assert.equal(useThisRule.test('Run tests'), false);
});

test('use-this-prefix: does NOT match "Use this" with no preposition (still kept narrow on the word boundary)', () => {
  // After widening: any of when|skill|for|to followed by word boundary.
  // "Use this approach" has none of the four — should NOT match.
  assert.equal(useThisRule.test('Use this approach to coding'), false);
});

test('too-long: catches descriptions above ClaudeKit recommended listing cap', () => {
  assert.equal(tooLongRule.test('x'.repeat(513)), true);
});

test('too-long: allows descriptions at ClaudeKit recommended listing cap', () => {
  assert.equal(tooLongRule.test('x'.repeat(512)), false);
});

test('estimateListingChars: includes skill ids, separators, and capped descriptions', () => {
  const skills = [
    { name: 'cook', description: 'x'.repeat(600) },
    { name: 'test', description: 'short' },
  ];

  assert.equal(
    estimateListingChars(skills, MAX_LISTING_DESC_CHARS),
    'cook'.length + 4 + MAX_LISTING_DESC_CHARS + 1 + 'test'.length + 4 + 'short'.length
  );
});

test('requiredBudgetFraction: keeps the 3 percent floor for current-sized inventories', () => {
  assert.equal(requiredBudgetFraction(18_623), MIN_SKILL_LISTING_BUDGET_FRACTION);
});

test('requiredBudgetFraction: rounds larger inventories up against the 200k context floor', () => {
  const listingChars = Math.ceil(CONTEXT_FLOOR_TOKENS * CHARS_PER_TOKEN * 0.0381);

  assert.equal(requiredBudgetFraction(listingChars), 0.039);
});

test('combineListingText: includes when_to_use in the listing estimate', () => {
  assert.equal(
    combineListingText('Build and test APIs.', 'Use when changing backend endpoints.'),
    'Build and test APIs. Use when changing backend endpoints.'
  );
});

test('known rule ids include missing when_to_use policy', () => {
  assert.equal(KNOWN_RULE_IDS.has('missing-when-to-use'), true);
});

test('validateSkillListingSettings: rejects missing listing settings', () => {
  const findings = validateSkillListingSettings({}, [
    { name: 'cook', description: 'x'.repeat(100) },
  ]);

  assert.deepEqual(
    findings.map((finding) => finding.ruleId).sort(),
    ['missing-skill-description-cap', 'missing-skill-listing-budget']
  );
});

test('validateSkillListingSettings: rejects low listing budget computed from inventory size', () => {
  const skills = Array.from({ length: 60 }, (_, index) => ({
    name: `skill-${index}`,
    description: 'x'.repeat(500),
  }));
  const findings = validateSkillListingSettings(
    { skillListingBudgetFraction: 0.03, skillListingMaxDescChars: 512 },
    skills
  );

  assert.equal(findings.some((finding) => finding.ruleId === 'low-skill-listing-budget'), true);
  assert.match(findings[0].message, />= 0\.039/);
});

test('validateSkillListingSettings: rejects skillOverrides policy', () => {
  const findings = validateSkillListingSettings(
    {
      skillListingBudgetFraction: 0.03,
      skillListingMaxDescChars: 512,
      skillOverrides: { cook: { enabled: false } },
    },
    [{ name: 'cook', description: 'x'.repeat(100) }]
  );

  assert.equal(findings.some((finding) => finding.ruleId === 'forbidden-skill-overrides'), true);
});

test('extractFrontmatterField: returns sentinel when frontmatter block absent', () => {
  const content = '# Just a heading\n\nNo frontmatter at all.';
  assert.equal(extractFrontmatterField(content, 'description'), FRONTMATTER_PARSE_ERROR);
});

test('extractFrontmatterField: returns sentinel when frontmatter unclosed', () => {
  const content = '---\nname: foo\ndescription: bar\n\nNo closing dashes.';
  assert.equal(extractFrontmatterField(content, 'description'), FRONTMATTER_PARSE_ERROR);
});

test('extractFrontmatterField: returns null when block parsed but field absent', () => {
  const content = '---\nname: foo\n---\nbody';
  assert.equal(extractFrontmatterField(content, 'description'), null);
});

test('extractFrontmatterField: parses simple inline value', () => {
  const content = '---\ndescription: Build X with Y.\n---\nbody';
  assert.equal(extractFrontmatterField(content, 'description'), 'Build X with Y.');
});

test('extractFrontmatterField: strips double quotes', () => {
  const content = '---\ndescription: "Build X."\n---\nbody';
  assert.equal(extractFrontmatterField(content, 'description'), 'Build X.');
});

test('extractFrontmatterField: strips single quotes', () => {
  const content = "---\ndescription: 'Build X.'\n---\nbody";
  assert.equal(extractFrontmatterField(content, 'description'), 'Build X.');
});

test('extractFrontmatterField: handles folded scalar `>-`', () => {
  const content = [
    '---',
    'description: >-',
    '  First line.',
    '  Second line.',
    '---',
    'body',
  ].join('\n');
  assert.equal(extractFrontmatterField(content, 'description'), 'First line. Second line.');
});

test('extractFrontmatterField: handles folded scalar `>`', () => {
  const content = [
    '---',
    'description: >',
    '  Folded text.',
    '---',
    'body',
  ].join('\n');
  assert.equal(extractFrontmatterField(content, 'description'), 'Folded text.');
});

test('extractFrontmatterField: handles literal block scalar `|` (NEW — was previously broken)', () => {
  const content = [
    '---',
    'description: |',
    '  Literal block scalar.',
    '  Second line preserved.',
    '---',
    'body',
  ].join('\n');
  assert.equal(
    extractFrontmatterField(content, 'description'),
    'Literal block scalar. Second line preserved.'
  );
});

test('extractFrontmatterField: handles literal block scalar `|-`', () => {
  const content = [
    '---',
    'description: |-',
    '  Stripped literal.',
    '---',
    'body',
  ].join('\n');
  assert.equal(extractFrontmatterField(content, 'description'), 'Stripped literal.');
});

test('extractName: returns null on parse error', () => {
  const content = 'no frontmatter';
  assert.equal(extractName(content), null);
});

test('extractName: returns portable skill name unchanged', () => {
  const content = '---\nname: foo\n---\nbody';
  assert.equal(extractName(content), 'foo');
});

test('extractName: returns bare name unchanged', () => {
  const content = '---\nname: bar\n---\nbody';
  assert.equal(extractName(content), 'bar');
});
