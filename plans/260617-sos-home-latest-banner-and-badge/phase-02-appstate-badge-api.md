---
title: "Phase 02 — AppState badge count and mark-read API"
---

## Overview

Expose the badge count and a method to mark all alerts as read from `AppState`.

## Requirements

- Badge count includes any alert that is unread OR unacknowledged.
- Opening the Alerts tab marks every alert as read.
- Acknowledging an alert also marks it as read.

## Related Code Files

- Modify: `lib/utils/app_state.dart`

## Implementation Steps

1. Add getter `int get alertBadgeCount => _alerts.where((a) => !a.read || !a.acknowledged).length;`.
2. Add method `void markAllAlertsRead()` that sets `read = true` on every alert, persists via `_saveAlertHistory`, and calls `notifyListeners()`.
3. In `acknowledgeAlert`, when updating the alert also set `read = true`.
4. In `triggerSOS`, ensure new alerts have `read = false` (default).
5. In `addAlert`, ensure new alerts have `read = false` (default).

## Success Criteria

- `alertBadgeCount` returns correct combined count.
- `markAllAlertsRead()` clears the unread portion of the count.
- Acknowledgement reduces the count for that alert.

## Risk Assessment

- Calling `markAllAlertsRead()` on every tab tap writes SharedPreferences each time; acceptable for current scale.
- Need to ensure `notifyListeners()` is called so badge updates immediately.
