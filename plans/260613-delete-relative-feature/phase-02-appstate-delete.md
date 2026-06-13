# Phase 02: AppState Delete Method

## Priority
P2

## Status
completed

## Context

Add the business-logic method that deletes a relative by id, removes linked alert state, persists the new list, and notifies listeners.

## Requirements

### Functional

1. `AppState.deleteElderly(int id)` removes the relative matching `id` from `_relatives`.
2. Any alert in `_alerts` whose `elderlyId` equals the removed id is removed.
3. If `_activeAlert?.elderlyId == id`, clear `_activeAlert`.
4. Persist updated `_relatives` to SharedPreferences under `offline_elderly_v2`.
5. Call `notifyListeners()`.
6. Return `true` if an item was removed, `false` if id not found.

### Non-functional

- Keep method under ~30 lines for readability.
- Use existing `_saveElderlyData()` to avoid duplicating persistence logic.
- Log/print deletion for debug parity with existing methods.

## Implementation Steps

1. Open `lib/utils/app_state.dart`.
2. After `updateElderly` at `lib/utils/app_state.dart:244`, add `deleteElderly(int id)`:
   - Find index by `id`.
   - If not found, return `false`.
   - Remove from `_relatives`.
   - Remove linked alerts: `_alerts.removeWhere((a) => a.elderlyId == id)`.
   - Clear active alert if linked: `if (_activeAlert?.elderlyId == id) _activeAlert = null`.
   - Call `_saveElderlyData()` and `notifyListeners()`.
   - Return `true`.
3. Make persistence async-safe with `.catchError` debug print if needed.

## Related Code Files

- Modify: `lib/utils/app_state.dart`
- Read for context: `lib/models/elderly_model.dart`, `lib/models/alert_model.dart`

## TODO

- [ ] Add `deleteElderly(int id)` method.
- [ ] Add linked alert cleanup.
- [ ] Add active alert cleanup.
- [ ] Ensure persistence and notification.
- [ ] Verify no file exceeds 200 lines after edit.

## Success Criteria

- `deleteElderly` exists and returns correct boolean.
- Deleted relative no longer appears in `AppState().relatives`.
- Linked alerts are removed in memory.
- `SharedPreferences` key `offline_elderly_v2` reflects the removal.

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Active alert cleared but UI still auto-pushes detail | Low | High | Clear `_activeAlert` before `notifyListeners`; `HomeScreen` checks `activeAlert != null` at `lib/screens/home_screen.dart:35` |
| Concurrent simulation mutates same list | Low | Medium | Method mutates `_relatives` list reference already used by simulation; safe because Flutter main thread is single-threaded |
| Persist fails silently | Low | High | Use existing `_saveElderlyData()` which awaits; wrap in catchError and log |

## Backwards Compatibility

- New method is additive; no schema or persistence format change.
- Existing elderly JSON remains unchanged for remaining items.
