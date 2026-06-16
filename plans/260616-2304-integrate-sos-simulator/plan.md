# Plan: Integrate SOS Device Simulator with flutter_application_1

**Date:** 2026-06-16  
**Folder:** `D:\App Mobile\flutter_application_1\plans\260616-2304-integrate-sos-simulator`  
**Goal:** Route realtime SOS / fall / heart-rate / location / battery events from `Project_GiaLap/sos_device_simulator` → `Project_GiaLap/sos_care_backend` → `flutter_application_1`, displayed as alerts and elderly status updates.

## Phases

1. [phase-01-dependencies-platform-config.md](./phase-01-dependencies-platform-config.md) — Add `socket_io_client` + `flutter_local_notifications`; configure Android / iOS / Windows.
2. [phase-02-event-contract-mapping.md](./phase-02-event-contract-mapping.md) — Document backend payloads and map `deviceId` / `elderlyId` strings to `ElderlyModel.id`.
3. [phase-03-device-event-service.md](./phase-03-device-event-service.md) — Build Socket.IO service and event handler; wire into `AppState`.
4. [phase-04-notification-service.md](./phase-04-notification-service.md) — Build local notification service and initialize in `main.dart`.
5. [phase-05-test-run-verify.md](./phase-05-test-run-verify.md) — Run all three components, test every simulator button, compile/test.
6. [phase-06-docs-review.md](./phase-06-docs-review.md) — Update changelog / note docs and run code review.

## Key decisions

- `socket_io_client: ^2.0.0` and `flutter_local_notifications: ^22.0.1`.
- Connection URL `http://localhost:8080` on desktop / iOS; `http://10.0.2.2:8080` on Android emulator.
- Mapping priority: (1) numeric suffix of `elderlyId` (e.g. `ELDERLY-001` → `1`), (2) `deviceId` vs `wearableDevice`, (3) create temporary `ElderlyModel` with a negative generated id.
- Local simulation in `AppState` is stopped once real Socket.IO data arrives to avoid conflicting fake data.
- Notifications are shown for SOS, fall, heart-rate warning, and low battery (`battery <= 20`).

## TODO

- [ ] phase-01: add dependencies, run `flutter pub get`, update `AndroidManifest.xml` + icon + `build.gradle.kts`, iOS `AppDelegate.swift`, Windows init settings.
- [ ] phase-02: confirm backend payloads; add `DeviceEventService` elderly resolution helper.
- [ ] phase-03: create `socket_io_service.dart` and `device_event_service.dart`; call from `AppState` / `main.dart`; stop simulation on first real event.
- [ ] phase-04: create `notification_service.dart`; request permissions; show heads-up alerts.
- [ ] phase-05: run backend (`npm run dev:fast`), simulator (`flutter run`), app (`flutter run` / `flutter build apk --debug`); test all buttons; run `flutter test`.
- [ ] phase-06: update `docs/project-changelog.md` and `docs/note-code-chi-tiet.md`; run `code-reviewer` agent; fix blockers.
