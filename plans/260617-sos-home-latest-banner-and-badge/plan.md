---
title: "SOS Home Latest Banner + Alert Tab Badge"
description: "Replace the Home SOS list with a single latest-alert banner, add animation swap-on-new, and expose an unread/unacknowledged badge count on the Alerts tab."
status: completed
priority: P1
effort: 4h
branch: main
tags: [flutter, ui, sos-alerts, badge, animations]
created: 2026-06-17
---

## Overview

User wants to change the way SOS alerts surface on Home and in the bottom navigation:

1. **Home SOS banner**: instead of the current `SosNotificationList` showing up to 5 unacknowledged alerts, show a single temporary banner for only the newest unacknowledged alert.
2. **Swap animation**: when a newer alert arrives, the old banner slides down and disappears; the new banner replaces it.
3. **Alerts tab badge**: show a count of alerts that are either unread or unacknowledged. Opening the Alerts tab marks all alerts as read, reducing the badge.

## Context Links

- Previous related plan: `plans/260617-sos-alerts-realtime-sorting/plan.md`
- `lib/utils/app_state.dart`: alert store and `sortedAlerts`.
- `lib/models/alert_model.dart`: alert data shape.
- `lib/widgets/relative_reorderable_list.dart`: Home list header where SOS section lives.
- `lib/widgets/sos_notification_list.dart`: widget to be replaced/removed.
- `lib/widgets/sos_bottom_nav.dart`: bottom navigation widget.
- `lib/screens/main_shell.dart`: PageView + bottom nav wiring.
- `test/alert_badge_test.dart`: new badge count / mark-read tests.
- `test/alert_sorting_and_autoack_test.dart`: existing alert sorting tests.
- `docs/project-changelog.md`: project changelog.

## Phases

| Phase | Description | Status | File |
|---|---|---|---|
| 01 | Add `read` state to `AlertModel` | completed | `lib/models/alert_model.dart` |
| 02 | Add badge count API and mark-read method to `AppState` | completed | `lib/utils/app_state.dart` |
| 03 | Render badge on bottom nav Alerts tab | completed | `lib/widgets/sos_bottom_nav.dart`, `lib/screens/main_shell.dart` |
| 04 | Build single latest SOS banner for Home | completed | `lib/widgets/sos_latest_alert_banner.dart`, `lib/widgets/relative_reorderable_list.dart` |
| 05 | Update tests and changelog | completed | `test/*`, `docs/project-changelog.md` |

## Implementation Strategy

- Add a `read` boolean to `AlertModel` with backward-compatible defaults.
- `AppState` exposes `alertBadgeCount` = alerts where `!read || !acknowledged`, and `markAllAlertsRead()` called when the Alerts tab is selected.
- `acknowledgeAlert` also marks the alert as `read`.
- Replace `SosNotificationList` in `RelativeReorderableList` with a new `SosLatestAlertBanner` widget using `AnimatedSwitcher`: child is the latest unacknowledged alert; old child slides down + fades out, new child slides in.
- Badge is rendered on the notifications icon in `SosBottomNav` using `BottomNavigationBarItem` + `Badge` widget.

## Success Criteria

- Home shows at most one SOS banner at a time.
- New SOS alert replaces old banner with slide-down/fade animation.
- Tapping banner opens `AlertDetailScreen`.
- Alerts tab badge reflects count of unread or unacknowledged alerts.
- Opening Alerts tab clears the unread portion of the badge.
- All existing tests pass; new tests cover badge count and banner child swap.

## Risk Summary

- The existing full-screen `activeAlert` auto-push in `HomeScreen` is kept; banner and auto-push can coexist, but user experience should be reviewed.
- AnimatedSwitcher key stability is critical to trigger exit animation.
- Marking all alerts as read on every Alerts tab tap must persist correctly.
