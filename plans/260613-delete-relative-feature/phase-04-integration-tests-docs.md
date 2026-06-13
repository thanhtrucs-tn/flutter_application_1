# Phase 04: Integration, Tests, and Documentation

## Priority
P2

## Status
completed

## Context

Wire the feature end-to-end, write unit tests, run the test/lint pipeline, and update the changelog.

## Requirements

### Functional

1. Home screen passes admin flag to the reorderable list.
2. List passes admin flag to each card.
3. Card popup triggers confirmation dialog.
4. Confirmation calls `AppState.deleteElderly`.
5. AppState cleans linked alerts and persists.

### Tests

1. Add tests in `test/relatives_reorder_test.dart`:
   - `deleteElderly removes relative by id`.
   - `deleteElderly removes linked alerts`.
   - `deleteElderly clears active alert if linked`.
   - `deleteElderly persists updated list`.
   - `deleteElderly returns false for unknown id`.
2. If widget testing becomes feasible without FakeAsync issues, add a widget test for the confirmation dialog; otherwise rely on unit tests and manual verification.

### Documentation

- Update `docs/project-changelog.md` with a new `Added` entry for delete-relative feature under `2026-06-13`.

## Implementation Steps

1. Open `test/relatives_reorder_test.dart`.
2. Add a helper to build `AlertModel` instances.
3. Add tests covering in-memory and SharedPreferences behavior.
4. Run `flutter test test/relatives_reorder_test.dart`.
5. Fix any failures.
6. Run `flutter analyze` (or project lint command).
7. Update `docs/project-changelog.md`.

## Related Code Files

- Modify: `test/relatives_reorder_test.dart`, `docs/project-changelog.md`
- Read for context: `lib/models/alert_model.dart`, `lib/utils/app_state.dart`

## TODO

- [ ] Add `AlertModel` test helper.
- [ ] Add unit tests for `deleteElderly`.
- [ ] Run unit tests and fix failures.
- [ ] Run static analysis.
- [ ] Update changelog.
- [ ] Verify no compile errors.

## Success Criteria

- All tests in `test/relatives_reorder_test.dart` pass.
- `flutter analyze` reports no errors in modified files.
- Changelog documents the feature.

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Test setup conflict with `AppState` singleton simulation | Medium | High | Always call `state.stopSimulation()` and clear `SharedPreferences` mock in `setUp` as existing tests do |
| FakeAsync issues when adding widget tests | Medium | Medium | Avoid widget tests if prior tests removed them; document rationale |
| Compile error from new localization keys | Low | Medium | Use `Localization.translate('key')` exactly as added to both maps |

## Rollback

- Revert test file changes and changelog entry.
- Remove Phase 03 UI wiring.
- `AppState.deleteElderly` can remain as dead code or be removed.
