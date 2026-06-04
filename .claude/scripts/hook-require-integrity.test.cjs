'use strict';

const assert = require('node:assert/strict');
const { readdirSync, readFileSync } = require('node:fs');
const path = require('node:path');
const test = require('node:test');

const repoRoot = path.resolve(__dirname, '..');
const hooksRoot = path.join(repoRoot, 'claude', 'hooks');
const RELATIVE_REQUIRE_RE = /\brequire\(\s*['"](\.[^'"]+)['"]\s*\)/g;

function listHookScripts(dir) {
  const entries = readdirSync(dir, { withFileTypes: true });
  const files = [];

  for (const entry of entries) {
    if (entry.name === '__tests__' || entry.name === '.logs') {
      continue;
    }

    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      files.push(...listHookScripts(fullPath));
    } else if (entry.isFile() && entry.name.endsWith('.cjs')) {
      files.push(fullPath);
    }
  }

  return files;
}

test('shipped hook scripts have resolvable relative require() dependencies', () => {
  const scripts = listHookScripts(hooksRoot);
  const missing = [];

  assert.ok(scripts.length > 0, 'expected shipped hook scripts to be discovered');

  for (const scriptPath of scripts) {
    const source = readFileSync(scriptPath, 'utf8');
    const scriptDir = path.dirname(scriptPath);

    for (const match of source.matchAll(RELATIVE_REQUIRE_RE)) {
      const request = match[1];
      try {
        require.resolve(path.resolve(scriptDir, request));
      } catch (error) {
        missing.push(`${path.relative(repoRoot, scriptPath)} -> ${request}`);
      }
    }
  }

  assert.deepEqual(missing, []);
});
