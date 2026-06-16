---
title: "Phase 04 — Home single latest SOS banner"
---

## Overview

Replace the multi-item `SosNotificationList` on Home with a single banner showing only the newest unacknowledged alert.

## Requirements

- Show at most one banner.
- Banner displays the latest unacknowledged alert (top of `sortedAlerts` filtered by `!acknowledged`).
- Tapping banner opens `AlertDetailScreen`.
- When a newer alert arrives, the old banner slides down and disappears; the new banner replaces it.
- If no unacknowledged alerts, hide the banner entirely.

## Related Code Files

- Create: `lib/widgets/sos_latest_alert_banner.dart`
- Modify: `lib/widgets/relative_reorderable_list.dart`
- Remove usage of: `lib/widgets/sos_notification_list.dart`

## Implementation Steps

1. Create `SosLatestAlertBanner` StatelessWidget that accepts `AlertModel? alert` and `ValueChanged<AlertModel> onTap`.
2. Use `AnimatedSwitcher` with:
   - `transitionBuilder`: old child slides down + fades out (`SlideTransition` with offset from (0,0) to (0,1) + `FadeTransition`); new child slides in from above (offset (0,-1) to (0,0)) + fades in.
   - `duration: Duration(milliseconds: 350)`.
   - `child` keyed by alert id (or a constant SizedBox when null).
3. Banner UI: red/orange styled card with icon, message, elderly name, and a small "NEW" indicator or timestamp.
4. In `RelativeReorderableList`, replace the `SosNotificationList` block (lines ~87-99) with `SosLatestAlertBanner` fed by the latest unacknowledged alert.
5. Remove the import of `sos_notification_list.dart` from `relative_reorderable_list.dart`.
6. Optionally delete `lib/widgets/sos_notification_list.dart` if no longer used anywhere.

## Success Criteria

- Home shows zero or one SOS banner.
- New alert replaces old banner with slide-down animation.
- Banner hidden when all alerts are acknowledged.

## Risk Assessment

- `AnimatedSwitcher` exit animation must run before new child fully appears; use distinct keys for each alert id.
- The banner and the full-screen `activeAlert` auto-push in `HomeScreen` may both trigger; acceptable per current plan, but verify UX is not confusing.
