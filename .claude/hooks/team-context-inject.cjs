#!/usr/bin/env node
/**
 * SubagentStart Hook - Injects team context for Agent Team teammates
 *
 * Fires: When a subagent is started (SubagentStart event)
 * Purpose: If the spawned agent is a team member, inject peer info + task summary
 * Design: Non-blocking, fail-open (exit 0 always), no external deps
 */

// Crash wrapper
try {
  const fs = require('fs');
  const path = require('path');
  const os = require('os');
  const { isHookEnabled } = require('./lib/ck-config-utils.cjs');

  if (!isHookEnabled('team-context-inject')) {
    process.exit(0);
  }

const HOME_DIR = process.env.CLAUDE_HOME || process.env.HOME || os.homedir();
const TEAMS_DIR = path.join(HOME_DIR, '.claude', 'teams');
const TASKS_DIR = path.join(HOME_DIR, '.claude', 'tasks');

/**
 * Extract team name from agent_id (format: "name@team-name")
 * Returns null if not a team agent or if name contains path separators
 */
function extractTeamName(agentId) {
  if (!agentId || typeof agentId !== 'string') return null;
  const atIdx = agentId.indexOf('@');
  if (atIdx < 1) return null;
  const name = agentId.substring(atIdx + 1);
  // Reject path traversal attempts
  if (name.includes('/') || name.includes('\\') || name.includes('..')) return null;
  return name;
}

/**
 * Read and parse JSON file safely
 */
function readJson(filePath) {
  try {
    return JSON.parse(fs.readFileSync(filePath, 'utf-8'));
  } catch {
    return null;
  }
}

/**
 * Build peer list from team config, excluding the current agent
 */
function buildPeerList(config, currentAgentId) {
  if (!config?.members?.length) return '';
  const peers = config.members
    .filter(m => m.agentId !== currentAgentId)
    .map(m => `${m.name} (${m.agentType})`)
    .join(', ');
  return peers || 'none';
}

function firstEnv(env, ...names) {
  for (const name of names) {
    if (env[name]) return env[name];
  }
  return '';
}

/**
 * Build runtime context from environment variables.
 * Generic names are preferred; legacy names remain supported for compatibility.
 */
function buildRuntimeContext() {
  const ctx = [];
  const env = process.env;

  const reportsPath = firstEnv(env, 'REPORTS_PATH', 'CK_REPORTS_PATH');
  const plansPath = firstEnv(env, 'PLANS_PATH', 'CK_PLANS_PATH');
  const projectRoot = firstEnv(env, 'PROJECT_ROOT', 'CK_PROJECT_ROOT');
  const namePattern = firstEnv(env, 'NAME_PATTERN', 'CK_NAME_PATTERN');
  const gitBranch = firstEnv(env, 'GIT_BRANCH', 'CK_GIT_BRANCH');
  const activePlan = firstEnv(env, 'ACTIVE_PLAN', 'CK_ACTIVE_PLAN');

  if (reportsPath) ctx.push(`Reports: ${reportsPath}`);
  if (plansPath) ctx.push(`Plans: ${plansPath}`);
  if (projectRoot) ctx.push(`Project: ${projectRoot}`);
  if (namePattern) ctx.push(`Naming: ${namePattern}`);
  if (gitBranch) ctx.push(`Branch: ${gitBranch}`);
  if (activePlan) ctx.push(`Active plan: ${activePlan}`);
  ctx.push('Commits: conventional (feat:, fix:, docs:, refactor:, test:, chore:)');

  return ctx;
}

/**
 * Summarize tasks from team task directory
 */
function summarizeTasks(teamName) {
  const taskDir = path.join(TASKS_DIR, teamName);
  try {
    if (!fs.existsSync(taskDir)) return null;
    const files = fs.readdirSync(taskDir).filter(f => f.endsWith('.json'));
    let pending = 0, inProgress = 0, completed = 0;
    for (const file of files) {
      const task = readJson(path.join(taskDir, file));
      if (!task?.status) continue;
      if (task.status === 'pending') pending++;
      else if (task.status === 'in_progress') inProgress++;
      else if (task.status === 'completed') completed++;
    }
    return { pending, inProgress, completed, total: files.length };
  } catch {
    return null;
  }
}

/**
 * Main hook execution
 */
function main() {
  try {
    const stdin = fs.readFileSync(0, 'utf-8').trim();
    if (!stdin) process.exit(0);

    const payload = JSON.parse(stdin);
    const agentId = payload.agent_id || '';

    // Detect team membership from agent_id pattern (name@team-name)
    const teamName = extractTeamName(agentId);
    if (!teamName) process.exit(0); // Not a team agent, exit silently

    // Read team config
    const configPath = path.join(TEAMS_DIR, teamName, 'config.json');
    const config = readJson(configPath);
    if (!config) process.exit(0); // No team config found

    // Build context
    const peerList = buildPeerList(config, agentId);
    const tasks = summarizeTasks(teamName);

    const lines = [];
    lines.push(`## Team Context`);
    lines.push(`Team: ${config.name || teamName}`);
    lines.push(`Your peers: ${peerList}`);

    if (tasks) {
      lines.push(`Task summary: ${tasks.pending} pending, ${tasks.inProgress} in progress, ${tasks.completed} completed`);
    }

    // Runtime context
    const runtimeCtx = buildRuntimeContext();
    if (runtimeCtx.length > 0) {
      lines.push('');
      lines.push('## Runtime Context');
      lines.push(...runtimeCtx);
    }

    lines.push('');
    lines.push('Remember: Check TaskList, claim tasks, respect file ownership, use SendMessage to communicate.');

    const output = {
      hookSpecificOutput: {
        hookEventName: "SubagentStart",
        additionalContext: lines.join('\n')
      }
    };

    console.log(JSON.stringify(output));
    process.exit(0);
  } catch (error) {
    // Fail-open: log to stderr, exit cleanly
    if (process.env.CK_DEBUG) {
      console.error(`[team-context-inject] Error: ${error.message}`);
    }
    process.exit(0);
  }
  }

  main();
} catch (e) {
  // Minimal crash logging (zero deps — only Node builtins)
  try {
    const fs = require('fs');
    const p = require('path');
    const logDir = p.join(__dirname, '.logs');
    if (!fs.existsSync(logDir)) fs.mkdirSync(logDir, { recursive: true });
    fs.appendFileSync(p.join(logDir, 'hook-log.jsonl'),
      JSON.stringify({ ts: new Date().toISOString(), hook: p.basename(__filename, '.cjs'), status: 'crash', error: e.message }) + '\n');
  } catch (_) {}
  process.exit(0); // fail-open
}
