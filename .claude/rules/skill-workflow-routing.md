# Skill Workflow Routing

When orchestrating multi-step tasks, consider these workflow sequences. Skills are listed in typical execution order.

## Core Development Workflow

```
`ck-plan` → `cook` → `test` → `adversarial-code-review` → `ship` → `journal`
```

| User Intent | Suggested Start |
|-------------|----------------|
| "implement feature X", "build X", "add X" | `ck-plan` then `cook` |
| "execute this plan" | `cook` with `<plan-path>` |
| "quick implementation" | `cook --fast` |

## Bugfix Workflow

```
`scout` → `ck-debug` → `fix` → `test` → `adversarial-code-review`
```

| User Intent | Suggested Start |
|-------------|----------------|
| "X is broken", "error in X", "bug in X" | `fix` (auto-scouts internally) |
| "CI is failing", "tests broken" | `fix --auto` |
| "investigate why X happens" | `scout` then `ck-debug` |

## Investigation Workflow

```
`scout` → `ck-debug` → `brainstorm` → `ck-plan`
```

| User Intent | Suggested Start |
|-------------|----------------|
| "understand how X works" | `scout` |
| "why is X happening" | `ck-debug` |
| "explore options for X" | `brainstorm` then `ck-plan` |

## Post-Implementation Checklist

After completing implementation work, consider:
- `adversarial-code-review` — review changes before merging
- `ship` — run full shipping pipeline (tests, review, version, PR)
- `journal` — document decisions and lessons learned

## Setup Skills

Before starting implementation in a shared codebase:
- `worktree` — create isolated worktree for the feature/fix
- `scout` — discover relevant files and code patterns
