---
title: "Phase 03 — Elderly Detail and Map View"
description: "Redesign detail screen and create full-screen map view with red headers, action buttons, health metrics."
status: pending
priority: P1
effort: 2h
created: 2026-06-06
---

# Phase 03 — Elderly Detail and Map View

## Context Links
- `lib/screens/detail_screen.dart`
- `lib/widgets/sos_app_header.dart`
- `lib/widgets/custom_map.dart`
- `lib/models/elderly_model.dart`
- `lib/utils/app_state.dart`

## Overview
Redesign `detail_screen.dart` to match reference: red header "SOS Khẩn cấp", large avatar with name/age/address, 2x2 action button grid (call, ring, listen, SMS), health metrics panel, safe-zone slider. Create new `map_view_screen.dart` for full-screen map with safe zone circle and action overlays.

## Key Insights
- Current `detail_screen.dart` is 525 lines. Must split into reusable widgets.
- Reference image shows Detail and Map as separate screens. Detail should have a "View Map" button that pushes `MapViewScreen`.
- Existing action screens (`ringing_device_screen.dart`, `ambient_listen_screen.dart`, `send_sms_screen.dart`, `remote_sos_screen.dart`) keep their logic; only entry points change.

## Requirements

### Functional
- Red header with back arrow via `SosAppHeader`.
- Top profile section: large `CircleAvatar` (radius 40), name, age, address text.
- 2x2 grid of action buttons: Call (green), Ring (orange), Listen (teal), SMS (red). Each uses `BigButton` or a new compact action icon button.
- Health metrics panel: heart rate, SpO2, temperature, blood pressure in a 2x2 grid of metric cards.
- Status badge below metrics: colored pill (safe/warning/critical).
- Safe zone slider stays but styled to match new theme.
- "View Map" button pushes `MapViewScreen`.
- Keep test scenario button (developer feature) but visually de-emphasized.

### Map View Screen
- Red header: "Vị trí của [Name]".
- Full-screen `CustomMap` with safe zone circle and current location marker.
- Floating action buttons overlay at bottom-right or bottom-center: Call, Ring, Directions.
- Back button returns to Detail.

### Non-functional
- `detail_screen.dart` target: < 200 lines.
- Extracted widgets each < 200 lines.

## Architecture

```
lib/screens/
  detail_screen.dart         (redesigned, <200 lines)
  map_view_screen.dart       (new, <200 lines)
lib/widgets/
  profile_header.dart        (new, <80 lines)
  action_button_grid.dart    (new, <120 lines)
  health_metrics_panel.dart  (new, <120 lines)
  metric_card.dart           (new, <60 lines)
  safe_zone_slider.dart      (new, <80 lines)
  map_action_overlay.dart    (new, <80 lines)
```

## Related Code Files

### Modify
- `lib/screens/detail_screen.dart` — redesign, keep existing navigation to action screens and `_makeCall`

### Create
- `lib/screens/map_view_screen.dart` — full-screen map
- `lib/widgets/profile_header.dart` — avatar + name + address
- `lib/widgets/action_button_grid.dart` — 2x2 grid of action buttons
- `lib/widgets/health_metrics_panel.dart` — 2x2 grid of metric cards
- `lib/widgets/metric_card.dart` — single metric with icon, value, unit
- `lib/widgets/safe_zone_slider.dart` — slider with label and icon
- `lib/widgets/map_action_overlay.dart` — floating buttons on map

## Implementation Steps

1. **Create metric_card.dart**
   - Props: `icon`, `iconColor`, `label`, `value`, `unit`, `alert`.
   - Build: `Card` with padding, icon row, large value text, unit text, optional alert badge.

2. **Create health_metrics_panel.dart**
   - Props: `elderly`.
   - Build: `GridView.count(crossAxisCount: 2)` with 4 `MetricCard`s: heart rate, SpO2, temperature (placeholder/mock or add to model if needed), blood pressure (placeholder/mock).
   - Note: `ElderlyModel` does not have `temperature` or `bloodPressure`. For now use placeholder values (e.g., 36.5°C, 120/80) and mark with TODO to add fields later.

3. **Create profile_header.dart**
   - Props: `avatarUrl`, `name`, `age`, `address`, `statusColor`.
   - Build: centered column with large avatar, name bold, age + address muted, status dot.

4. **Create action_button_grid.dart**
   - Props: `onCall`, `onRing`, `onListen`, `onSms`.
   - Build: `GridView.count(crossAxisCount: 2, childAspectRatio: ~2.5)` with 4 custom action buttons.
   - Each button: colored rounded rectangle with icon and label.

5. **Create safe_zone_slider.dart**
   - Props: `value`, `onChanged`.
   - Build: row with `Icons.gpp_maybe`, `Expanded(Slider)`, radius label text.

6. **Create map_action_overlay.dart**
   - Props: `onCall`, `onRing`, `onDirections`.
   - Build: `Positioned` or `Align` at bottom with a row of 3 circular floating buttons.

7. **Create map_view_screen.dart**
   - Stateful or Stateless. Props: `elderly`.
   - `Scaffold` with `SosAppHeader(title: "Vị trí của ${elderly.name}", showBackButton: true)`.
   - Body: `Stack` with `CustomMap` (full size) and `MapActionOverlay`.
   - Use `flutter_map` safe zone circle and marker.

8. **Rewrite detail_screen.dart**
   - `SosAppHeader` with title "SOS Khẩn cấp" or elderly name.
   - `SingleChildScrollView` body:
     - `ProfileHeader`
     - `ActionButtonGrid`
     - `HealthMetricsPanel`
     - `SafeZoneSlider`
     - `CustomMap` (compact, height 200) with tap to push `MapViewScreen`
     - `BigButton` remote SOS
     - Test scenario card (keep but smaller)
   - Keep `_makeCall`, `_openRingingDevice`, etc. methods.
   - Keep `AnimatedBuilder` listening to `AppState`.
   - Target < 200 lines.

## Todo List

- [ ] Create `metric_card.dart`
- [ ] Create `health_metrics_panel.dart`
- [ ] Create `profile_header.dart`
- [ ] Create `action_button_grid.dart`
- [ ] Create `safe_zone_slider.dart`
- [ ] Create `map_action_overlay.dart`
- [ ] Create `map_view_screen.dart`
- [ ] Rewrite `detail_screen.dart`
- [ ] Verify detail + map navigation works
- [ ] Run compile check

## Success Criteria
- Detail screen shows profile, actions, health metrics, safe zone, and compact map.
- Tapping compact map opens `MapViewScreen` with full map and action overlay.
- All existing action screen navigations preserved.
- File sizes under 200 lines.

## Risk Assessment
- **Risk**: `ElderlyModel` lacks temperature/bloodPressure fields. **Mitigation**: Use placeholder values in `HealthMetricsPanel` and note in plan to add fields later if required.
- **Risk**: Map safe zone circle rendering may differ in full-screen. **Mitigation**: Reuse `CustomMap` parameters exactly.

## Next Steps
- Phase 04 (Health tracking + Emergency contacts) can run in parallel.
