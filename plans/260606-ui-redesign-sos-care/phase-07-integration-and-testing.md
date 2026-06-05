---
title: "Phase 07 — Integration and Testing"
description: "Wire bottom nav to all main screens, ensure back navigation, run compile checks and end-to-end validation."
status: pending
priority: P1
effort: 2h
created: 2026-06-06
---

# Phase 07 — Integration and Testing

## Context Links
- `lib/main.dart`
- `lib/widgets/sos_bottom_nav.dart`
- `lib/utils/app_state.dart`
- All screen files from Phases 01–06

## Overview
Integrate every redesigned and new screen into the `MainShell` bottom navigation. Ensure that:
- Bottom nav is hidden on sub-screens (Detail, Map, Alert Detail, etc.).
- Back navigation works correctly from sub-screens.
- All existing functionality (WebSocket simulation, SOS triggers, alert auto-push, settings persistence) remains intact.
- App compiles and passes a manual end-to-end walkthrough.

## Key Insights
- `MainShell` in `main.dart` must use `IndexedStack` to preserve page state across tab switches (so Home scroll position and simulation state remain).
- Sub-screens should be pushed via `Navigator.push` on top of `MainShell`, so bottom nav stays hidden behind the route.
- `AlertDetailScreen` is a full-screen overlay; it already pushes on top and should not show bottom nav.

## Requirements

### Functional
- `MainShell` pages:
  - index 0: `HomeScreen`
  - index 1: `AlertsScreen`
  - index 2: `AddAlertScreen`
  - index 3: `SettingsScreen`
  - index 4: `AccountScreen`
- Bottom nav `currentIndex` synced with `AppState.currentNavIndex`.
- Tapping a nav item calls `state.setNavIndex(index)`.
- Sub-screen navigation from any main tab uses `Navigator.push` and does not mutate nav index.
- Login flow: `main.dart` starts with `LoginScreen`; successful login pushes `MainShell` and removes login from stack (or uses conditional root).

### Non-functional
- Compile with zero errors.
- No deprecated API usage.
- All files under 200 lines (final audit).

## Architecture

```
lib/main.dart
  └─ LoginScreen
       └─ pushReplacement → MainShell
            ├─ IndexedStack
            │    ├─ HomeScreen
            │    ├─ AlertsScreen
            │    ├─ AddAlertScreen
            │    ├─ SettingsScreen
            │    └─ AccountScreen
            └─ SosBottomNav (outside IndexedStack, inside Scaffold)
```

## Related Code Files

### Modify
- `lib/main.dart` — finalize `MainShell` scaffold, `IndexedStack`, bottom nav wiring
- `lib/utils/app_state.dart` — ensure `setNavIndex` triggers `notifyListeners`

### Create (if needed)
- `lib/screens/login_screen.dart` — minor update if needed to push `MainShell` instead of `HomeScreen`

## Implementation Steps

1. **Finalize main.dart**
   - Define `MainShell` as `StatefulWidget`.
   - `build` returns `Scaffold`:
     - `body: IndexedStack(index: state.currentNavIndex, children: [HomeScreen(), AlertsScreen(), AddAlertScreen(), SettingsScreen(), AccountScreen()])`
     - `bottomNavigationBar: SosBottomNav(currentIndex: state.currentNavIndex, onTap: state.setNavIndex)`
   - Wrap `MainShell` in `AnimatedBuilder` if not already handled by child screens.
   - Keep `MaterialApp(home: LoginScreen())`.
   - Update `LoginScreen` to `Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainShell()))` upon success.

2. **Audit bottom nav visibility**
   - Verify `DetailScreen`, `MapViewScreen`, `HealthTrackingScreen`, `EmergencyContactsScreen`, `AlertDetailScreen`, `AddAlertScreen` (when pushed as sub-screen? No, it's a main tab), `NotificationSettingsScreen`, `AccountScreen` (when pushed from Settings? No, it's a main tab) do NOT have bottom nav.
   - Actually, `AccountScreen` IS a main tab, so it has nav. If pushed from elsewhere, it shouldn't.
   - Rule: only `MainShell` Scaffold has `bottomNavigationBar`. All other screens are plain `Scaffold` without bottom nav.

3. **Audit file sizes**
   - Run a script or manual check: every `.dart` file under `lib/screens/` and `lib/widgets/` should be <= 200 lines.
   - If any exceed, extract further widgets.

4. **End-to-end manual test checklist**
   - Launch app → Login → MainShell shows Home tab with red header and bottom nav.
   - Switch to Alerts tab → list renders.
   - Switch to Add tab → form renders.
   - Switch to Settings tab → sections render.
   - Switch to Account tab → profile and relatives render.
   - Tap elderly card on Home → Detail screen opens without bottom nav, red header, profile, actions.
   - Tap "View Map" → Map screen opens, full map, action overlay.
   - Tap SOS simulation in Settings developer tools → Alert auto-pushes, red blink screen shows.
   - Acknowledge alert → returns to previous screen.
   - Toggle dark mode → red headers adapt, all screens readable.
   - Change language → labels switch between vi/en.
   - Add alert via Add tab → appears in Alerts tab immediately.

5. **Compile check**
   - `flutter analyze`
   - `flutter build apk --split-debug-info=symbols` (or `flutter build ios` if macOS)
   - Fix any warnings/errors.

## Todo List

- [ ] Finalize `main.dart` `MainShell` with `IndexedStack` and bottom nav
- [ ] Update `LoginScreen` to push `MainShell` via `pushReplacement`
- [ ] Verify sub-screens do not show bottom nav
- [ ] Audit all new/modified files for <= 200 lines
- [ ] Run `flutter analyze` and fix errors
- [ ] Run end-to-end manual test checklist
- [ ] Document any deviations from reference image in plan notes

## Success Criteria
- App launches, logs in, and shows 5-tab bottom navigation.
- All 9 reference-image screens reachable and styled with red headers.
- Simulation, WebSocket status, auto-push alerts, settings persistence all work.
- Zero compile errors.
- All files under 200 lines.

## Risk Assessment
- **Risk**: `IndexedStack` keeps all 5 pages alive simultaneously, increasing memory use slightly. **Mitigation**: Acceptable for 5 simple Flutter screens; monitor if performance degrades.
- **Risk**: Back button on Android/Windows desktop from sub-screen may pop to wrong tab. **Mitigation**: Ensure `Navigator.push` uses proper route stack; `MainShell` is beneath pushed routes.

## Rollback Plan
- If integration fails catastrophically, revert `main.dart` and screen files to pre-plan state using git.
- No database or API changes, so rollback is purely code revert.

## Next Steps
- None. Plan complete.
