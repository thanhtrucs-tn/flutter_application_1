# Phase 01: Research and Scope

## Priority
P2

## Status
pending

## Context

This phase reads the existing code paths that the delete feature will touch, confirms data flows, and identifies constraints before any edits.

## Key Findings

### Data Flow

1. `HomeScreen` reads `AppState().relatives` via `AnimatedBuilder` at `lib/screens/home_screen.dart:24-29`.
2. `RelativeReorderableList` builds `ElderlyListCard` for each relative at `lib/widgets/relative_reorderable_list.dart:80-89`.
3. `ElderlyListCard` renders card content and, on desktop, a drag handle at `lib/widgets/elderly_list_card.dart:35-83`.
4. `AppState` persists relatives under key `offline_elderly_v2` at `lib/utils/app_state.dart:160`.

### Role Model

- `UserProfile.role` stored at `lib/models/user_profile.dart:15`.
- Default role is `Tài khoản giám sát` (`lib/models/user_profile.dart:57`).
- Admin role contains case-insensitive substrings `"admin"` or `"Quản trị viên"`.

### Existing Patterns

- `AlertDialog` usage: `lib/widgets/add_relative_dialog.dart:158`.
- `Localization.translate` usage: `lib/utils/localization.dart:191`.
- `SnackBar` feedback: `lib/widgets/add_relative_dialog.dart:145-153`.
- SharedPreferences save: `lib/utils/app_state.dart:202-206`.
- List mutation + notify pattern: `lib/utils/app_state.dart:215-227`.

### Files to Modify / Create

**Modify:**
- `lib/utils/app_state.dart` — add `deleteElderly`.
- `lib/utils/localization.dart` — add delete-related keys.
- `lib/widgets/elderly_list_card.dart` — add admin-only popup menu.
- `lib/widgets/relative_reorderable_list.dart` — pass admin flag and wire delete callback.
- `lib/screens/home_screen.dart` — provide admin state to list (or read inside list).
- `test/relatives_reorder_test.dart` — add delete unit tests.
- `docs/project-changelog.md` — record change.

**Create:**
- `lib/widgets/delete_relative_confirmation_dialog.dart` — reusable confirmation dialog.

### TODO

- [x] Read `README.md`.
- [x] Read `AppState`, `RelativeReorderableList`, `ElderlyListCard`, `ElderlyCardContent`.
- [x] Read `localization.dart`, `user_profile.dart`, `home_screen.dart`, existing test file, and changelog.
- [x] Confirm role detection rule and localization pattern.
- [ ] Document any unresolved ambiguity before Phase 02 starts.

## Success Criteria

- Every touched file is identified with line citations.
- Data flow from UI tap → AppState → SharedPreferences is traceable.
- Admin-only rule is explicit.

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Missing edge case around active alert cleanup | Medium | High | Phase 02 explicitly clears linked `_alerts` and `_activeAlert` |
| Gesture conflict with drag and popup icon | Medium | Medium | Phase 03 tests mobile/desktop layouts with popup icon outside drag area |
