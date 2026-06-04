# Skill Workflow Routing

When orchestrating multi-step tasks, consider these workflow sequences. Skills are listed in typical execution order.

## Core Development Workflow

```
plan → cook → test → code-review → ship → journal
```

| User Intent | Suggested Start |
|-------------|----------------|
| "implement feature X", "build X", "add X" | `plan` then `cook` |
| "execute this plan" | `cook <plan-path>` |
| "quick implementation" | `cook --fast` |

## Bugfix Workflow

```
scout → debug → fix → test → code-review
```

| User Intent | Suggested Start |
|-------------|----------------|
| "X is broken", "error in X", "bug in X" | `fix` (auto-scouts internally) |
| "CI is failing", "tests broken" | `fix --auto` |
| "investigate why X happens" | `scout` then `debug` |

## Investigation Workflow

```
scout → debug → brainstorm → plan
```

| User Intent | Suggested Start |
|-------------|----------------|
| "understand how X works" | `scout` |
| "why is X happening" | `debug` |
| "explore options for X" | `brainstorm` then `plan` |

## Post-Implementation Checklist

After completing implementation work, consider:
- `code-review` — review changes before merging
- `ship` — run full shipping pipeline (tests, review, version, PR)
- `journal` — document decisions and lessons learned

## Setup Skills

Before starting implementation in a shared codebase:
- `worktree` — create isolated worktree for the feature/fix
- `scout` — discover relevant files and code patterns
