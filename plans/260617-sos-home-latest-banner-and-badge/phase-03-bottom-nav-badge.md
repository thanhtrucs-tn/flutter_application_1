---
title: "Phase 03 — Bottom navigation badge"
---

## Overview

Display the alert count as a badge on the Alerts icon in the bottom navigation bar.

## Requirements

- Badge shows `alertBadgeCount`.
- Badge is red with white text; hidden when count is zero.
- Opening Alerts tab clears the unread portion of the count.

## Related Code Files

- Modify: `lib/widgets/sos_bottom_nav.dart`
- Modify: `lib/screens/main_shell.dart`

## Implementation Steps

1. Update `SosBottomNav` constructor to accept `required int alertBadgeCount`.
2. Wrap the notifications `BottomNavigationBarItem` icon in a `Badge` widget (or custom `Stack` with a red circle) when count > 0.
3. In `MainShell._onNavTap`, when index == 1 (Alerts tab), call `AppState().markAllAlertsRead()` after updating the page.
4. In `MainShell.build`, read `state.alertBadgeCount` and pass it to `SosBottomNav`.

## Success Criteria

- Badge appears when there are unread/unacknowledged alerts.
- Badge disappears when count reaches zero.
- Tapping Alerts tab immediately marks alerts as read.

## Risk Assessment

- `BottomNavigationBarItem.icon` expects a Widget; `Badge` widget is supported in Material 3.
- Must use `AnimatedBuilder` in `MainShell` so count updates when `AppState` notifies.
