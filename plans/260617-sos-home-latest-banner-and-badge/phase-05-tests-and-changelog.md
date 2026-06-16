---
title: "Phase 05 — Tests and changelog"
---

## Overview

Add tests for the new badge count and banner behavior, then update the project changelog.

## Requirements

- Cover `alertBadgeCount` with read/unread and acknowledged states.
- Cover `markAllAlertsRead()` behavior.
- Widget test for `SosLatestAlertBanner` child swap / tap.
- Update `docs/project-changelog.md`.

## Related Code Files

- Add: `test/alert_badge_test.dart`
- Add: `test/sos_latest_alert_banner_test.dart`
- Modify: `docs/project-changelog.md`

## Implementation Steps

1. Create `test/alert_badge_test.dart` with tests for:
   - `alertBadgeCount` counts unread + unacknowledged.
   - `markAllAlertsRead()` sets all `read` to true without changing `acknowledged`.
   - `acknowledgeAlert` sets `read` to true.
2. Create `test/sos_latest_alert_banner_test.dart` with:
   - Banner hidden when alert is null.
   - Banner shows alert message and opens detail on tap.
   - Swapping alert id triggers AnimatedSwitcher child change.
3. Run `flutter test` and fix failures.
4. Run `flutter analyze` / lint if available.
5. Append a new 2026-06-17 section to `docs/project-changelog.md` describing badge and banner changes.

## Success Criteria

- All tests pass.
- No compile errors.
- Changelog updated.

## Risk Assessment

- AppState singleton may carry state from previous tests; use `setUp` with `SharedPreferences.setMockInitialValues` and fresh `AppState` instances carefully.
- Widget test for AnimatedSwitcher exit animation may require multiple pump frames.
