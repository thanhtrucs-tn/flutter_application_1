# Phase 03: Popup Menu and Confirmation Dialog

## Priority
P2

## Status
completed

## Context

Add an admin-only popup menu on each relative card and a reusable confirmation dialog for delete action.

## Requirements

### Functional

1. `ElderlyListCard` displays a `PopupMenuButton` (vertical "⋮" icon) only when the current user is admin.
2. Menu contains a single visible item: `Xóa người thân` / `Delete relative`.
3. Tapping it opens a confirmation `AlertDialog` with message:
   - vi: `Bạn có chắc chắn muốn xóa người thân này khỏi danh sách?`
   - en: `Are you sure you want to remove this relative from the list?`
4. Dialog has `Cancel` and `Confirm` (or `Delete`) actions.
5. On confirm, call `AppState().deleteElderly(elderly.id)` and show a `SnackBar`.
6. On cancel, close dialog and do nothing.

### Non-functional

- Keep `ElderlyListCard` under 200 lines; extract dialog to a new file if needed.
- Use existing localization and snackbar patterns.
- Avoid gesture conflicts on mobile: popup icon must not trigger card tap or drag.

## Localization Keys

Add to `lib/utils/localization.dart`:

| Key | vi | en |
|---|---|---|
| `deleteRelative` | `Xóa người thân` | `Delete relative` |
| `deleteRelativeConfirm` | `Bạn có chắc chắn muốn xóa người thân này khỏi danh sách?` | `Are you sure you want to remove this relative from the list?` |
| `deleteRelativeSuccess` | `Đã xóa người thân` | `Relative removed` |
| `delete` | `Xóa` | `Delete` |

If `delete` already exists, reuse it; otherwise add it.

## Implementation Steps

1. Add keys to `lib/utils/localization.dart` in both `vi` and `en` maps.
2. Create `lib/widgets/delete_relative_confirmation_dialog.dart`:
   - Stateless widget `DeleteRelativeConfirmationDialog`.
   - Required parameter `ElderlyModel elderly`.
   - `AlertDialog` title = `deleteRelative`, content = `deleteRelativeConfirm`.
   - Actions: `TextButton` cancel, `ElevatedButton` delete with red color.
   - On delete: call `AppState().deleteElderly(elderly.id)`, then `Navigator.pop(context, true)`.
   - Helper static method `show(BuildContext, ElderlyModel) => Future<bool>`.
3. Modify `lib/widgets/elderly_list_card.dart`:
   - Add `bool isAdmin` parameter.
   - Add a `PopupMenuButton` in the top-right of the card content only if `isAdmin`.
   - Wrap the card's inner content with a `Row` or `Stack` so the menu is positioned in the drag-handle-free area on desktop.
   - On mobile, card is already wrapped in `ReorderableDelayedDragStartListener` at `lib/widgets/relative_reorderable_list.dart:94`; menu icon must use a separate `GestureDetector` with `HitTestBehavior.deferToChild` or similar to avoid starting drag.
4. Modify `lib/widgets/relative_reorderable_list.dart`:
   - Accept `bool isAdmin` parameter.
   - Pass `isAdmin: isAdmin` to `ElderlyListCard`.
5. Modify `lib/screens/home_screen.dart`:
   - Pass `isAdmin: _isAdmin(state.userProfile.role)` to `RelativeReorderableList`.
   - Add helper `_isAdmin(String role)` checking case-insensitive `admin` or `quản trị viên`.
6. In `ElderlyListCard`, after successful delete, show `SnackBar` with `deleteRelativeSuccess` + name.

## Related Code Files

- Modify: `lib/utils/localization.dart`, `lib/widgets/elderly_list_card.dart`, `lib/widgets/relative_reorderable_list.dart`, `lib/screens/home_screen.dart`
- Create: `lib/widgets/delete_relative_confirmation_dialog.dart`
- Read for context: `lib/models/elderly_model.dart`, `lib/models/user_profile.dart`

## TODO

- [ ] Add localization keys for delete actions.
- [ ] Create `DeleteRelativeConfirmationDialog` widget.
- [ ] Add admin-only popup menu to `ElderlyListCard`.
- [ ] Wire `isAdmin` through `RelativeReorderableList` and `HomeScreen`.
- [ ] Add SnackBar feedback after deletion.
- [ ] Verify mobile drag-and-popup gesture separation.

## Success Criteria

- Only admin users see the popup menu.
- Confirmation dialog text matches localized vi/en strings.
- Confirm triggers deletion and shows SnackBar.
- Cancel leaves list unchanged.
- Card tap to detail and drag reorder still work on mobile and desktop.

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Popup icon captured by drag listener on mobile | Medium | High | Wrap icon in `GestureDetector` with `behavior: HitTestBehavior.translucent` and/or absorb pointer; test on mobile emulator |
| Desktop drag handle overlaps menu icon | Low | Medium | Keep right padding large enough: desktop already pads right by 48px for handle at `lib/widgets/elderly_list_card.dart:51`; place menu inside that padding or adjust to avoid overlap |
| File exceeds 200 lines | Low | Medium | Extract dialog to dedicated widget file |

## Rollback

- Revert `ElderlyListCard`, `RelativeReorderableList`, `HomeScreen`, and remove new dialog file.
- `AppState.deleteElderly` is harmless to keep even if UI reverted.
