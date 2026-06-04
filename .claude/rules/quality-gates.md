# Quality Gate Rules

Rules for contributors and AI agents working on this skill bundle. These are NOT shipped to end users.

## Metadata Deletions (MANDATORY)

When renaming or deleting ANY shipped file under `.claude/` (skills, hooks, agents, scripts), you MUST add the old payload-relative path to `.claude/metadata.json` `deletions[]` array when that metadata file is part of the distribution. This tells installers to remove stale files from user machines during upgrade. Forgetting this leaves orphaned files that cause conflicts.

**Affected files:** `.claude/metadata.json`

## Skill Registry Contract

Canonical skill names live in each `.claude/skills/*/SKILL.md` frontmatter `name:` field. Names MUST be portable kebab-case (`plan`, `code-review`, `security`) without legacy namespace prefixes. All cross-references in markdown files MUST use the exact registered name; when a CI-validated explicit reference is needed, use `skill:<name>` (for example `skill:plan`). When renaming a skill, update ALL cross-references in the same PR.

## Skill Cross-Reference Integrity (CI-enforced)

CI runs `node scripts/check-skill-cross-refs.js` on every push. It builds a registry from all `.claude/skills/*/SKILL.md` frontmatter `name:` fields and checks every explicit `skill:<name>` reference in `.claude/**/*.md` resolves to a registered name.

**Critical rule: use REGISTERED names, not historical aliases.**

The registry no longer strips namespace prefixes. A frontmatter value of `name: debug` registers exactly as `debug`; `skill:debug` matches, but legacy namespaced forms or directory aliases do not.

| Directory Name | Frontmatter `name:` | Registered As | Correct explicit reference |
|----------------|---------------------|---------------|-------------------|
| `debug` | `debug` | `debug` | `skill:debug` |
| `plan` | `plan` | `plan` | `skill:plan` |
| `security` | `security` | `security` | `skill:security` |
| `cook` | `cook` | `cook` | `skill:cook` |
| `brainstorm` | `brainstorm` | `brainstorm` | `skill:brainstorm` |

**Before committing any explicit `skill:<name>` reference**, verify the name exists in the registry:
```bash
node scripts/check-skill-cross-refs.js
```

**When modifying workflow routing rules** (`.claude/rules/skill-workflow-routing.md`, `.claude/rules/skill-domain-routing.md`):
- These rules are shipped to end users — they guide Claude's skill suggestions
- Any explicit `skill:<name>` reference in these files is CI-checked
- Run `.claude/skills/.venv/bin/python3 .claude/scripts/validate-skill-crossrefs.py .claude/skills/` to verify workflow chain integrity
- When adding a new skill to a workflow chain, update BOTH the routing rule AND the skill's `## Workflow Position` section

**Affected files:** `.claude/rules/skill-*.md`, `.claude/skills/*/SKILL.md`, `.claude/scripts/check-skill-cross-refs.js`

## Skill Routing Coverage (CI-enforced)

CI runs `node scripts/check-skill-routing.js` on every PR. It verifies every shipped skill is reachable from at least one routing file (`.claude/rules/skill-domain-routing.md` or `.claude/rules/skill-workflow-routing.md`). Skills intentionally absent from routing (meta-routers, orchestrator-internal, maintainer-tier) must be listed in `.claude/scripts/skill-routing-allowlist.json` with a written justification.

**The principle (audit-route-reframe):** discoverability is part of the contract. Shipping a skill that no routing file mentions means users (and Claude) will not find it. **Telemetry zero ≠ zero value** — most dormant skills audited under epic #711 flipped to KEEP after routing or description fixes. When tempted to delete a "dormant" skill:

1. **Audit:** Does the skill have unique capability (scripts, references, agents)? If yes, deletion likely loses real value.
2. **Route:** Is it reachable from a routing file? If no, dormancy is a discoverability problem — fix the routing.
3. **Reframe:** Does the SKILL.md `description` read like a maintainer-only utility? Rewrite with user-phrasing keywords.

Delete only when: (a) audit confirms zero unique capability, AND (b) routing fix wouldn't change adoption, AND (c) use case is genuinely covered by another skill. Catalog size is an output, not a target.

**When adding a new skill:**
1. Add the skill to the appropriate domain block in `skill-domain-routing.md` (preferred — user-facing)
2. OR add to `skill-workflow-routing.md` if it fits a workflow chain
3. OR add to `scripts/skill-routing-allowlist.json` with a justification (only for genuine meta/orchestrator/maintainer skills)

