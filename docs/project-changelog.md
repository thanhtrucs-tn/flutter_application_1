# Project Changelog

## 2026-06-17 (SOS Home latest banner + alert tab badge)

### Added
- Trạng thái `read` cho cảnh báo để phân biệt "chưa đọc" và "chưa xử lý".
  - `lib/models/alert_model.dart`: thêm trường `read` với giá trị mặc định
    `false`; cập nhật `copyWith`, `fromMap`, `toMap` tương thích ngược.
  - `lib/utils/app_state.dart`: thêm `alertBadgeCount` đếm cảnh báo chưa đọc
    hoặc chưa xử lý; thêm `markAllAlertsRead()` để xóa cờ `read` khi mở tab
    Thông báo; `acknowledgeAlert` tự động đánh dấu `read` luôn.
- Badge số lượng cảnh báo trên tab Thông báo ở bottom navigation.
  - `lib/widgets/sos_bottom_nav.dart`: nhận `alertBadgeCount`, bọc icon
    `notifications` trong `Badge` khi count > 0; giới hạn hiển thị tối đa `99+`.
  - `lib/screens/main_shell.dart`: truyền count xuống `SosBottomNav` và gọi
    `markAllAlertsRead()` khi chuyển sang tab Thông báo (index 1).
- Banner SOS mới nhất trên trang chủ, thay thế danh sách 5 thông báo cũ.
  - `lib/widgets/sos_latest_alert_banner.dart` (file mới): hiển thị tối đa 1
    cảnh báo chưa xử lý mới nhất; dùng `AnimatedSwitcher` để banner cũ trượt
    xuống biến mất và banner mới thay thế khi có cảnh báo mới.
  - `lib/widgets/relative_reorderable_list.dart`: thay `SosNotificationList`
    bằng `SosLatestAlertBanner`.

### Removed
- Xóa file `lib/widgets/sos_notification_list.dart` không còn được sử dụng.

### Fixed
- Số lượng người thân ONLINE/OFFLINE ở lobby cập nhật realtime mà không cần
  chuyển tab.
  - `lib/widgets/home_user_header.dart`: bọc toàn bộ nội dung trong
    `AnimatedBuilder` lắng nghe `AppState()` trực tiếp, giúp count cập nhật ngay
    khi `ElderlyModel.isOffline` thay đổi ngay cả khi parent list reference
    không đổi.

### Tests
- `test/alert_badge_test.dart` (file mới): test `alertBadgeCount`,
  `markAllAlertsRead`, và `acknowledgeAlert` đồng thời đánh dấu `read`.
- `test/sos_latest_alert_banner_test.dart` (file mới): test banner ẩn khi
  không có cảnh báo, nhấn mở chi tiết, và thay thế alert kích hoạt animation.
- `test/home_user_header_realtime_count_test.dart` (file mới): test count
  online/offline cập nhật ngay khi thay đổi trạng thái thiết bị mà không cần
  tab switching.

## 2026-06-17 (SOS alerts sorting, auto-acknowledge fix, realtime device badge)

### Fixed
- Sửa lỗi cảnh báo té ngã tự động bị đánh dấu "ĐÃ XỬ LÝ" dù người dùng chưa động vào.
  - `lib/utils/app_state.dart`: không còn dùng `elderly.status == 'critical'` làm
    proxy cho "vừa ở ngoài vùng an toàn"; thay bằng khoảng cách GPS thực tế so
    với tâm vùng an toàn.
  - `lib/utils/app_state.dart`: chỉ tự động acknowledge khi active alert thuộc
    loại `geofence` và người thân quay về vùng an toàn. Cảnh báo `fall` và `vital`
    luôn yêu cầu xác nhận thủ công.
  - `lib/models/alert_model.dart`: thêm trường `type` (`fall` | `geofence` |
    `vital` | `manual`), cập nhật `copyWith`, `fromMap`, `toMap` với giá trị mặc
    định tương thích ngược.
  - `lib/utils/app_state.dart`: các hàm `simulateFall`, `simulateExitSafeZone`,
    `simulateHeartRateSpike` truyền đúng `type`.
  - `lib/database/mock_data.dart`: cập nhật các cảnh báo mẫu với `type` phù hợp.
  - `lib/screens/home_screen.dart`: gỡ bỏ nhánh tự động acknowledge khi user đang
    ở ngoài Home.
- Sửa lỗi compile `lib/screens/alerts_screen.dart`: di chuyển `topAlertId` ra ngoài
  danh sách `children` của `ListView`.
- `lib/utils/app_state.dart`: tự động acknowledge cảnh báo geofence khi người thân
  đã ở trong vùng an toàn ngay cả khi tọa độ trước đó (do `updateElderly`) cũng đã
  ở trong vùng — giúp realtime hơn khi GPS được cập nhật từ backend.
- `lib/utils/app_state.dart`: `acknowledgeAlert` chỉ reset `isFallen` khi xác nhận
  đúng cảnh báo `fall`, tránh xóa nhầm cờ té ngã khi một cảnh báo geofence tự
  động acknowledge.
- `lib/screens/alerts_screen.dart`: đổi tên `latestAlertId` → `topAlertId` cho đúng
  ngữ nghĩa (top của danh sách chưa-xử-lý-ưu-tiên), và thay chuỗi empty-state cứng
  bằng `Localization.translate('noAlerts')`.

### Added
- Sắp xếp danh sách cảnh báo: chưa xử lý mới nhất lên đầu, sau đó đã xử lý mới nhất.
  - `lib/utils/app_state.dart`: thêm getter `sortedAlerts`.
  - `lib/screens/alerts_screen.dart`: dùng `sortedAlerts` và truyền `isLatest`
    cho thông báo mới nhất.
- Badge thời gian chi tiết trên mỗi thông báo (`dd/mm/yyyy - hh:mm:ss`) ở góc
  phải.
  - `lib/widgets/alert_list_item.dart`: hiển thị badge thời gian, hỗ trợ `isLatest`
    để bật hiệu ứng highlight nhấp nháy chỉ đúng thông báo mới nhất.
- Danh sách thông báo SOS trên Home với animation mượt mà.
  - `lib/widgets/sos_notification_list.dart` (file mới): dùng `AnimatedList`,
    thông báo mới chèn lên đầu, thông báo cũ/cũ bị xóa trượt xuống/xóa mượt mà.
  - `lib/widgets/relative_reorderable_list.dart`: chèn `SosNotificationList` giữa
    `StatusBanner` và section "Danh sách người thân".
- Badge trạng thái thiết bị ONLINE/OFFLINE cập nhật realtime.
  - `lib/widgets/device_online_badge.dart` (file mới): chip hiển thị `ONLINE` /
    `OFFLINE` với màu xanh/xám và đèn hiệu.
  - `lib/widgets/elderly_card_content.dart`: đặt badge ngay cạnh tên người thân,
    cập nhật ngay khi `ElderlyModel.isOffline` thay đổi nhờ `AnimatedBuilder` ở
    `HomeScreen`.

### Tests
- `test/alert_sorting_and_autoack_test.dart` (file mới): test `sortedAlerts` và
  fall alert không bị auto-acknowledge.
- `test/alert_list_item_test.dart` (file mới): test badge thời gian, trạng thái
  xử lý, highlight khi `isLatest`.

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
