'use strict';

const assert = require('node:assert/strict');
const { mkdtempSync, mkdirSync, rmSync, writeFileSync } = require('fs');
const { tmpdir } = require('os');
const path = require('path');
const test = require('node:test');

const { findLiveDeletionConflicts, matchesDeletion } = require('./check-metadata-deletions.js');

test('findLiveDeletionConflicts reports deletion entries that still ship payload files', () => {
  const sourceRoot = mkdtempSync(path.join(tmpdir(), 'ck-metadata-live-'));

  try {
    mkdirSync(path.join(sourceRoot, 'hooks'), { recursive: true });
    mkdirSync(path.join(sourceRoot, 'skills', 'retired', 'scripts'), { recursive: true });
    writeFileSync(path.join(sourceRoot, 'hooks', 'session-init.cjs'), 'module.exports = {};\n');
    writeFileSync(path.join(sourceRoot, 'skills', 'retired', 'scripts', 'tool.js'), 'console.log("live");\n');

    assert.deepEqual(
      findLiveDeletionConflicts(
        [
          'hooks/session-init.cjs',
          'hooks/missing.cjs',
          'skills/retired',
          'skills/missing/**',
        ],
        sourceRoot,
      ),
      ['hooks/session-init.cjs', 'skills/retired'],
    );
  } finally {
    rmSync(sourceRoot, { recursive: true, force: true });
  }
});

test('findLiveDeletionConflicts permits maintainer-only command archive pruning', () => {
  const sourceRoot = mkdtempSync(path.join(tmpdir(), 'ck-metadata-archive-'));

  try {
    mkdirSync(path.join(sourceRoot, 'command-archive', 'help'), { recursive: true });
    writeFileSync(path.join(sourceRoot, 'command-archive', 'help', 'SKILL.md'), '# archived\n');

    assert.deepEqual(findLiveDeletionConflicts(['command-archive/**'], sourceRoot), []);
  } finally {
    rmSync(sourceRoot, { recursive: true, force: true });
  }
});

test('matchesDeletion supports installer-style glob patterns', () => {
  assert.equal(matchesDeletion('hooks/session-init.cjs', 'hooks/*.cjs'), true);
  assert.equal(matchesDeletion('hooks/lib/session-state-manager.cjs', 'hooks/*.cjs'), false);
  assert.equal(matchesDeletion('hooks/session-init.cjs', 'hooks/**/*.cjs'), true);
  assert.equal(matchesDeletion('hooks/lib/session-state-manager.cjs', 'hooks/**/*.cjs'), true);
  assert.equal(matchesDeletion('hooks/session-init.cjs', 'hooks/{session-init,subagent-init}.cjs'), true);
  assert.equal(matchesDeletion('skills/help/scripts/skills_data.yaml', 'skills/help'), true);
});
