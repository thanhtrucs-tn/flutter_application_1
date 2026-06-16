# Phase 05 — Run, Test & Verify

## Context Links

- `Project_GiaLap/sos_care_backend/package.json`
- `Project_GiaLap/sos_device_simulator/pubspec.yaml`
- `pubspec.yaml`
- `test/` folder

## Overview

Run the backend, simulator, and target app together; validate every simulator button; run compile and unit tests.

## Key Insights

- Backend listens on `8080`; the simulator already posts to `http://localhost:8080`.
- For Android emulator testing, the target app must connect to `10.0.2.2:8080`.
- For Windows desktop testing, `localhost:8080` works directly.

## Requirements

- Functional: every simulator control produces a visible change in the target app.
- Non-functional: no regressions in existing `flutter test`.

## Architecture

- Three independent processes: Node backend, Flutter simulator, Flutter target app.
- Verify via logs, UI, and notifications.

## Related Code Files

- No new files are created in this phase; only runtime configuration and verification.

## Implementation Steps / Test Procedure

1. Backend:
   - `cd Project_GiaLap/sos_care_backend`
   - Ensure `.env` has DB credentials and `PORT=8080`.
   - `npm install`
   - `npm run dev:fast` (or `npm run dev`)
   - Confirm log: `Server running on port 8080`.
2. Simulator:
   - `cd Project_GiaLap/sos_device_simulator`
   - `flutter pub get`
   - `flutter run -d windows` (or your preferred device)
   - Confirm card shows Online and device id `SOS-DEVICE-001` / elderly `ELDERLY-001`.
3. Target app:
   - `cd flutter_application_1`
   - `flutter pub get`
   - Windows: `flutter run -d windows`
   - Android emulator: `flutter run`; ensure the service uses `10.0.2.2:8080`.
4. Test matrix:
   | Simulator action | Expected result in app |
   |---|---|
   | SOS button | Full-screen `AlertDetailScreen` + local notification |
   | Fall button | Critical alert + notification |
   | Heart rate slider > 110 | Automatic `HEART_RATE_ALERT` → warning alert + notification |
   | Battery slider to 15% | Battery UI updates + low-battery notification |
   | Toggle Online off | Elderly card shows Offline; vitals zeroed |
   | Toggle Online on | Elderly card shows Online; vitals restored |
   | Send current location | Detail / map screen reflects new coordinates |
5. Compile verification:
   - `flutter build apk --debug`
   - `flutter test`
6. Capture screenshots / logs and note any deviations.

## TODO

- [ ] Start backend and confirm listening on `8080`.
- [ ] Start simulator and confirm it is Online.
- [ ] Start target app and confirm socket connected in logs.
- [ ] Run each simulator button and verify UI / notification.
- [ ] Run `flutter build apk --debug` (or `flutter build windows`).
- [ ] Run `flutter test` and fix regressions.

## Success Criteria

- All five event types produce the expected UI updates or notifications.
- `flutter build apk --debug` succeeds.
- `flutter test` passes with no new failures.
- `npm run dev:fast` starts the backend without errors.

## Risk Assessment

- MySQL / DB not configured → backend crashes. Mitigation: run migrations and seed first (`npm run db:create`, `npm run migrate`).
- Windows Defender Firewall blocks Node on `8080`. Mitigation: allow Node.js in firewall or run backend with firewall disabled for local testing.
- Android emulator cannot reach desktop backend. Mitigation: use `10.0.2.2:8080` and ensure backend binds to `0.0.0.0`.

## Security Considerations

- All testing uses local HTTP. Do not commit `.env` or DB credentials.
- Disable cleartext traffic and switch to HTTPS before any production build.

## Next Steps

- Phase 06 to update documentation and run code review.
