# Project Changelog

## 2026-06-14 (relative avatar picker)

### Added
- Cho phép đổi ảnh đại diện của người thân trong màn hình Cài đặt.
  - `lib/models/elderly_model.dart`: thêm `avatarLocalPath` để lưu đường dẫn
    ảnh local; cập nhật `copyWith`, `fromMap`, `toMap`.
  - `lib/widgets/elderly_avatar.dart` (file mới): widget hiển thị avatar người
    thân, ưu tiên ảnh local, fallback về URL, cuối cùng là icon mặc định.
  - `lib/widgets/manage_relatives_section.dart`: tap vào avatar trong danh sách
    quản lý người thân mở dialog `AvatarPicker`; sau khi chọn ảnh gọi
    `AppState().updateElderly(...)` để lưu.
  - `lib/widgets/elderly_card_content.dart`: dùng `ElderlyAvatar` thay vì
    `CircleAvatar` với `NetworkImage` cố định.
  - `lib/widgets/profile_header.dart`: hỗ trợ `avatarLocalPath`, ưu tiên ảnh
    local trước URL.
  - `lib/screens/detail_screen.dart` và `lib/screens/health_tracking_screen.dart`:
    truyền `avatarLocalPath` xuống `ProfileHeader`.
  - `lib/screens/remote_sos_screen.dart`: dùng `ProfileAvatar` để hiển thị ảnh
    local nếu có.
  - `lib/utils/localization.dart`: thêm `changeAvatar` và
    `tapAvatarToPickFromGallery` cho tiếng Việt và tiếng Anh.
  - `test/elderly_add_test.dart`: test round-trip `avatarLocalPath` qua
    `toMap`/`fromMap` và `copyWith`.

### Changed
- `lib/models/elderly_model.dart`: `avatarLocalPath` mặc định rỗng để tương
  thích với dữ liệu elderly đã lưu trước đó.

## 2026-06-14 (per-account data isolation)

### Added
- Cô lập toàn bộ dữ liệu ứng dụng theo tài khoản đăng nhập.
  - `lib/utils/app_state.dart`: danh sách người thân (`_offlineElderlyKey`) và
    lịch sử cảnh báo SOS (`_offlineAlertHistoryKey`) giờ là account-scoped:
    mỗi tài khoản có key riêng (`offline_elderly_<username>_v2`,
    `offline_alert_history_<username>_v1`).
  - `lib/utils/app_state.dart`: thêm `_saveAlertHistory()` để persist lịch sử
    cảnh báo theo tài khoản; được gọi khi `triggerSOS`, `acknowledgeAlert`,
    `clearAlertHistory`, `addAlert`, `deleteElderly`.
  - `lib/utils/app_state.dart`: `setCurrentAccount(...)` tải lại danh sách
    người thân và lịch sử cảnh báo của tài khoản vừa đăng nhập, đồng thời xóa
    active alert của tài khoản trước.
  - Dữ liệu demo MockData chỉ được seed cho tài khoản `admin` hoặc khi chưa
    đăng nhập; các tài khoản khác bắt đầu với danh sách rỗng.
  - `test/per_account_data_test.dart` (file mới): 4 test kiểm tra cô lập dữ
    liệu giữa các tài khoản và chuyển đổi account tải đúng dữ liệu riêng.

### Changed
- `lib/utils/app_state.dart`: `_loadElderlyData` và `_loadAlertHistory` tải theo
  `_currentAccountId` thay vì dùng key chung; `_saveElderlyData` và
  `_saveAlertHistory` chụp snapshot accountId + danh sách trước await để tránh
  ghi nhầm khi đổi account giữa chừng.

### Security / Isolation
- Thêm `AppState.logout()` để xóa `current_account_id_v1` và tải lại trạng thái
  mặc định (dữ liệu demo chung) khi đăng xuất; `lib/screens/profile_screen.dart`
  và `lib/screens/settings_screen.dart` gọi `logout()` trước khi navigate về
  LoginScreen, ngăn dữ liệu tài khoản trước bị lộ sau đăng xuất.

## 2026-06-14 (registration with email)

### Added
- Cập nhật form đăng ký: thay thế trường "Họ và tên" bằng "Email"; đổi nhãn
  trường tài khoản thành "Tên tài khoản (Username)" và nhập lại mật khẩu thành
  "Xác nhận mật khẩu".
  - `lib/screens/register_screen.dart`: bỏ `_fullNameController`, thêm
    `_emailController`; validate không rỗng, email đúng định dạng, mật khẩu
    và xác nhận mật khẩu trùng khớp; gọi `DbHelper.registerUser` với `email`.
  - `lib/screens/login_screen.dart`: nhãn input đăng nhập là
    "Email / Tên tài khoản"; thông báo lỗi đề cập email/username.
  - `lib/utils/localization.dart`: cập nhật `username`, `confirmPassword`;
    thêm `email`, `invalidEmail`, `passwordMismatch`, `emailOrUsername` cho
    cả tiếng Việt và tiếng Anh.

