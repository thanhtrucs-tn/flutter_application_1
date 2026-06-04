'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');

const {
  getHeadTags,
  hasCurrentStableReleaseTag,
} = require('./send-discord-release.cjs');

function execWithOutput(output) {
  return () => output;
}

function execThatThrows() {
  throw new Error('git failed');
}

test('getHeadTags returns trimmed tags pointing at HEAD', () => {
  assert.deepEqual(getHeadTags(execWithOutput('v2.19.0\nv2.19.1-beta.18\n\n')), [
    'v2.19.0',
    'v2.19.1-beta.18',
  ]);
});

test('getHeadTags falls back to an empty list when git lookup fails', () => {
  assert.deepEqual(getHeadTags(execThatThrows), []);
});

test('hasCurrentStableReleaseTag requires the stable release tag at HEAD', () => {
  assert.equal(hasCurrentStableReleaseTag({ version: '2.19.0' }, execWithOutput('v2.19.0\n')), true);
  assert.equal(hasCurrentStableReleaseTag({ version: '2.19.0' }, execWithOutput('v2.18.0\n')), false);
});

test('hasCurrentStableReleaseTag rejects beta and unknown versions', () => {
  assert.equal(
    hasCurrentStableReleaseTag({ version: '2.19.1-beta.18' }, execWithOutput('v2.19.1-beta.18\n')),
    false,
  );
  assert.equal(hasCurrentStableReleaseTag({ version: 'Unknown' }, execWithOutput('vUnknown\n')), false);
});
