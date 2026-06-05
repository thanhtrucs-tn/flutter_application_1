---
title: "Phase 06 — Settings and Account Screens"
description: "Refactor settings into general settings and notification settings, create account screen."
status: pending
priority: P1
effort: 2h
created: 2026-06-06
---

# Phase 06 — Settings and Account Screens

## Context Links
- `lib/screens/settings_screen.dart`
- `lib/models/app_settings.dart`
- `lib/utils/app_state.dart`
- `lib/widgets/sos_app_header.dart`

## Overview
Redesign `settings_screen.dart` to match reference: sectioned layout (Account, Notifications, App, Info, Logout). Create `notification_settings_screen.dart` with toggles. Create `account_screen.dart` with profile info, update links, and logout.

## Key Insights
- Current `settings_screen.dart` is 272 lines and mixes system settings, relative management, and developer simulator sandbox.
- Reference image separates settings into clean sections. Developer sandbox should be kept but visually separated or moved to an "Advanced" expandable section.
- `AppSettings` model only has language, dark mode, sound, auto-call. The reference shows notification toggles (SOS alerts, safe zone, health reminders, firmware). Add booleans to `AppSettings` or keep them as UI-only toggles that write to `AppSettings` later.

## Requirements

### Functional

**General Settings Screen**
- Red header "Cài đặt" via `SosAppHeader`.
- Sections as `Card` with `ListTile` children:
  1. **Account**: "Change password" (placeholder dialog), "Update info" (placeholder dialog).
  2. **Notifications**: Navigate to `NotificationSettingsScreen`.
  3. **App**: Language toggle (existing switch), Dark mode toggle (existing switch).
  4. **Info**: Version text (static), Terms of service (placeholder).
  5. **Logout**: red `ListTile` with `Icons.logout` that triggers logout + push `LoginScreen`.
- Developer simulator sandbox preserved at bottom inside an `ExpansionTile` labeled "Developer Tools".
- Relative management list moved to `AccountScreen` or kept in a separate section. **Decision**: move to `AccountScreen` to keep Settings clean.

**Notification Settings Screen**
- Red header "Cài đặt thông báo" via `SosAppHeader` with back button.
- Toggles (store in `AppSettings` or `AppState`):
  - SOS alerts
  - Safe zone exit/enter
  - Health reminders
  - Firmware updates
- Each toggle is a `SwitchListTile` inside a `Card`.

**Account Screen**
- Red header "Tài khoản" via `SosAppHeader`.
- Profile card: avatar, name, email placeholder, role label.
- Sectioned list:
  - Update personal info
  - Change password
  - Manage relatives (list from current `settings_screen.dart`)
  - Logout button (red, full-width at bottom)

### Non-functional
- Each screen < 200 lines.
- `AppSettings` may need extension for notification toggles.

## Architecture

```
lib/screens/
  settings_screen.dart             (redesigned, <200 lines)
  notification_settings_screen.dart (new, <150 lines)
  account_screen.dart              (new, <200 lines)
lib/models/
  app_settings.dart                (updated: add notification toggles)
lib/widgets/
  settings_section_card.dart       (new, <60 lines)
```

## Related Code Files

### Modify
- `lib/screens/settings_screen.dart` — full redesign, extract sandbox to ExpansionTile
- `lib/models/app_settings.dart` — add fields: `bool notifySos`, `bool notifySafeZone`, `bool notifyHealth`, `bool notifyFirmware`

### Create
- `lib/screens/notification_settings_screen.dart`
- `lib/screens/account_screen.dart`
- `lib/widgets/settings_section_card.dart` — reusable `Card` with optional header text

## Implementation Steps

1. **Update app_settings.dart**
   - Add fields: `notifySos`, `notifySafeZone`, `notifyHealth`, `notifyFirmware` (default true).
   - Update `copyWith`, `fromMap`, `toMap`.
   - Update `defaultSettings` factory.

2. **Create settings_section_card.dart**
   - Stateless widget `SettingsSectionCard`.
   - Props: `title` (optional), `children`.
   - Build: `Card` with optional `ListTile` dense header, then `Column(children)`.

3. **Create notification_settings_screen.dart**
   - Stateful, listens to `AppState`.
   - `SosAppHeader(title: Localization.translate('notificationSettings'), showBackButton: true)`.
   - Body: `SingleChildScrollView` with 4 `SwitchListTile`s inside `SettingsSectionCard`.
   - Each switch calls `state.updateSettings(settings.copyWith(...))`.

4. **Create account_screen.dart**
   - Stateful, listens to `AppState`.
   - `SosAppHeader`.
   - Body `SingleChildScrollView`:
     - Profile card with avatar, name.
     - `SettingsSectionCard` "Account" with placeholder "Change password" and "Update info" tiles.
     - `SettingsSectionCard` "Relatives" with `ListView` of relatives (moved from old settings).
     - `SettingsSectionCard` "Actions" with red logout `ListTile`.
   - Logout navigates to `LoginScreen` with `pushAndRemoveUntil`.

5. **Redesign settings_screen.dart**
   - Keep `AnimatedBuilder`.
   - Replace body with:
     - `SettingsSectionCard` "Account" with tiles that push placeholder dialogs or `AccountScreen`.
     - `SettingsSectionCard` "Notifications" with tile pushing `NotificationSettingsScreen`.
     - `SettingsSectionCard` "App" with language and dark mode switches.
     - `SettingsSectionCard` "Info" with version and terms tiles.
     - `SettingsSectionCard` "Logout" with red logout tile.
     - `ExpansionTile` "Developer Tools" containing existing sandbox buttons.
   - Remove inline relative management list (moved to `AccountScreen`).

## Todo List

- [ ] Extend `AppSettings` with notification toggle fields
- [ ] Create `settings_section_card.dart`
- [ ] Create `notification_settings_screen.dart`
- [ ] Create `account_screen.dart`
- [ ] Redesign `settings_screen.dart`
- [ ] Verify settings persist after app restart
- [ ] Run compile check

## Success Criteria
- Settings screen shows clean sections matching reference image.
- Notification settings toggles persist via `AppState`.
- Account screen shows profile, relatives list, and logout.
- Developer sandbox accessible but not prominent.
- All screens under 200 lines.

## Risk Assessment
- **Risk**: Extending `AppSettings` serialization may break existing stored settings. **Mitigation**: `fromMap` uses `?? true` fallbacks for new fields; old JSON missing keys defaults safely.
- **Risk**: Moving relative management out of Settings may disorient users. **Mitigation**: Add a tile in Settings "Manage relatives" that navigates to Account screen relatives section.

## Next Steps
- Phase 07 (Integration & Testing) must integrate all screens with bottom nav and run full tests.
