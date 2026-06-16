# Phase 06 — Documentation Update & Code Review

## Context Links

- `docs/project-changelog.md`
- `docs/note-code-chi-tiet.md`
- `.claude/agents/code-reviewer.md`
- `.claude/agents/docs-manager.md`

## Overview

Update project documentation with the new integration and run a code review before marking the task complete.

## Key Insights

- Existing changelog entries are written in Vietnamese; the new entry should follow the same style.
- `note-code-chi-tiet.md` explains important code sections line by line; add a short section describing the new Socket.IO / notification services.
- Code review must verify no file exceeds the recommended 200-line limit where avoidable and that error handling covers malformed payloads.

## Requirements

- Functional: docs accurately describe the integration.
- Non-functional: no `.claude` files are modified; review comments are addressed.

## Architecture

- `docs-manager` agent appends a new changelog entry.
- `code-reviewer` agent inspects all new / modified source files.

## Related Code Files

- Modify: `docs/project-changelog.md`, optionally `docs/note-code-chi-tiet.md`.
- Review: `lib/services/socket_io_service.dart`, `lib/services/device_event_service.dart`, `lib/services/notification_service.dart`, `lib/utils/app_state.dart`, `lib/main.dart`, `pubspec.yaml`, `android/app/src/main/AndroidManifest.xml`, `android/app/build.gradle.kts`, `ios/Runner/AppDelegate.swift`.

## Implementation Steps

1. `docs-manager` agent reads `docs/project-changelog.md` and appends a new entry dated 2026-06-16:
   - Added packages `socket_io_client` and `flutter_local_notifications`.
   - New files: `lib/services/socket_io_service.dart`, `lib/services/device_event_service.dart`, `lib/services/notification_service.dart`.
   - Integration logic: mapping `ELDERLY-001` → `ElderlyModel.id == 1`, temp-elderly fallback, stopping local simulation on real data.
   - Platform config changes in Android manifest and iOS `AppDelegate.swift`.
2. Update `docs/note-code-chi-tiet.md` with a new section covering:
   - How `DeviceEventService` connects to `localhost:8080` / `10.0.2.2:8080`.
   - How events are parsed and forwarded to `AppState`.
   - How `NotificationService` shows high-importance alerts.
3. `code-reviewer` agent checks:
   - Socket.IO options and reconnection handling.
   - Safe parsing helpers and null checks.
   - Elderly mapping logic and temporary-relative creation.
   - `main.dart` initialization order.
   - Platform-specific host resolution.
   - File sizes stay under 200 lines (new files; accept that `AppState` is already larger and only small additions are made).
4. Address review feedback and re-run `flutter test` / `flutter build apk --debug`.

## TODO

- [ ] Update `docs/project-changelog.md`.
- [ ] Update `docs/note-code-chi-tiet.md` with Socket.IO / notification explanation.
- [ ] Run `code-reviewer` agent on all changed files.
- [ ] Fix any blockers and re-run tests.

## Success Criteria

- Changelog entry is complete and formatted consistently with previous entries.
- Code reviewer reports no blockers.
- All tests still pass after review fixes.

## Risk Assessment

- Review may request splitting `AppState` further because it already exceeds 200 lines. Evaluate cost / benefit before performing a large refactor; the immediate integration should keep additions minimal.

## Security Considerations

- Ensure no credentials, internal IP addresses, or notification GUIDs are committed in documentation.

## Next Steps

- Hand off to implementation team or proceed with the `cook` skill to execute the plan.
