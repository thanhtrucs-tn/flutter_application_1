---
title: "Delete Relative from List"
description: "Add admin-only popup menu on relative cards to delete a relative with confirmation, persistence, and linked-alert cleanup."
status: completed
priority: P2
effort: 5h
branch: main
tags: [flutter, app-state, ui, localization, admin]
created: 2026-06-13
---

## Overview

Add the ability for administrators to remove a relative from the managed list on the Home screen. Feature includes:

- Popup menu on each `ElderlyListCard` with delete option visible only for admins.
- Confirmation dialog with localized message (vi/en).
- `AppState.deleteElderly(int id)` that removes the relative, cleans up linked alerts/device state, persists to SharedPreferences, and notifies listeners.
- SnackBar feedback after deletion.
- Unit tests and changelog update.

## Phases

| Phase | Description | Status | File |
|---|---|---|---|
| 01 | Research and scope existing code | completed | [phase-01-research.md](phase-01-research.md) |
| 02 | AppState delete method + persistence | completed | [phase-02-appstate-delete.md](phase-02-appstate-delete.md) |
| 03 | UI popup menu + confirmation dialog | completed | [phase-03-ui-popup-dialog.md](phase-03-ui-popup-dialog.md) |
| 04 | Integration + tests + docs | completed | [phase-04-integration-tests-docs.md](phase-04-integration-tests-docs.md) |

## Key Dependencies

- `AppState` singleton manages relatives at `lib/utils/app_state.dart:14`.
- Relative list UI lives in `lib/widgets/relative_reorderable_list.dart:18` and `lib/widgets/elderly_list_card.dart:15`.
- Admin detection via `UserProfile.role` at `lib/models/user_profile.dart:15`.
- Localization via `lib/utils/localization.dart:2`.
- SharedPreferences persistence key: `offline_elderly_v2` at `lib/utils/app_state.dart:160`.

## Risk Summary

- Gesture conflict between card tap, long-press drag on mobile, and popup menu icon.
- Admin-only visibility must be robust to avoid destructive action for supervisors.
- Deleting an elderly with an active critical alert could leave dangling state; cleanup is required.
