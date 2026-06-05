---
title: "Phase 05 — Alerts List and Add Alert Screens"
description: "Create dedicated alerts history screen and add-alert form screen with red headers."
status: pending
priority: P1
effort: 2h
created: 2026-06-06
---

# Phase 05 — Alerts Flow

## Context Links
- `lib/models/alert_model.dart`
- `lib/utils/app_state.dart`
- `lib/widgets/sos_app_header.dart`
- `lib/screens/alert_detail_screen.dart`

## Overview
Build two new screens:
- `AlertsScreen`: full alert history list moved out of Home. Shows all alerts with filtering/status chips. Tapping an alert opens `AlertDetailScreen`.
- `AddAlertScreen`: form to manually add a new alert (title, content, urgency level, related person picker). Save inserts into `AppState.alerts`.

## Key Insights
- Home screen currently shows only the latest 5 alerts. The new `AlertsScreen` shows the full `AppState.alerts` list.
- `AddAlertScreen` serves the "Add" tab in bottom nav. It can also be used to manually log incidents.
- `AlertDetailScreen` (existing) is a push-only emergency screen and does not need redesign beyond ensuring its red emergency background still contrasts with the new global theme.

## Requirements

### Functional

**Alerts Screen**
- Red header via `SosAppHeader` with title "Alerts" (localized).
- Filter chips at top: All, Critical, Warning, Unacknowledged.
- List of alerts: each row shows urgency icon, message, time, location snippet, acknowledged pill.
- Tap row pushes `AlertDetailScreen` (existing) for critical/warning detail.
- Swipe-to-dismiss or long-press menu to acknowledge/delete.

**Add Alert Screen**
- Red header "Thêm cảnh báo mới" via `SosAppHeader`.
- Form fields:
  - Title (`TextFormField`)
  - Content (`TextFormField`, maxLines 3)
  - Level (`DropdownButtonFormField`: Critical / Warning)
  - Related person (`DropdownButtonFormField` populated from `AppState.relatives`)
- Red "Save" button at bottom.
- On save: create `AlertModel`, insert into `AppState.alerts`, pop back.

### Non-functional
- Each file < 200 lines.
- Reuse existing `AlertModel.copyWith` / `fromMap` patterns.

## Architecture

```
lib/screens/
  alerts_screen.dart      (new, <200 lines)
  add_alert_screen.dart   (new, <200 lines)
lib/widgets/
  alert_list_item.dart    (new, <80 lines)
  filter_chip_bar.dart    (new, <60 lines)
```

## Related Code Files

### Create
- `lib/screens/alerts_screen.dart` — full alert history with filters
- `lib/screens/add_alert_screen.dart` — manual alert creation form
- `lib/widgets/alert_list_item.dart` — single alert row
- `lib/widgets/filter_chip_bar.dart` — horizontal chips for filtering

### Modify (minor)
- `lib/screens/alert_detail_screen.dart` — verify red emergency background still works; no major changes needed.

## Implementation Steps

1. **Create filter_chip_bar.dart**
   - Stateless widget `FilterChipBar`.
   - Props: `options` (List<String>), `selected`, `onSelected`.
   - Build: `Wrap` or `ListView` horizontal of `ChoiceChip`s.

2. **Create alert_list_item.dart**
   - Stateless widget `AlertListItem`.
   - Props: `alert`.
   - Build: `ListTile` leading with urgency icon, title = message, subtitle = time + location, trailing = acknowledged pill.
   - Colors: red for critical, orange for warning.

3. **Create alerts_screen.dart**
   - Stateful. Use `AnimatedBuilder` on `AppState`.
   - `SosAppHeader` with back if pushed from non-main context, or without back if inside `MainShell`.
   - Body:
     - `FilterChipBar` (All, Critical, Warning, Unacknowledged).
     - `ListView.builder` of filtered `AlertListItem`s.
   - Filter logic in `build` based on selected chip.

4. **Create add_alert_screen.dart**
   - Stateful with `GlobalKey<FormState>`.
   - `SosAppHeader(showBackButton: true)`.
   - Body `SingleChildScrollView` with `Form`:
     - Title field
     - Content field
     - Level dropdown
     - Related person dropdown
     - SizedBox(height: 24)
     - `BigButton` or `ElevatedButton` Save
   - On save:
     - Validate form.
     - Build `AlertModel` with generated id, current time, placeholder lat/lng from selected relative.
     - `AppState().alerts.insert(0, newAlert); AppState().notifyListeners();`
     - `Navigator.pop(context)`.

## Todo List

- [ ] Create `filter_chip_bar.dart`
- [ ] Create `alert_list_item.dart`
- [ ] Create `alerts_screen.dart`
- [ ] Create `add_alert_screen.dart`
- [ ] Verify tapping alert opens `AlertDetailScreen`
- [ ] Verify saving new alert appears in alerts list immediately
- [ ] Run compile check

## Success Criteria
- Alerts screen lists all alerts with filter chips.
- Add alert form validates and inserts new alert into history.
- Both screens under 200 lines.

## Risk Assessment
- **Risk**: `AddAlertScreen` requires lat/lng for `AlertModel`; user may not have GPS intent. **Mitigation**: Use selected relative's current lat/lng as default location.

## Next Steps
- Phase 06 (Settings & Account) can run in parallel.
