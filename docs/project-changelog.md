# Project Changelog

## 2026-06-13

### Added
- Chức năng xóa người thân khỏi danh sách theo dõi (chỉ dành cho quản trị viên).
  - `lib/utils/app_state.dart`: thêm `deleteElderly(int id)` — xóa người thân,
    dọn dẹp cảnh báo liên kết và active alert, lưu xuống SharedPreferences,
    thông báo cho listeners.
  - `lib/utils/localization.dart`: thêm các khóa `deleteRelative`,
    `deleteRelativeConfirm`, `deleteRelativeSuccess`, `delete` cho tiếng Việt
    và tiếng Anh.
  - `lib/widgets/delete_relative_confirmation_dialog.dart`: hộp thoại xác nhận
    xóa với nút Cancel/Delete và SnackBar thông báo kết quả.
  - `lib/widgets/elderly_list_card.dart`: **gỡ** biểu tượng `⋮`
    (PopupMenuButton) — tính năng xóa không còn ở Home.
  - `lib/widgets/relative_reorderable_list.dart` và
    `lib/screens/home_screen.dart`: **gỡ** truyền cờ `isAdmin` xuống card.
  - `lib/screens/login_screen.dart`: cập nhật `UserProfile.role` thành
    `Quản trị viên` khi đăng nhập bằng tài khoản `admin`.
  - `lib/widgets/manage_relatives_section.dart` (file mới): tách section
    "Quản lý người thân" từ `SettingsScreen`, thêm popup menu xóa cho mỗi
    người thân (chỉ admin) và nút thêm người thân.
  - `lib/widgets/relative_reorderable_list.dart`: hiển thị empty-state khi
    danh sách người thân trống, gồm icon, hướng dẫn và nút "Thêm người thân
    đầu tiên".
  - `lib/utils/localization.dart`: bổ sung thêm các khóa `noRelatives`,
    `noRelativesHint`, `addFirstRelative`, `deleteRelativeFailed` cho tiếng
    Việt và tiếng Anh.
  - `lib/utils/role_utils.dart` (file mới): helper `RoleUtils.isAdmin()` dùng
    chung cho `HomeScreen` và `SettingsScreen`.
  - `lib/widgets/developer_tools_section.dart` (file mới): tách section
    "Developer Tools" từ `SettingsScreen`, giúp màn hình này dưới 200 dòng.
  - `lib/widgets/delete_relative_confirmation_dialog.dart`: chuyển sang
    `StatefulWidget`, thêm cờ `_isDeleting` để ngăn double-tap, dùng
    `barrierDismissible: false` và `PopScope` để không đóng dialog trong lúc
    đang xóa, dùng key `deleteRelativeFailed` cho thông báo lỗi.
  - `lib/utils/app_state.dart`: trong `deleteElderly`, nếu lưu thất bại thì
    khôi phục lại người thân, cảnh báo và active alert đã xóa.
  - `lib/utils/localization.dart`: thêm khóa `fillAllFields` cho màn hình đăng
    nhập.
  - `lib/screens/login_screen.dart`: dùng key `fillAllFields` thay vì hardcode.
  - `test/relatives_reorder_test.dart`: 4 unit test cho `deleteElderly`.

### Fixed
- Sửa lỗi không thể kéo thả sắp xếp người thân trên HomeScreen.
  - `lib/widgets/relative_reorderable_list.dart`: dùng `ReorderableListView.builder`,
    tắt `buildDefaultDragHandles`. Toàn bộ card là vùng kéo thả:
    - **Mobile**: bọc card trong `ReorderableDelayedDragStartListener`, nhấn giữ
      ~300-500ms bất kỳ đâu trên thẻ để bắt đầu kéo thả.
    - **Desktop/Web**: bọc card trong `ReorderableDragStartListener`, nhấn và
      kéo card để sắp xếp lại.
    - Không hiển thị biểu tượng drag handle (=).
  - `lib/widgets/elderly_list_card.dart`: gỡ drag handle tùy chỉnh cũ, gỡ callback
    `onLocateTap` không dùng, thay `InkWell` bằng `GestureDetector` với
    `HitTestBehavior.translucent` để tap mở detail không cạnh tranh gesture
    nhấn giữ của listener cha.
  - `lib/screens/home_screen.dart`: bỏ state `_selectedElderlyId` và callback
    `onLocateTap` không còn dùng, dùng hằng `_defaultSelectedElderlyId`.
  - Cập nhật title section dùng `Localization.translate('relativeList')` thay vì
    hardcode tiếng Việt.
  - Cập nhật plan ghi nhận độ lệch so với thiết kế ban đầu.

### Tests
- `test/relatives_reorder_test.dart`: 3 unit test cho `AppState.reorderRelatives`
  pass; widget test đã gỡ bỏ do `AppState` dùng real async trong widget test
  (FakeAsync).
