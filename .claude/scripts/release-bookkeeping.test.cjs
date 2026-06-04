'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');

const {
  computeNextBetaVersion,
  findLatestStableVersion,
  parseClosingIssueNumbers,
  parsePullNumbersFromMergeSubjects,
} = require('./release-bookkeeping-helpers.cjs');

test('parseClosingIssueNumbers only accepts closing keywords', () => {
  const body = [
    'Closes #704',
    'Fixes: #707, #709 and #713',
    'Resolved #78; closed #715',
    'Part of #711',
    'Refs #77',
    'See claudekit-docs#156',
    'This fixes bug #999',
    'Random 123',
  ].join('\n');

  assert.deepEqual(parseClosingIssueNumbers(body), [78, 704, 707, 709, 713, 715]);
});

test('parseClosingIssueNumbers deduplicates repeated refs', () => {
  assert.deepEqual(parseClosingIssueNumbers('closes #1\nFixes #1, #2'), [1, 2]);
});

test('parsePullNumbersFromMergeSubjects reads merge commit subjects only', () => {
  const subjects = [
    'Merge pull request #706 from claudekit/kai/fix/foo',
    'merge PR #708 from claudekit/kai/fix/bar',
    'fix: update docs (#709)',
    'Merge branch dev into main',
  ].join('\n');

  assert.deepEqual(parsePullNumbersFromMergeSubjects(subjects), [706, 708]);
});

test('findLatestStableVersion ignores prerelease tags', () => {
  assert.deepEqual(findLatestStableVersion(['v2.17.0-beta.10', 'v2.16.2', 'v2.17.0']), {
    major: 2,
    minor: 17,
    patch: 0,
  });
});

test('computeNextBetaVersion advances patch when stable catches up to beta base', () => {
  assert.deepEqual(computeNextBetaVersion('2.17.0', ['v2.17.0-beta.10', 'v2.17.0']), {
    stable: '2.17.0',
    version: '2.17.1-beta.1',
  });
});

test('computeNextBetaVersion continues highest beta line ahead of stable', () => {
  assert.deepEqual(
    computeNextBetaVersion('v2.17.0', ['v2.17.0-beta.10', 'v2.18.0-beta.1']),
    {
      stable: '2.17.0',
      version: '2.18.0-beta.2',
    },
  );
});

test('computeNextBetaVersion advances patch when no beta tags ahead of stable', () => {
  assert.deepEqual(computeNextBetaVersion('v3.0.0', ['v2.18.0-beta.1']), {
    stable: '3.0.0',
    version: '3.0.1-beta.1',
  });
});

test('computeNextBetaVersion bumps patch past released stable when beta lags', () => {
  assert.deepEqual(
    computeNextBetaVersion('2.18.0', ['v2.18.0-beta.1', 'v2.18.0']),
    {
      stable: '2.18.0',
      version: '2.18.1-beta.1',
    },
  );
});
