'use strict';

const STABLE_TAG_RE = /^v?(\d+)\.(\d+)\.(\d+)$/;
const BETA_TAG_RE = /^v?(\d+)\.(\d+)\.(\d+)-beta\.(\d+)$/;
const CLOSING_PHRASE_RE =
  /\b(?:close[sd]?|fix(?:e[sd])?|resolve[sd]?)\b\s*:?\s+((?:#\d+|[\s,;&]|\band\b)+)/gi;

function parseStableVersion(value) {
  const match = String(value || '').trim().match(STABLE_TAG_RE);
  if (!match) {
    throw new Error(`Invalid stable version: ${value}`);
  }
  return {
    major: Number(match[1]),
    minor: Number(match[2]),
    patch: Number(match[3]),
  };
}

function compareVersions(a, b) {
  return a.major - b.major || a.minor - b.minor || a.patch - b.patch;
}

function findLatestStableVersion(tags) {
  return tags
    .map((tag) => (String(tag).match(STABLE_TAG_RE) ? parseStableVersion(tag) : null))
    .filter(Boolean)
    .sort(compareVersions)
    .pop();
}

function computeNextBetaVersion(stableVersion, existingTags) {
  const stable = parseStableVersion(stableVersion);

  let base = null;
  let maxBeta = 0;
  for (const tag of existingTags) {
    const match = String(tag).match(BETA_TAG_RE);
    if (!match) {
      continue;
    }
    const candidate = {
      major: Number(match[1]),
      minor: Number(match[2]),
      patch: Number(match[3]),
    };
    const betaNumber = Number(match[4]);
    const cmp = base ? compareVersions(candidate, base) : 1;
    if (cmp > 0) {
      base = candidate;
      maxBeta = betaNumber;
    } else if (cmp === 0) {
      maxBeta = Math.max(maxBeta, betaNumber);
    }
  }

  // Beta line must be strictly ahead of latest stable. If the existing beta
  // base has been overtaken (or there is none), advance to stable.patch + 1.
  if (!base || compareVersions(base, stable) <= 0) {
    base = { major: stable.major, minor: stable.minor, patch: stable.patch + 1 };
    maxBeta = 0;
  }

  return {
    stable: `${stable.major}.${stable.minor}.${stable.patch}`,
    version: `${base.major}.${base.minor}.${base.patch}-beta.${maxBeta + 1}`,
  };
}

function parseClosingIssueNumbers(text) {
  const issues = new Set();
  for (const match of String(text || '').matchAll(CLOSING_PHRASE_RE)) {
    const refs = match[1].match(/#(\d+)/g) || [];
    refs.forEach((ref) => issues.add(Number(ref.slice(1))));
  }
  return [...issues].sort((a, b) => a - b);
}

function parsePullNumbersFromMergeSubjects(text) {
  const pulls = new Set();
  for (const line of String(text || '').split(/\r?\n/)) {
    const match =
      line.match(/^Merge pull request #(\d+)\b/i) ||
      line.match(/^Merge PR #(\d+)\b/i);
    if (match) {
      pulls.add(Number(match[1]));
    }
  }
  return [...pulls].sort((a, b) => a - b);
}

module.exports = {
  computeNextBetaVersion,
  findLatestStableVersion,
  parseClosingIssueNumbers,
  parsePullNumbersFromMergeSubjects,
  parseStableVersion,
};
