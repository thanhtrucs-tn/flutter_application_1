---
title: "Phase 02 — Home Screen Redesign"
description: "Redesign Home screen with red header, elderly cards with vitals, status banner, modular widgets."
status: pending
priority: P1
effort: 2h
created: 2026-06-06
---

# Phase 02 — Home Screen Redesign

## Context Links
- `lib/screens/home_screen.dart`
- `lib/widgets/sos_app_header.dart` (from Phase 01)
- `lib/models/elderly_model.dart`
- `lib/utils/app_state.dart`

## Overview
Rewrite `home_screen.dart` to match the reference image: red header with "SOS Care" title and monitor account badge; scrollable list of elderly cards showing heart rate, SpO2, battery; status banner; bottom nav stays external (in `MainShell`).

## Key Insights
- Current `home_screen.dart` is 643 lines. Must split into smaller widgets.
- Auto-push alert logic (lines 118–149) is critical and must be preserved exactly.
- Map mini-view on home can stay or be moved to a tap-to-expand flow. Reference image shows map as separate screen, so the home map mini-view may be reduced or replaced with a "View Map" button.

## Requirements

### Functional
- Red header via `SosAppHeader` with title "SOS Care" and a small monitor account badge.
- Status banner at top: green/orange/red based on relatives' aggregated status.
- Elderly list cards: avatar, name, status dot, heart rate, SpO2, battery, last update time.
- Tap card navigates to `DetailScreen` (redesigned in Phase 03).
- Floating map mini-view replaced with a compact "View Map" row or removed (map is full-screen in Phase 03).
- SOS history section moved to `AlertsScreen` (Phase 05). Home shows only elderly cards + status banner.

### Non-functional
- `home_screen.dart` target: < 200 lines.
- Extracted widgets each < 200 lines.

## Architecture

```
lib/screens/home_screen.dart          (redesigned, <200 lines)
lib/widgets/status_banner.dart        (new, <100 lines)
lib/widgets/elderly_list_card.dart    (new, <150 lines)
lib/widgets/vital_badge.dart          (new, <50 lines)
```

## Related Code Files

### Modify
- `lib/screens/home_screen.dart` — full rewrite keeping auto-push alert logic intact

### Create
- `lib/widgets/status_banner.dart` — colored banner with icon, title, description
- `lib/widgets/elderly_list_card.dart` — card for one elderly with vitals row
- `lib/widgets/vital_badge.dart` — small pill with icon + value

## Implementation Steps

1. **Create vital_badge.dart**
   - Stateless widget `VitalBadge`.
   - Props: `icon`, `color`, `value`, `isSmall` (default true).
   - Build: rounded container with background opacity 0.06, icon + text row.

2. **Create status_banner.dart**
   - Stateless widget `StatusBanner`.
   - Props: `status` enum (`safe`, `warning`, `critical`).
   - Build: `Container` with gradient/color, icon, title, subtitle.
   - Colors: green (`statusSafe`), orange (`statusWarning`), red (`statusCritical`).

3. **Create elderly_list_card.dart**
   - Stateless widget `ElderlyListCard`.
   - Props: `elderly` (ElderlyModel), `isSelected`, `onTap`, `onLocateTap`.
   - Build:
     - `Card` with border side color based on status.
     - Top row: `CircleAvatar` (avatar), name + status dot, `IconButton` for locate.
     - Vitals row: 3 `VitalBadge`s (heart rate, SpO2, battery).
     - Bottom row: last update time + status pill.
   - Keep all existing interaction behavior.

4. **Rewrite home_screen.dart**
   - Use `SosAppHeader` with title "SOS Care" and a leading account badge row.
   - Keep `AnimatedBuilder` listening to `AppState`.
   - Keep auto-push `activeAlert` logic exactly as current lines 118–149.
   - Build body:
     - `StatusBanner` (computed from relatives statuses).
     - `ListView.builder` of `ElderlyListCard`.
   - Remove inline map widget and SOS history list (moved to other screens).
   - Remove floating action button (Add is in bottom nav now).
   - Remove settings/logout actions from AppBar (moved to Settings/Account tabs).
   - File size target < 200 lines.

## Todo List

- [ ] Create `vital_badge.dart`
- [ ] Create `status_banner.dart`
- [ ] Create `elderly_list_card.dart`
- [ ] Rewrite `home_screen.dart` with extracted widgets
- [ ] Preserve auto-push alert logic verbatim
- [ ] Verify file sizes are under 200 lines
- [ ] Run compile check

## Success Criteria
- Home screen renders elderly cards matching reference style.
- Auto-push alert still navigates to `AlertDetailScreen` when active alert fires.
- File `home_screen.dart` < 200 lines.

## Risk Assessment
- **Risk**: Removing SOS history from home may confuse users used to old layout. **Mitigation**: History is one tap away via bottom nav Alerts tab.
- **Risk**: Auto-push alert logic is fragile. **Mitigation**: Copy-paste exact current implementation; test with simulator buttons.

## Next Steps
- Phase 03 (Elderly Detail + Map) depends on `elderly_list_card.dart` tap navigation.
