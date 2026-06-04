---
name: plans-kanban
description: Open the plans dashboard in a compatible CLI config UI. Use for plan kanban views, progress tracking, timeline checks, and quick navigation into plan files.
user-invocable: true
when_to_use: "Invoke to open or inspect the plans dashboard."
category: dev-tools
keywords: [plans, dashboard, kanban, progress, timeline]
argument-hint: "[deprecated flags are accepted with warnings]"
metadata:
  author: claudekit
  version: "2.0.0"
---

# plans-kanban

Thin launcher for a compatible CLI dashboard plans view.

It opens the integrated dashboard at `http://localhost:3456/plans` instead of starting the legacy standalone server.
If `3456` is already in use, the CLI may auto-fallback to `3457-3460` and the launcher will follow that running port.

## Quick Start

```bash
node .claude/skills/plans-kanban/scripts/open-dashboard.cjs
```

If the dashboard is not already running, the launcher starts:

```bash
${PLAN_DASHBOARD_CLI:-ck} config ui --port 3456 --no-open
```

Then it opens the plans route in your browser.

## Purpose

Use this skill when you want the visual plans dashboard for:
- Multi-plan kanban and grid views
- Timeline and progress overview
- Navigating into `plan.md` and `phase-*.md` files
- Quick visibility into active vs completed work

Scope note:
- Project dashboards should show project-scoped plans only.
- Global dashboards should show global-scoped plans only.
- Use a compatible plan status command as the authoritative dependency/status view for `blockedBy` / `blocks`; `plans-kanban` is a launcher, not the source of cross-scope dependency truth.
- The generic `/plans` route defaults to `plans` unless a `dir` query param is already present; scope-aware plan roots come from the project/global dashboard context, not from deprecated launcher flags.

## Dashboard Workflow

```bash
# Open the plans dashboard
node .claude/skills/plans-kanban/scripts/open-dashboard.cjs

# Run the dashboard manually if you want to keep it in the foreground
${PLAN_DASHBOARD_CLI:-ck} config ui --port 3456
```

Primary URL:

```text
http://localhost:3456/plans
```

## Deprecated Compatibility

The old standalone server flags are accepted for compatibility and replaced with guidance:

| Legacy input | Current behavior |
|-------------|------------------|
| `--dir <path>` / positional path | Warns and ignores. This launcher always opens the generic `/plans` route; it does not choose a custom plan root. |
| `--plans <path>` | Warns and ignores. |
| `--port <n>` | Warns and ignores. `plans-kanban` now targets the CLI dashboard starting at `3456` and follows the CLI fallback port if needed. |
| `--host <addr>` | Warns and ignores. Use the dashboard CLI directly if needed. |
| `--background` / `--foreground` | Warns and ignores. The launcher manages its own detached startup flow. |
| `--stop` | Stops the launcher-managed dashboard process if one was started by `plans-kanban`; otherwise prints manual shutdown guidance. |
| `--open` | Accepted. Opening is now the default behavior. |

## Related CLI Commands

```bash
${PLAN_DASHBOARD_CLI:-ck} config ui                    # Start dashboard
${PLAN_DASHBOARD_CLI:-ck} config ui --port 3456        # Start on the plans-kanban default port
plan status <plan.md>                                  # Inspect plan progress when a compatible plan CLI exists
cd /absolute/path/to/plan-dir && plan check 1
cd /absolute/path/to/plan-dir && plan check 1 --start
cd /absolute/path/to/plan-dir && plan uncheck 1
```

## Requirements

### CLI Compatibility

The launcher performs a capability probe before opening the browser.
The dashboard at `/plans` is only opened when the running claudekit-cli instance supports it — detected by either:

- `/api/health` response containing `"plans-dashboard"` in its `features` array, or
- `/api/plans` responding with a 2xx status (backward-compat for early dev builds).

If neither probe succeeds, the launcher prints an upgrade message and exits with code 1 without opening the browser. Upgrade the CLI to a version that exposes the plans-dashboard capability to use this launcher.

## Migration Notes

The legacy standalone server, renderer, and assets have been retired from this skill.

For migration details:

```text
.claude/skills/plans-kanban/deprecated/MIGRATION.md
```

## Troubleshooting

**Dashboard CLI not found**
Install a compatible CLI or set `PLAN_DASHBOARD_CLI` / `CLAUDEKIT_CLI` to its executable path.

**Dashboard did not open**
Start it manually with the configured CLI (`config ui --port 3456`), then open `/plans` on whichever port the CLI reports.

**Need to stop a launcher-started dashboard**
Run the launcher again with `--stop`. If the dashboard was started manually, stop the terminal running the dashboard CLI.

**Need custom host or different port**
Run the dashboard CLI directly with the flags you need. The `plans-kanban` launcher intentionally stays thin and opinionated.
