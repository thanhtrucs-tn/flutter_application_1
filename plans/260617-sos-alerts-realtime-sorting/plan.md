---
title: "SOS Alerts Realtime Sorting, Auto-Acknowledge Fix, and Device Badges"
description: "Fix fall-detection auto-acknowledge bug, sort SOS alerts by unacknowledged/newest, add timestamp badges and highlight animation, expose latest SOS list on Home with smooth reordering, and make device online badge update immediately."
status: completed
priority: P1
effort: 6h
branch: main
tags: [flutter, app-state, ui, sos-alerts, realtime, animations]
created: 2026-06-17
---

## Overview

User reports four related issues in the SOS Care Flutter app:

1. **Fall detection auto-acknowledged** — SOS alerts triggered by fall detection (`simulateFall`) sometimes show as "ĐÃ XỬ LÝ" without user interaction.
2. **Alert list ordering** — processed alerts should sink to bottom; unprocessed alerts should bubble to top sorted by newest first.
3. **Timestamp badge** — every notification card needs a detailed timestamp `dd/mm/yyyy - hh:mm:ss` in the top-right corner.
4. **Latest-notification highlight** — only the newest notification should pulse/highlight inside the correct screen zone.
5. **Home SOS priority** — on Home, the SOS section should also show the newest alert on top and slide older ones down smoothly, mirroring the alert detail/list behaviour.
6. **Online device badge delay** — the online indicator for relatives lags; it must update immediately when `isOffline` changes.

## Root-Cause Findings

- `lib/utils/app_state.dart:642` uses `elderly.status == 'critical'` as a proxy for "was outside safe zone". A fall alert also sets `status='critical'`, so when the simulation tick sees the elder back inside the zone it auto-calls `acknowledgeAlert` on the active fall alert.
- `AlertsScreen` filters alerts but does **not** re-sort them by `acknowledged` + `time`, so processed and unprocessed alerts stay mixed.
- `AlertListItem` only shows `HH:MM` and has no timestamp badge.
- `HomeScreen` only pushes the single `activeAlert` fullscreen and has no inline SOS list, so users cannot see multiple alerts on Home.
- `ElderlyCardContent` shows a small status dot + text but no explicit "online/offline" badge, and the status text can lag if a parent rebuild is skipped.

## Phases

| Phase | Description | Status | File |
|---|---|---|---|
| 01 | Fix AppState simulation so fall alerts are never auto-acknowledged by geofence logic | completed | `lib/utils/app_state.dart`, `lib/models/alert_model.dart` |
| 02 | Add alert sorting helper, timestamp badge, and latest-highlight widget | completed | `lib/widgets/alert_list_item.dart`, `lib/screens/alerts_screen.dart` |
| 03 | Build inline SOS notification list on Home with AnimatedList / ImplicitlyAnimatedReorder | completed | `lib/widgets/sos_notification_list.dart`, `lib/widgets/relative_reorderable_list.dart` |
| 04 | Add dedicated online/offline badge with immediate rebuild wiring | completed | `lib/widgets/device_online_badge.dart`, `lib/widgets/elderly_card_content.dart` |
| 05 | Update tests and changelog | completed | `test/alert_sorting_and_autoack_test.dart`, `test/alert_list_item_test.dart`, `docs/project-changelog.md` |

## Key Dependencies

- `AppState` singleton at `lib/utils/app_state.dart:15`.
- `AlertModel` at `lib/models/alert_model.dart:2`.
- `ElderlyModel` at `lib/models/elderly_model.dart:4`.
- `AlertsScreen` at `lib/screens/alerts_screen.dart:11`.
- `AlertListItem` at `lib/widgets/alert_list_item.dart:5`.
- `HomeScreen` at `lib/screens/home_screen.dart:11`.
- `RelativeReorderableList` / `ElderlyCardContent` at `lib/widgets/relative_reorderable_list.dart:22` and `lib/widgets/elderly_card_content.dart:8`.

## Implementation Strategy

### Phase 01 — Auto-acknowledge fix

- Stop using `elderly.status == 'critical'` as the "was outside" signal.
- Track geofence state separately (e.g. a local `bool wasOutsideSafeZone` derived from actual GPS distance vs radius before the update).
- Only acknowledge the active alert on `!isOutsideSafeZone && wasOutsideSafeZone` (genuine return to safe zone).
- Fall alerts (`isFallen` or message contains fall keywords) must require manual acknowledgement.

### Phase 02 — Alert list enhancements

- Add `AppState.getSortedAlerts()` / `AlertsScreen._sortedAlerts` that returns:
  1. Unacknowledged alerts first, sorted `time` descending.
  2. Acknowledged alerts second, sorted `time` descending.
- Extend `AlertListItem`:
  - Accept `isLatest` flag.
  - Show `dd/MM/yyyy - HH:mm:ss` badge in the top-right corner.
  - Wrap card in an `AnimatedContainer` or `AnimatedBuilder` highlight when `isLatest` is true; animation is a subtle border/pulse, scoped to the card only.
- Update `AlertsScreen` to use sorted list and pass `isLatest` for the first item.

### Phase 03 — Home SOS list

- Create a new `SosNotificationList` widget (or inline section) displayed above the relatives list when unacknowledged alerts exist.
- Use an `AnimatedList` or `SliverAnimatedList` with stable keys so newly-inserted latest alerts slide in at the top and older alerts smoothly move down.
- Limit Home list to the 3–5 most recent unacknowledged critical alerts (or all unacknowledged if small) to avoid overwhelming the home screen.
- Tapping an item opens `AlertDetailScreen`.
- Keep the existing full-screen `activeAlert` modal for the single currently-active critical alert, but ensure it does not auto-acknowledge on background navigation (remove the `!isCurrentHome` acknowledge shortcut).

### Phase 04 — Online badge realtime

- Add a dedicated `DeviceOnlineBadge` widget that displays "ONLINE" / "OFFLINE" with green/grey chip styling.
- Place it next to the wearable-device line in `ElderlyCardContent`.
- Ensure `simulateDeviceOnline`, battery-depletion path in `startSimulation`, and any other `isOffline` mutation all call `notifyListeners()` immediately.
- Verify every screen that reads `elderly.isOffline` is wrapped in `AnimatedBuilder` listening to `AppState`.

### Phase 05 — Tests & docs

- Unit test: fall alert remains unacknowledged after simulation tick where elder is inside safe zone.
- Unit test: sorted alerts order = unacknowledged newest first, then acknowledged newest first.
- Widget test: `AlertListItem` renders timestamp badge and highlight only on `isLatest`.
- Widget test: Home SOS list renders and opens detail on tap.
- Update `docs/project-changelog.md`.

## Risk Summary

- Removing the `!isCurrentHome` auto-acknowledge path means alerts may re-trigger if user navigates while an active alert exists; we must clear `_pushedAlertId` correctly without acknowledging.
- AnimatedList requires stable keys and careful insert/remove item builders; tests must cover insert order.
- Status-banner text may overlap with the new Home SOS list; keep banner as summary and list as detail.
