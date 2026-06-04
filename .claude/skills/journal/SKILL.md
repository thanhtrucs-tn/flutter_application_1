---
name: journal
description: "Write technical journal entries analyzing recent changes. Use for session reflections, change analysis, decision documentation."
user-invocable: true
when_to_use: "Invoke for technical session reflection or decision records."
category: utilities
keywords: [journal, reflection, changes, session]
argument-hint: "[topic or reflection]"
metadata:
  author: claudekit
  version: "1.0.0"
---

# Journal

Use the `journal-writer` subagent to explore the memories and recent code changes, and write some journal entries.
Journal entries should be concise and focused on the most important events, key changes, impacts, and decisions.
Keep journal entries in the `./docs/journals/` directory.

**IMPORTANT:** Invoke "project-organization" skill to organize the outputs.

## Workflow Position

**Typically follows:** `ship` (journal after shipping), `cook` (journal after implementation), `fix` (journal after bug fix)
**Terminal skill** — no typical successor.