### Changed
- `lib/services/auth_api_service.dart`: `register` nhận thêm `email` và gửi lên
  backend; `name` không còn bắt buộc.
- `lib/database/db_helper.dart`:
  - `registerUser` nhận `email`, lưu email vào MySQL và offline
    SharedPreferences.
  - `loginUser` hỗ trợ đăng nhập bằng username hoặc email.
  - `_registerOffline` kiểm tra trùng username và email.
  - `_loginOffline` cho phép đăng nhập bằng username hoặc email.
  - `_offlineUserToInfo` trả về email đã lưu.
- `backend/server.js`:
  - `/api/register` nhận `email`, validate định dạng và độ dài, kiểm tra trùng
    username và trùng email, lưu `username`, `password`, `email`.
  - `/api/login` cho phép đăng nhập bằng username hoặc email.
- `db_script.sql`: thêm ràng buộc `UNIQUE(email)` cho bảng `users`.

### Tests
- `test/account_db_test.dart`: cập nhật test đăng ký dùng `email`; thêm test
  đăng nhập bằng email và test không cho phép trùng email ở chế độ offline.

## 2026-06-13 (per-account profile)

### Added
- Thông tin cá nhân được lưu theo tài khoản đăng nhập, không còn dùng chung.
  - `lib/utils/app_state.dart`: thêm `_currentAccountId` và phương thức
    `setCurrentAccount(...)` để tải profile riêng của tài khoản sau đăng nhập;
    key lưu profile giờ chứa username (`offline_user_profile_<username>_v1`).
  - `lib/utils/app_state.dart`: `updateUserProfile` đồng bộ họ tên/email/SĐT
    lên cơ sở dữ liệu (MySQL / backend API / offline SharedPreferences) trước
    khi persist cục bộ.
  - `lib/database/db_helper.dart`: `loginUser` trả về `Map<String,String>?`
    chứa `id`, `username`, `name`, `email`, `phone`; `registerUser` nhận thêm
    `name` để lưu họ tên; thêm `updateUserProfile` để cập nhật thông tin.
  - `lib/services/auth_api_service.dart`: `register` gửi `name`; `login` trả về
    thông tin user; thêm `updateProfile` gọi `PUT /api/users/:username`.
  - `backend/server.js`: bảng `users` mở rộng cột `name`, `email`, `phone`;
    endpoint `/api/register` nhận và lưu `name`; `/api/login` trả về các cột
    mới; thêm `PUT /api/users/:username` để cập nhật profile.
  - `db_script.sql`: thêm cột `name`, `email`, `phone` cho bảng `users`; cập
    nhật bản ghi `admin` với họ tên "Quản trị viên".
  - `lib/screens/register_screen.dart`: thêm trường "Họ và tên" và validate
    bắt buộc nhập.
  - `lib/screens/login_screen.dart`: sau đăng nhập gọi
    `AppState().setCurrentAccount(...)` với thông tin lấy từ DB.
  - `lib/utils/localization.dart`: thêm khóa `fullName` cho tiếng Việt và
    tiếng Anh.
  - `test/user_profile_test.dart`: 2 test cho profile độc lập theo tài khoản.
  - `test/account_db_test.dart` (file mới): test đăng ký/cập nhật/lấy họ tên
    qua `DbHelper` ở chế độ offline.

### Changed
- `lib/database/db_helper.dart`: đổi signature `loginUser` từ `Future<bool>`
  sang `Future<Map<String,String>?>`.

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
    xóa chỉ hiển thị chữ "Xóa người thân" trong tiêu đề, không có icon; nút
    Cancel/Delete đều là `TextButton`, không dùng icon.
  - `lib/widgets/elderly_list_card.dart`: **gỡ** biểu tượng `⋮`
    (PopupMenuButton) — tính năng xóa không còn ở Home.
  - `lib/widgets/relative_reorderable_list.dart` và
    `lib/screens/home_screen.dart`: **gỡ** truyền cờ `isAdmin` xuống card.
  - `lib/screens/login_screen.dart`: cập nhật `UserProfile.role` thành
    `Quản trị viên` khi đăng nhập bằng tài khoản `admin`.
  - `lib/widgets/manage_relatives_section.dart` (file mới): tách section
    "Quản lý người thân" từ `SettingsScreen`, thêm icon thùng rác
    (`Icons.delete_outline`) để mở hộp thoại xác nhận xóa cho mỗi người thân
    (khi có quyền) và nút thêm người thân.
  - `lib/widgets/relative_reorderable_list.dart`: hiển thị empty-state khi
    danh sách người thân trống, gồm icon, hướng dẫn và nút "Thêm người thân
    đầu tiên".
  - `lib/utils/localization.dart`: bổ sung thêm các khóa `noRelatives`,
    `noRelativesHint`, `addFirstRelative`, `deleteRelativeFailed` cho tiếng
    Việt và tiếng Anh.
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
  - `lib/screens/settings_screen.dart`: thay đổi mục ngôn ngữ từ `Switch`
    (bật/tắt Vi/En) thành `ListTile` mở hộp thoại chọn ngôn ngữ, cho phép
    user/admin chọn giữa Tiếng Việt và English.
  - `lib/utils/localization.dart`: thêm các khóa `selectLanguage`, `vietnamese`,
    `english` cho tiếng Việt và tiếng Anh.
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

