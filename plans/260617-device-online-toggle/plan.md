---
title: "Device Online/Offline Toggle in Test Scenario"
description: "Make the THIẾT BỊ ONLINE scenario card in TestScenarioScreen act as a toggle: tapping it switches the selected elderly between online and offline states."
status: in_progress
priority: P2
effort: 1h
branch: main
tags: [flutter, ui, simulation, device-status]
created: 2026-06-17
---

## Overview

User wants the test-scenario screen to support toggling a relative's device online/offline with a single card:
- When the device is currently **offline**, the card shows **"THIẾT BỊ ONLINE"** and tapping makes it online.
- When the device is currently **online**, the card shows **"THIẾT BỊ OFFLINE"** and tapping makes it offline.
- The card must update reactively as the device state changes.

## Context Links

- `lib/screens/test_scenario_screen.dart`: screen with 4 scenario cards.
- `lib/utils/app_state.dart`: state methods `simulateDeviceOnline`, `updateElderly`.
- `lib/widgets/developer_tools_section.dart`: Developer Tools section with duplicate online/offline buttons.
- `lib/models/elderly_model.dart`: `isOffline` field.
- `docs/project-changelog.md`: project changelog.

## Phases

| Phase | Description | Status | File |
|---|---|---|---|
| 01 | Add `simulateDeviceOffline` API to `AppState` | pending | `lib/utils/app_state.dart` |
| 02 | Make Online scenario card a reactive toggle in `TestScenarioScreen` | pending | `lib/screens/test_scenario_screen.dart` |
| 03 | Consolidate Developer Tools online/offline button | pending | `lib/widgets/developer_tools_section.dart` |
| 04 | Add widget test for toggle behavior and update changelog | pending | `test/test_scenario_online_toggle_test.dart`, `docs/project-changelog.md` |

## Key Decisions

- Add a dedicated `simulateDeviceOffline` method in `AppState` (sets `isOffline: true`, `battery: 0`, `heartRate: 0`, `spo2: 0`, updates `lastUpdated`).
- Keep `simulateDeviceOnline` unchanged; UI decides which method to call based on current `elderly.isOffline`.
- Wrap the scenario card (or the whole screen) in `AnimatedBuilder` listening to `AppState()` so the label/icon updates immediately when state changes.
- Update `DeveloperToolsSection` to use a single toggle button that matches the behavior, removing the separate "ĐỔI ONLINE/OFFLINE" outlined button.
- Test: verify tapping the card when offline calls online, and tapping again when online calls offline.
