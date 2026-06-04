'use strict';

const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const { join } = require('node:path');
const test = require('node:test');

const installScript = readFileSync(join(__dirname, '..', 'claude', 'skills', 'install.ps1'), 'utf8');

test('PowerShell installer passes package specs to pip as exact arguments', () => {
  assert.match(
    installScript,
    /\$pipArgs = @\("install", \$PackageSpec, "--prefer-binary"\)\s+\$output = & python -m pip @pipArgs/s,
  );
  assert.match(
    installScript,
    /\$pipArgs = @\("install", \$PackageSpec, "--no-binary", \$packageName\)\s+\$output = & python -m pip @pipArgs/s,
  );
  assert.doesNotMatch(installScript, /pip install \$PackageSpec/);
});

test('PowerShell remediation reports failed requirements, not skill names', () => {
  assert.match(installScript, /function Split-FailureItem/);
  assert.match(installScript, /\$firstColon = \$Item\.IndexOf\(':'\)/);
  assert.match(installScript, /\$reasonColon = \$details\.LastIndexOf\(': '\)/);
  assert.match(installScript, /python -m pip install `"\$pkg`"/);
  assert.match(
    installScript,
    /\$pythonFailures = @\(Get-PythonFailureItems\)/,
  );
  assert.match(installScript, /foreach \(\$item in \$pythonFailures\) \{\s+\$failure = Split-FailureItem -Item \$item/s);
});

test('PowerShell installer does not suggest nonexistent librsvg winget or Scoop packages', () => {
  assert.match(installScript, /function Install-RsvgConvert/);
  assert.doesNotMatch(installScript, /GNOME\.librsvg/);
  assert.doesNotMatch(installScript, /-ScoopName "librsvg"/);
  assert.match(installScript, /choco install rsvg-convert -y/);
  assert.match(installScript, /pacman -S mingw-w64-x86_64-librsvg/);
  assert.match(installScript, /rsvg-convert is not available via winget or Scoop/);
});

test('PowerShell installer records critical failure details in the summary', () => {
  assert.match(installScript, /\$Script:FAILED_CRITICAL = \[System\.Collections\.ArrayList\]::new\(\)/);
  assert.match(
    installScript,
    /\[void\]\$Script:FAILED_CRITICAL\.Add\("\$\{Name\}: \$\{Reason\}"\)/,
  );
  assert.match(installScript, /critical_failures = @\(\$Script:FAILED_CRITICAL\)/);
});
