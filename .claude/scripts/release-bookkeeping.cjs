#!/usr/bin/env node
'use strict';

const { execFileSync } = require('node:child_process');
const fs = require('node:fs');

const {
  computeNextBetaVersion,
  findLatestStableVersion,
  parseClosingIssueNumbers,
  parsePullNumbersFromMergeSubjects,
  parseStableVersion,
} = require('./release-bookkeeping-helpers.cjs');

const DEFAULT_RELEASED_LABEL = 'released on @dev';

function run(command, args, options = {}) {
  try {
    return execFileSync(command, args, {
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'pipe'],
      ...options,
    }).trim();
  } catch (error) {
    const stderr = error.stderr ? String(error.stderr).trim() : error.message;
    throw new Error(`${command} ${args.join(' ')} failed: ${stderr}`);
  }
}

function getTags() {
  const output = run('git', ['tag', '--sort=-v:refname', '-l', 'v*']);
  return output ? output.split(/\r?\n/) : [];
}

function getPreviousTag(currentTag) {
  try {
    return run('git', ['describe', '--tags', '--match', 'v*', '--abbrev=0', `${currentTag}^`]);
  } catch {
    return '';
  }
}

function writeGithubOutput(values) {
  if (!process.env.GITHUB_OUTPUT) {
    return;
  }
  const lines = Object.entries(values).map(([key, value]) => `${key}=${value}`);
  fs.appendFileSync(process.env.GITHUB_OUTPUT, `${lines.join('\n')}\n`);
}

function parseArgs(argv) {
  const result = { _: [] };
  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (!arg.startsWith('--')) {
      result._.push(arg);
      continue;
    }
    const key = arg.slice(2);
    if (key === 'close-issues' || key === 'no-close-issues') {
      result[key] = true;
      continue;
    }
    result[key] = argv[index + 1];
    index += 1;
  }
  return result;
}

function nextBetaVersion() {
  const tags = getTags();
  const latestStable = findLatestStableVersion(tags) || parseStableVersion('0.0.0');
  const result = computeNextBetaVersion(
    `${latestStable.major}.${latestStable.minor}.${latestStable.patch}`,
    tags,
  );
  writeGithubOutput(result);
  console.log(`[i] Stable: v${result.stable} | Beta: v${result.version}`);
}

function hasMarker(comments, marker) {
  return comments.some((comment) => String(comment.body || '').includes(marker));
}

function markIssueReleased(issueNumber, { currentTag, label, prNumber, closeIssues }) {
  const issue = JSON.parse(
    run('gh', ['issue', 'view', String(issueNumber), '--json', 'state,comments']),
  );
  const marker = `<!-- claudekit-dev-release:${currentTag}:pr-${prNumber} -->`;
  const comment = `${marker}\nReleased on \`dev\` in ${currentTag} via PR #${prNumber}.`;

  run('gh', ['issue', 'edit', String(issueNumber), '--add-label', label]);

  if (issue.state !== 'CLOSED' && closeIssues) {
    run('gh', ['issue', 'close', String(issueNumber), '--comment', comment]);
    return;
  }
  if (!hasMarker(issue.comments || [], marker)) {
    run('gh', ['issue', 'comment', String(issueNumber), '--body', comment]);
  }
}

function markDevRelease(options) {
  const currentTag = options['current-tag'];
  if (!currentTag) {
    throw new Error('Missing --current-tag');
  }
  const label = options.label || DEFAULT_RELEASED_LABEL;
  const closeIssues = Boolean(options['close-issues']) && !options['no-close-issues'];
  const previousTag = getPreviousTag(currentTag);
  const range = previousTag ? [`${previousTag}..HEAD`] : ['-20'];
  const mergeSubjects = run('git', ['log', ...range, '--merges', '--format=%s']);
  const pullNumbers = parsePullNumbersFromMergeSubjects(mergeSubjects);
  const failures = [];

  for (const prNumber of pullNumbers) {
    try {
      console.log(`[i] Labeling PR #${prNumber} with '${label}'`);
      run('gh', ['pr', 'edit', String(prNumber), '--add-label', label]);

      const pr = JSON.parse(
        run('gh', ['pr', 'view', String(prNumber), '--json', 'body,title']),
      );
      const issueNumbers = parseClosingIssueNumbers(`${pr.title}\n${pr.body}`);
      for (const issueNumber of issueNumbers) {
        console.log(`[i] Marking issue #${issueNumber} released on dev`);
        markIssueReleased(issueNumber, { currentTag, label, prNumber, closeIssues });
      }
    } catch (error) {
      failures.push(`PR #${prNumber}: ${error.message}`);
    }
  }

  if (failures.length) {
    throw new Error(`Release bookkeeping failed:\n${failures.join('\n')}`);
  }
}

function main() {
  const [command, ...rawArgs] = process.argv.slice(2);
  const options = parseArgs(rawArgs);
  if (command === 'next-beta-version') {
    nextBetaVersion();
  } else if (command === 'mark-dev-release') {
    markDevRelease(options);
  } else {
    throw new Error(`Unknown command: ${command || '(none)'}`);
  }
}

module.exports = {
  computeNextBetaVersion,
  findLatestStableVersion,
  parseClosingIssueNumbers,
  parsePullNumbersFromMergeSubjects,
};

if (require.main === module) {
  try {
    main();
  } catch (error) {
    console.error(error.message);
    process.exit(1);
  }
}
