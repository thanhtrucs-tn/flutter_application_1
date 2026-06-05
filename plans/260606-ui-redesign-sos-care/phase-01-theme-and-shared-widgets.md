---
title: "Phase 01 — Theme Update and Shared Widgets"
description: "Update theme with red-header AppBar, create reusable header and bottom nav widgets, add localization keys."
status: pending
priority: P1
effort: 2h
created: 2026-06-06
---

# Phase 01 — Theme Update and Shared Widgets

## Context Links
- `lib/utils/theme.dart`
- `lib/utils/localization.dart`
- `lib/main.dart`
- `lib/utils/app_state.dart`

## Overview
Prepare the visual foundation: red-gradient AppBar theme, shared `SosAppHeader`, shared `SosBottomNavBar`, and all new localization keys needed by redesigned screens.

## Key Insights
- Current `AppBar` is white/dark flat. Reference image uses a red header.
- Bottom nav must persist on 5 main tabs. Sub-screens push without bottom nav.
- `AppState` already drives `AnimatedBuilder` in `main.dart`; add a `currentNavIndex` field for bottom-nav state.

## Requirements

### Functional
- `AppTheme.lightTheme.appBarTheme` gets red gradient background, white title/icons.
- `AppTheme.darkTheme.appBarTheme` gets deeper red background, white title/icons.
- New widget `SosAppHeader` supports title, optional subtitle, optional back button, optional action icons.
- New widget `SosBottomNavBar` wraps `BottomNavigationBar` with 5 items: Home, Alerts, Add, Settings, Account.
- New localization keys added for every label in reference image.

### Non-functional
- Every new widget file under 200 lines.
- No breaking changes to existing screens yet (theme change is global but safe).

## Architecture

```
lib/
  utils/
    theme.dart          (updated)
    localization.dart   (updated)
    app_state.dart      (updated: add nav index)
  widgets/
    sos_app_header.dart (new)
    sos_bottom_nav.dart (new)
```

## Related Code Files

### Modify
- `lib/utils/theme.dart` — update `appBarTheme` colors for red header
- `lib/utils/localization.dart` — add missing keys
- `lib/utils/app_state.dart` — add `int currentNavIndex` with getter/setter + notifyListeners
- `lib/main.dart` — replace `home: LoginScreen()` with a `MainShell` that shows bottom nav after login

### Create
- `lib/widgets/sos_app_header.dart` — reusable red gradient AppBar
- `lib/widgets/sos_bottom_nav.dart` — bottom nav bar widget

## Implementation Steps

1. **Update theme.dart**
   - Change `AppBarTheme` in `lightTheme`:
     - `backgroundColor`: `AppTheme.statusCritical` (or a red gradient — note: Flutter AppBar doesn't do gradients natively, so use `AppTheme.statusCritical` as solid color, or build gradient in `SosAppHeader` via `flexibleSpace`).
     - `foregroundColor`: `Colors.white`
     - `elevation`: 0
   - Change `AppBarTheme` in `darkTheme` similarly with slightly darker red.
   - Keep all other theme properties intact.

2. **Update localization.dart**
   - Add keys (both `vi` and `en`):
     - `home`, `alerts`, `add`, `account`, `mapViewTitle`, `healthTracking`, `emergencyContactsTitle`, `callNow`, `addContact`, `sosAlerts`, `safeZoneAlerts`, `healthReminders`, `firmwareUpdates`, `changePassword`, `updateInfo`, `notificationSettings`, `generalSettings`, `language`, `version`, `termsOfService`, `logoutConfirm`, `title`, `content`, `level`, `relatedPerson`, `saveAlert`, `temperature`, `bloodPressure`, `statusNormal`, `directions`, `sms`, `listen`, `ring`, `age`, `address`
   - Verify no existing keys removed.

3. **Update app_state.dart**
   - Add `int _currentNavIndex = 0;`
   - Add getter `int get currentNavIndex => _currentNavIndex;`
   - Add setter `void setNavIndex(int index) { _currentNavIndex = index; notifyListeners(); }`
   - `setNavIndex` is used by bottom nav tap.

4. **Create sos_app_header.dart**
   - Stateless widget `SosAppHeader`.
   - Props: `title`, `subtitle` (optional), `showBackButton` (default false), `actions` (List<Widget>?), `bottom` (PreferredSizeWidget?).
   - Build: `AppBar` with `flexibleSpace: Container(decoration: BoxDecoration(gradient: LinearGradient(...)))`.
   - Gradient colors: `[Color(0xFFE53935), Color(0xFFB71C1C)]` for light; slightly darker for dark.
   - Text style: white, bold, size 20.

5. **Create sos_bottom_nav.dart**
   - Stateless widget `SosBottomNav`.
   - Props: `currentIndex`, `onTap`.
   - Items:
     - Home (`Icons.home_filled`) — label `Localization.translate('home')`
     - Alerts (`Icons.notifications`) — label `Localization.translate('alerts')`
     - Add (`Icons.add_circle`) — label `Localization.translate('add')`
     - Settings (`Icons.settings`) — label `Localization.translate('settings')`
     - Account (`Icons.person`) — label `Localization.translate('account')`
   - Selected item color: `AppTheme.statusCritical`.
   - Unselected color: grey.

6. **Update main.dart**
   - Introduce `MainShell` StatefulWidget that hosts:
     - `PageView` or `IndexedStack` with 5 pages:
       1. `HomeScreen`
       2. `AlertsScreen` (placeholder or existing alert list)
       3. `AddAlertScreen` (placeholder)
       4. `SettingsScreen`
       5. `AccountScreen` (placeholder)
     - `SosBottomNav` below.
   - Keep `LoginScreen` as initial route; after login push `MainShell`.
   - Ensure `AppState().setNavIndex` syncs with `PageController`.

## Todo List

- [ ] Update `theme.dart` AppBarTheme to red
- [ ] Add new localization keys to `localization.dart`
- [ ] Add `currentNavIndex` to `app_state.dart`
- [ ] Create `sos_app_header.dart`
- [ ] Create `sos_bottom_nav.dart`
- [ ] Update `main.dart` with `MainShell` and nav wiring
- [ ] Run `flutter analyze` / compile check

## Success Criteria
- `flutter build apk` (or `flutter analyze`) passes with no errors.
- New widgets render correctly in a test page.
- Bottom nav switches between 5 placeholder pages.

## Risk Assessment
- **Risk**: AppBar gradient may not apply globally to all screens if some use custom AppBar. **Mitigation**: `SosAppHeader` is used explicitly per screen; global theme is fallback.

## Next Steps
- Phase 02 (Home screen) depends on `sos_app_header.dart` and `sos_bottom_nav.dart`.
