'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');

const { validateReason, MIN_REASON_LENGTH } = require('./validate-allowlist-reason.js');

test('rejects undefined', () => {
  const r = validateReason(undefined);
  assert.equal(r.ok, false);
  assert.match(r.error, /must be a string/);
});

test('rejects non-string', () => {
  assert.equal(validateReason(42).ok, false);
  assert.equal(validateReason(null).ok, false);
  assert.equal(validateReason({}).ok, false);
});

test('rejects empty string', () => {
  const r = validateReason('');
  assert.equal(r.ok, false);
  assert.match(r.error, /empty/);
});

test('rejects whitespace-only', () => {
  const r = validateReason('   \t\n  ');
  assert.equal(r.ok, false);
  assert.match(r.error, /empty/);
});

test('rejects placeholder "ok"', () => {
  const r = validateReason('ok');
  assert.equal(r.ok, false);
  assert.match(r.error, /too short/);
});

test('rejects placeholder "tbd"', () => {
  const r = validateReason('tbd');
  assert.equal(r.ok, false);
  assert.match(r.error, /too short/);
});

test('rejects placeholder "."', () => {
  const r = validateReason('.');
  assert.equal(r.ok, false);
  assert.match(r.error, /too short/);
});

test('rejects exactly MIN-1 chars', () => {
  const r = validateReason('a'.repeat(MIN_REASON_LENGTH - 1));
  assert.equal(r.ok, false);
});

test('accepts exactly MIN chars', () => {
  const r = validateReason('a'.repeat(MIN_REASON_LENGTH));
  assert.equal(r.ok, true);
});

test('accepts a real-world reason', () => {
  const r = validateReason(
    'Meta-router skill, no user-facing slash-command yet — pending Phase B integration.'
  );
  assert.equal(r.ok, true);
});

test('trims whitespace before length check', () => {
  // "    short    " has visible content < MIN — should reject
  const r = validateReason('   short   ');
  assert.equal(r.ok, false);
});

test('error message mentions threshold', () => {
  const r = validateReason('too brief');
  assert.equal(r.ok, false);
  assert.match(r.error, new RegExp(`≥${MIN_REASON_LENGTH}`));
});