**When deleting a skill:**
- Run the check after deletion. The tool will flag stale allowlist entries pointing to the now-removed skill — remove those entries in the same PR.

**When the lint flags a "redundant allowlist entry":**
- The skill was added to a routing file. Drop it from the allowlist — its routing entry is now load-bearing.

**Affected files:** `.claude/scripts/check-skill-routing.js`, `.claude/scripts/skill-routing-allowlist.json`, `.claude/rules/skill-domain-routing.md`, `.claude/rules/skill-workflow-routing.md`

### Allowlist `reason` quality (both lints)

Both `skill-routing-allowlist.json` and `skill-description-lint-allowlist.json` enforce a minimum reason length of **20 characters** (post-trim) via the shared `scripts/lib/validate-allowlist-reason.js` helper. Placeholder strings (`"ok"`, `"tbd"`, `"."`) error out at load. The audit-trail purpose of allowlists demands a real justification — link a follow-up issue, name the constraint, or describe the use case.

**Affected files:** `scripts/lib/validate-allowlist-reason.js`

## Skill Description and Listing Policy

CI also runs `python3 .claude/scripts/validate-skill-frontmatter.py` as a blocking `skill-frontmatter-contract` job. That validator enforces the hard shipped-skill schema, including portable kebab-case names and `user-invocable: true`.

CI runs `node scripts/check-skill-descriptions.js` on every PR as a blocking major-policy gate. Major findings fail CI; minor description guidance remains non-blocking. It surfaces frontmatter `description:` / `when_to_use:` patterns that hurt user discoverability:

| Rule | Severity | Catches |
|---|---|---|
| `use-this-prefix` | minor | Description starts with "Use this when/skill/for/to…" — instructional, not capability-led |
| `maintainer-marker` | major | Description contains `[KAI]`, `maintainer-only`, `for kai` — should be removed if shipped to all users |
| `todo-marker` | major | Description contains TODO / FIXME / XXX / WIP — resolve before shipping |
| `too-short` | minor | Description <50 chars — add trigger keywords / use cases |
| `too-long` | minor | Description >512 chars — keep frontmatter to routing signal; move detail into the skill body |
| `missing-description` | major | Frontmatter parsed but no `description:` field (auto-emitted) |
| `frontmatter-parse-error` | major | Frontmatter block missing or unclosed (auto-emitted; distinct from missing-description so authors can debug) |
| `missing-user-invocable-visibility` | major | Shipped skill is missing `user-invocable: true` |
| `disabled-model-invocation` | major | Shipped skill sets `disable-model-invocation: true` |
| `missing-skill-listing-budget` | major | Project settings do not define the skill listing budget settings |
| `low-skill-listing-budget` | major | `skillListingBudgetFraction` is invalid or too low for the projected shipped-skill listing on a 200k context floor |
| `missing-skill-description-cap` | major | Project settings do not define `skillListingMaxDescChars` |
| `high-skill-description-cap` | major | `skillListingMaxDescChars` is invalid or above the 512-character recommendation |
| `forbidden-skill-overrides` | major | Project settings define `skillOverrides`; keep skills visible and manage pressure through budget/caps |

Allowlist (`scripts/skill-description-lint-allowlist.json`) lets specific skills opt out of specific rules with required `reason`. Rule IDs in allowlist entries are validated at load — typos like `too_short` vs `too-short` error out instead of silently allowing nothing.

`python3 .claude/scripts/validate-skill-frontmatter.py` remains the blocking frontmatter contract. It requires portable kebab-case names and `user-invocable: true`, and rejects `disable-model-invocation: true` for shipped skills; listing pressure must be handled through `skillListingBudgetFraction`, `skillListingMaxDescChars`, and tighter descriptions.

**When the lint flags a description:**
- For "minor" rules: review the description, rewrite if the warning is fair, OR allowlist with justification
- For "major" rules: fix immediately. These are ship-blockers (hidden skills, missing budget settings, TODO left in, maintainer-only marker on a user-shipped skill)

**Affected files:** `scripts/check-skill-descriptions.js`, `scripts/skill-description-lint-allowlist.json`

## Statusline Changes

Changes to `statusline*.cjs` or `statusline-*.cjs` MUST update snapshot tests. Run test suite with all config variants: minimal config, full config, custom lines, no quota, 1M context window. ANSI escape sequences and special characters (NBSP) must be explicitly tested.