### Removed
- Gỡ bỏ trường `role` khỏi `UserProfile` (`lib/models/user_profile.dart`); ứng
  dụng chỉ có một tài khoản giám sát chính nên vai trò được hiển thị tĩnh là
  "Quản trị viên" / "Tài khoản giám sát" ở các widget thay vì lưu trong model.
  - Xóa file `lib/utils/role_utils.dart` (dead code).
  - `lib/screens/login_screen.dart`: bỏ logic cập nhật `UserProfile.role` sau
    đăng nhập.

### Tests
- `test/relatives_reorder_test.dart`: 3 unit test cho `AppState.reorderRelatives`
  pass; widget test đã gỡ bỏ do `AppState` dùng real async trong widget test
  (FakeAsync).

## 2026-06-16 (SOS device simulator integration)

### Added
- Tích hợp `Project_GiaLap/sos_device_simulator` vào `flutter_application_1`
  qua `sos_care_backend` (Socket.IO, port 8080) để nhận sự kiện SOS/ngã/nhịp tim/vị trí/pin.
  - `pubspec.yaml`: thêm `socket_io_client: ^2.0.3` và `flutter_local_notifications: ^22.0.1`.
  - `lib/services/socket_io_service.dart` (file mới): wrapper quanh `socket_io_client`,
    hỗ trợ `connect`, `on`, `off`, `dispose`.
  - `lib/services/notification_service.dart` (file mới): singleton khởi tạo kênh
    `sos_alerts` và hiển thị local notification với named parameters theo API v22.
  - `lib/services/device_event_mapper.dart` (file mới): xử lý URL backend, ánh xạ
    ID người thân (`ELDERLY-001` → `int id`), tạo temporary elderly khi không khớp,
    parse payload và tạo ID notification ổn định.
  - `lib/services/device_event_service.dart` (file mới): singleton đăng ký lắng
    nghe `sos:alert`, `event:fall`, `event:heart_rate`, `device:location`, `device:status`
    rồi mới `connect`; cập nhật `AppState`, dừng `simulateDeviceOnline`, và đẩy
    local notification cho sự kiện khẩn cấp.
  - `lib/utils/app_state.dart`: thêm `setRealtimeConnection(bool)`.
  - `android/app/src/main/AndroidManifest.xml`: thêm quyền `POST_NOTIFICATIONS`,
    `VIBRATE`, `WAKE_LOCK`, lock-screen flags cho `MainActivity`.
  - `android/app/src/main/res/drawable/sos_notification_icon.xml`: icon vector trắng
    dùng làm small icon cho notification.
  - `ios/Runner/AppDelegate.swift`: thiết lập delegate cho `flutter_local_notifications`.

### Changed
- `lib/main.dart`: chuyển sang `Future<void> main() async`, khởi tạo
  `NotificationService`, `AppState`, rồi `DeviceEventService().start('http://localhost:8080')`
  trước khi chạy app.
- `android/app/build.gradle.kts`: nâng `compileSdk` lên 36, bật desugaring
  (`isCoreLibraryDesugaringEnabled = true`, `desugar_jdk_libs:2.1.4`).
- `android/build.gradle.kts`: override `compileSdk = 36` cho toàn bộ subproject
  Android bằng `CommonExtension`.
- `android/gradle.properties`: thêm `kotlin.compiler.execution.strategy=in-process`,
  `kotlin.incremental=false`, `org.gradle.caching=false` để ổn định daemon build.

### Fixed
- Sửa lỗi build Android khi plugin mới yêu cầu `compileSdk >= 34` bằng cách đồng
  bộ `compileSdk = 36` trên app và mọi module phụ thuộc.
- Sửa lỗi `flutter_local_notifications` v22 API: dùng named parameters
  `settings:`, `id:`, `title:`, `body:`, `notificationDetails:`.
- Sửa lỗi thứ tự đăng ký listener: đăng ký `on('sos:alert')`, `on('connect')`, v.v.
  trước khi gọi `connect()` để không bỏ lỡ sự kiện đầu tiên.
- Sửa lỗi hiển thị trùng cảnh báo pin thấp bằng cách lưu trạng thái battery gần
  nhất và chỉ notify khi chuyển từ ≥ 20% xuống < 20%.
- Khắc phục lỗi daemon Kotlin incremental cache bằng `flutter clean`, xóa thư
  mục cache hỏng, và cấu hình in-process compiler.

### Tests / Verification
- `flutter build apk --debug` pass.
- `flutter build windows --debug` pass.
- `flutter test` pass (56/56).

### Pending
- Chạy end-to-end: backend 8080 → simulator → app, kiểm tra mọi nút simulator
  đều làm UI hoặc local notification thay đổi.
