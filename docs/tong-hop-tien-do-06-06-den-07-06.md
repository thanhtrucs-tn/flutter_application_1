# Tổng Hợp Tiến Độ Dự Án SOS Care — Từ 06/06/2026 đến 07/06/2026

> **Mục đích:** Tài liệu này giải thích chi tiết toàn bộ những gì đã được làm trong 2 ngày qua, giúp người mới học Flutter đọc hiểu từng phần, từng file, từng dòng code ý nghĩa gì. Không giả định bạn đã biết gì nhiều — mọi khái niệm đều được giải thích.

---

## 1. Tổng Quan Dự Án

**Tên:** SOS Care — Hệ thống giám sát khẩn cấp cho người cao tuổi.

**Mô tả ngắn:** Đây là ứng dụng Flutter giúp người thân (con cháu) theo dõi sức khỏe, vị trí GPS, và nhận cảnh báo SOS khẩn cấp từ thiết bị đeo của người cao tuổi (mô phỏng ESP32).

**Kiến trúc chính:**
- **Frontend:** Flutter (Dart) — chạy trên Android, iOS, Windows, macOS, Linux, Web.
- **Database:** Hỗ trợ cả MySQL (online qua API) và Mock Data (offline khi không có server).
- **Lưu trữ local:** `SharedPreferences` — lưu cài đặt, hồ sơ người dùng, danh sách người thân.

---

## 2. Timeline Chi Tiết (06/06 → 07/06)

### Ngày 06/06/2026 — Commit 1: `update lần 5` (`bd8ec83`)

**Nội dung:** Thêm 5 màn hình chức năng điều khiển từ xa + cải tiến bản đồ.

| File/Màn hình mới | Chức năng |
|-------------------|-----------|
| `ambient_listen_screen.dart` | Nghe âm thanh xung quanh thiết bị người cao tuổi |
| `remote_sos_screen.dart` | Điều khiển nút SOS từ xa (bật/tắt) |
| `ringing_device_screen.dart` | Bật chuông/báo rung thiết bị để tìm |
| `send_sms_screen.dart` | Gửi tin nhắn khẩn cấp SMS |
| `test_scenario_screen.dart` | Màn hình test kịch bản SOS (dành cho dev/test) |

**Cải tiến:**
- `alert_detail_screen.dart`: Thêm thông tin chi tiết cảnh báo.
- `detail_screen.dart`: Chỉnh sửa layout chi tiết người cao tuổi.
- `home_screen.dart`: Thêm badge trạng thái.
- `custom_map.dart` & `full_screen_map_modal.dart`: Cải thiện hiển thị bản đồ.
- `app_state.dart`: Thêm logic mô phỏng và quản lý trạng thái.

---

### Ngày 06/06/2026 — Commit 2: `update lần 6` (`e45bffd`)

**Nội dung:** Thay đổi giao diện toàn diện (UI Redesign) + Bản đồ hoàn chỉnh.

**Các thay đổi lớn:**
1. **Tái cấu trúc giao diện:** Tách các màn hình "khổng lồ" thành nhiều widget nhỏ, dễ quản lý.
2. **Thêm 20+ widget mới:** `ElderlyListCard`, `StatusBanner`, `SosBottomNav`, `SosAppHeader`, `ActionButtonGrid`, `VitalBadge`, `MetricCard`, `FilterChipBar`, `HealthMetricsPanel`, `SafeZoneSlider`, `MapActionOverlay`, `SettingsSectionCard`, `ProfileHeader`, `AlertListItem`, `ContactListItem`.
3. **Thêm màn hình mới:**
   - `main_shell.dart` — Khung chứa 3 tab chính (Home, Alerts, Settings).
   - `map_view_screen.dart` — Xem bản đồ toàn màn hình.
   - `health_tracking_screen.dart` — Theo dõi sức khỏe chi tiết.
   - `emergency_contacts_screen.dart` — Danh bạ khẩn cấp.
   - `notification_settings_screen.dart` — Cài đặt thông báo.
   - `add_alert_screen.dart` — Thêm cảnh báo thủ công.
   - `alerts_screen.dart` — Danh sách cảnh báo có lọc.
   - `account_screen.dart` — Thông tin tài khoản (sau này bị gộp vào Settings).
4. **Bản đồ hoàn chỉnh:** Hiển thị tên địa điểm bằng chữ (geocoding), vùng an toàn hình tròn.
5. **Theme & Dark Mode:** Định nghĩa hệ thống màu sắc y tế (Teal) hỗ trợ sáng/tối.
6. **Đa ngôn ngữ:** Hỗ trợ Tiếng Việt (`vi`) và Tiếng Anh (`en`).
7. **Lập kế hoạch:** Tạo thư mục `plans/260606-ui-redesign-sos-care/` với 7 phase lập kế hoạch chi tiết.

---

### Ngày 07/06/2026 — Thay đổi chưa commit (Working Tree)

**Nội dung:** Thêm hệ thống Hồ Sơ Người Dùng (User Profile) — đây là phần mới nhất, chưa được `git commit`.

**Các thay đổi:**
1. **Xóa `account_screen.dart`** — Tài khoản cũ được gộp vào `SettingsScreen`.
2. **Thêm Model mới:** `user_profile.dart` — lưu thông tin người giám sát.
3. **Thêm màn hình mới:** `profile_screen.dart` — màn hình sửa hồ sơ cá nhân.
4. **Thêm Widget mới:**
   - `avatar_picker.dart` — Chọn ảnh đại diện từ thư viện.
   - `profile_avatar.dart` — Hiển thị avatar (ưu tiên ảnh local, fallback URL).
   - `edit_single_field_dialog.dart` — Dialog sửa 1 trường (tên/email/SĐT).
   - `user_profile_dialogs.dart` — Các hàm tiện ích mở dialog sửa + hiển thị SnackBar.
5. **Cập nhật `app_state.dart`:** Thêm quản lý `UserProfile`, lưu/đọc từ `SharedPreferences`.
6. **Cập nhật `home_screen.dart`:** Thêm `_UserHeader` hiển thị avatar + tên người giám sát ở đầu trang.
7. **Cập nhật `settings_screen.dart`:** Gộp thông tin tài khoản vào đây, thêm nút vào ProfileScreen.
8. **Dependencies mới:** `image_picker: ^1.1.2` trong `pubspec.yaml`.
9. **Test mới:** `test/user_profile_test.dart` — test đơn vị cho UserProfile.

---

## 3. Kiến Trúc Ứng Dụng (Cho Người Mới)

### 3.1. Cấu trúc thư mục chuẩn

```
lib/
├── database/           # Dữ liệu giả (Mock) + kết nối DB thật
├── models/             # Các lớp dữ liệu (ElderlyModel, AlertModel, UserProfile, AppSettings)
├── screens/            # Các màn hình full-page (Home, Detail, Login, Profile...)
├── services/           # Gọi API (AuthApiService)
├── utils/              # Công cụ dùng chung (AppState, Theme, Localization)
├── widgets/            # Các khối UI nhỏ tái sử dụng (Card, Button, Badge...)
└── main.dart           # Điểm khởi đầu ứng dụng
```

**Quy tắc đặt tên file:** Dùng `snake_case.dart` (vd: `elderly_list_card.dart`). Đây là quy ước Flutter/Dart chuẩn.

### 3.2. Luồng dữ liệu cơ bản

```
Người dùng tương tác UI (Widget)
        ↓
Gọi hàm trong AppState (ChangeNotifier)
        ↓
AppState cập nhật dữ liệu + lưu SharedPreferences
        ↓
Gọi notifyListeners() → UI tự động rebuild
```

**Giải thích cho người mới:**
- **Widget:** Mọi thứ hiển thị trên màn hình đều là Widget. Button, Text, Card, thậm chí cả AppBar đều là Widget.
- **ChangeNotifier:** Là một lớp của Flutter giúp "thông báo" cho UI biết "dữ liệu đã thay đổi, hãy vẽ lại". Tương tự như `useState` trong React nếu bạn quen JS.
- **SharedPreferences:** Là nơi lưu dữ liệu nhỏ trên điện thoại (giống `localStorage` trên web). Dữ liệu không mất khi tắt app.
- **notifyListeners():** Hàm này kêu gọi tất cả widget đang "lắng nghe" hãy vẽ lại (rebuild).

---

## 4. Các Lớp Model (Dữ Liệu)

Model là lớp định nghĩa "hình dạng" của dữ liệu. Trong Flutter, ta dùng `class` thuần (Plain Old Dart Object — POD).

### 4.1. `ElderlyModel` — Thông tin người cao tuổi

**File:** `lib/models/elderly_model.dart`

```dart
class ElderlyModel {
  final int id;
  final String name;
  final String avatar;           // URL ảnh đại diện
  final int battery;             // % pin còn lại
  final DateTime lastUpdated;    // Thời điểm cập nhật cuối
  final String status;           // 'safe' | 'warning' | 'critical'
  final double latitude;         // Vĩ độ GPS
  final double longitude;        // Kinh độ GPS
  final int heartRate;           // Nhịp tim (bpm)
  final int spo2;                // Nồng độ oxy máu (%)
  final bool isOffline;          // Thiết bị có mất kết nối không
  final String wearableDevice;   // Tên thiết bị đeo
  final bool isFallen;           // Có phát hiện té ngã không
  final double safeZoneRadius;   // Bán kính vùng an toàn (mét)
  final double safeZoneLat;      // Tâm vùng an toàn (vĩ độ)
  final double safeZoneLng;      // Tâm vùng an toàn (kinh độ)
  final List<String> emergencyContacts; // Danh sách SĐT khẩn cấp
  final String address;          // Địa chỉ dạng chữ (VD: "268 Lý Thường Kiệt")
}
```

**Tại sao dùng `final`?**
- `final` nghĩa là giá trị chỉ được gán **một lần**. Khi muốn thay đổi, ta không sửa trực tiếp mà tạo object mới. Điều này giúp Flutter nhận biết thay đổi dễ hơn.

**Phương thức quan trọng: `copyWith`**

```dart
ElderlyModel copyWith({int? battery, String? status, ...}) {
  return ElderlyModel(
    id: id ?? this.id,               // Nếu không truyền id mới → giữ id cũ
    battery: battery ?? this.battery, // Nếu truyền battery mới → dùng giá trị mới
    ...
  );
}
```

**Ý nghĩa:** `copyWith` cho phép bạn tạo một bản sao của object với **chỉ một vài trường thay đổi**, giữ nguyên tất cả trường khác. Đây là pattern cực kỳ phổ biến trong Flutter để đảm bảo dữ liệu bất biến (immutable).

**Phương thức: `fromMap` và `toMap`**
- `fromMap`: Chuyển từ JSON (Map) → Object. Dùng khi đọc từ SharedPreferences hoặc API.
- `toMap`: Chuyển từ Object → JSON (Map). Dùng khi lưu xuống.

---

### 4.2. `AlertModel` — Cảnh báo SOS

**File:** `lib/models/alert_model.dart`

```dart
class AlertModel {
  final String id;
  final int elderlyId;        // ID người cao tuổi liên quan
  final String elderlyName;
  final DateTime time;        // Thời điểm cảnh báo
  final String locationName;  // Tên địa điểm (VD: "Khu vực nhà ở")
  final String urgency;       // 'critical' (đỏ) | 'warning' (vàng)
  final String message;       // Nội dung cảnh báo
  final bool acknowledged;    // Đã xác nhận/xử lý chưa
  final double latitude;
  final double longitude;
}
```

**Ý nghĩa:** Mỗi lần có sự cố (té ngã, ra khỏi vùng an toàn, nhịp tim bất thường), hệ thống tạo một `AlertModel` và thêm vào danh sách lịch sử.

---

### 4.3. `UserProfile` — Hồ sơ người giám sát (MỚI)

**File:** `lib/models/user_profile.dart`

```dart
class UserProfile {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String avatarUrl;        // Ảnh từ internet
  final String avatarLocalPath;  // Ảnh từ thư viện điện thoại (ưu tiên)
  final String role;             // VD: "Tài khoản giám sát"
}
```

**Logic ưu tiên avatar:**
1. Nếu `avatarLocalPath` có giá trị và file tồn tại → Hiển thị ảnh local.
2. Nếu không → Hiển thị ảnh từ `avatarUrl`.
3. Nếu cả hai đều rỗng → Hiển thị icon người mặc định.

---

### 4.4. `AppSettings` — Cài đặt ứng dụng

**File:** `lib/models/app_settings.dart`

```dart
class AppSettings {
  final bool isDarkMode;
  final String languageCode;      // 'vi' hoặc 'en'
  final bool isSoundAlertEnabled;
  final bool isAutoCallEnabled;
  final int autoCallTimeoutSeconds;
}
```

---

## 5. Quản Lý Trạng Thái Toàn Cục — `AppState`

**File:** `lib/utils/app_state.dart`

Đây là **trái tim** của ứng dụng. Nó quản lý tất cả dữ liệu dùng chung cho mọi màn hình.

### 5.1. Singleton Pattern — Tại sao chỉ có 1 instance?

```dart
class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal() { ... }
}
```

**Giải thích cho người mới:**
- **Singleton** nghĩa là "đơn thể". Dù bạn gọi `AppState()` ở đâu, bao nhiêu lần, bạn luôn nhận được **cùng một object duy nhất**.
- Tại sao cần? Để đảm bảo dữ liệu ở màn hình A và màn hình B là **như nhau**. Nếu không dùng Singleton, mỗi lần `AppState()` sẽ tạo object mới → mất dữ liệu.
- `_internal()` là constructor riêng (private), chỉ được gọi một lần duy nhất khi khởi tạo `_instance`.

### 5.2. Dữ liệu lưu trữ trong AppState

```dart
List<ElderlyModel> _relatives = [];    // Danh sách người cao tuổi đang giám sát
List<AlertModel> _alerts = [];          // Lịch sử cảnh báo
AppSettings _settings = ...;           // Cài đặt
UserProfile _userProfile = ...;        // Hồ sơ người dùng (MỚI)
AlertModel? _activeAlert;              // Cảnh báo đang diễn ra (khẩn cấp)
bool _isWebSocketConnected = true;      // Trạng thái kết nối mô phỏng
Timer? _simulationTimer;               // Bộ đếm giờ mô phỏng realtime
int _currentNavIndex = 0;              // Tab đang chọn (0=Home, 1=Alerts, 2=Settings)
```

### 5.3. Getter — Cách đọc dữ liệu an toàn

```dart
List<ElderlyModel> get relatives => _relatives;
```

**Ý nghĩa:** Các màn hình không truy cập trực tiếp `_relatives` (có dấu `_` nghĩa là private — riêng tư). Chỉ được đọc qua `relatives`. Điều này bảo vệ dữ liệu khỏi bị sửa lung tung từ bên ngoài.

### 5.4. Các hành động chính

#### Quản lý cài đặt
```dart
Future<void> updateSettings(AppSettings newSettings) async {
  _settings = newSettings;
  Localization.currentLanguage = _settings.languageCode;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('app_settings', json.encode(_settings.toMap()));
  notifyListeners();  // ← Báo cho UI: dữ liệu thay đổi, vẽ lại đi!
}
```

**Giải thích:**
- `json.encode(...)`: Chuyển object thành chuỗi JSON để lưu.
- `notifyListeners()`: Gọi sau khi sửa dữ liệu. Nếu quên gọi, UI sẽ không cập nhật.

#### Toggle Dark Mode / Ngôn ngữ
```dart
Future<void> toggleDarkMode(bool enabled) async {
  await updateSettings(_settings.copyWith(isDarkMode: enabled));
}

Future<void> toggleLanguage(String langCode) async {
  await updateSettings(_settings.copyWith(languageCode: langCode));
}
```

#### Quản lý UserProfile (MỚI)

```dart
Future<bool> updateUserProfile(UserProfile updated) async {
  // Validate trước khi lưu
  if (updated.name.trim().isEmpty) return false;
  if (!RegExp(r'^[0-9]{10}$').hasMatch(updated.phone.trim())) return false;
  
  _userProfile = updated;
  await _saveUserProfile();  // Lưu xuống SharedPreferences
  notifyListeners();
  return true;
}

Future<bool> updateUserAvatarLocalPath(String path) async {
  if (path.isEmpty) return false;
  _userProfile = _userProfile.copyWith(avatarLocalPath: path);
  await _saveUserProfile();
  notifyListeners();
  return true;
}
```

**Tại sao validate trong AppState mà không trong UI?**
- Để đảm bảo quy tắc **Single Source of Truth**. Dù bạn sửa từ màn hình nào, quy tắc kiểm tra chỉ nằm ở một nơi.

### 5.5. Hệ thống cảnh báo SOS (`triggerSOS`)

```dart
void triggerSOS(int elderlyId, String message, String urgency, double lat, double lng) {
  // 1. Cập nhật trạng thái người cao tuổi thành warning/critical
  // 2. Tạo AlertModel mới
  // 3. Thêm vào lịch sử _alerts
  // 4. Nếu là critical → đặt làm _activeAlert (để popup tự động hiện)
  // 5. notifyListeners()
}
```

---

## 6. Mô Phỏng Dữ Liệu Realtime (`startSimulation`)

**File:** `lib/utils/app_state.dart` (hàm `startSimulation`)

Vì chưa có thiết bị ESP32 thật, ứng dụng tự mô phỏng dữ liệu cập nhật mỗi **4 giây**.

### 6.1. Timer trong Flutter

```dart
_simulationTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
  // Chạy code này mỗi 4 giây
});
```

**Giải thích:** `Timer.periodic` giống như `setInterval` trong JavaScript. Nó chạy lặp lại mãi cho đến khi bị hủy (`cancel()`).

### 6.2. Các sự kiện mô phỏng

| Sự kiện | Logic |
|---------|-------|
| **Pin giảm** | Mỗi chu kỳ có 50% giảm 1% pin. Khi về 0 → thiết bị offline. |
| **Nhịp tim dao động** | Random trong khoảng 60-105 bpm. |
| **SpO2 dao động** | Random trong khoảng 92-100%. |
| **Di chuyển GPS** | 40% cơ hội dịch chuyển nhẹ tọa độ (±0.0003 độ). |
| **Vùng an toàn** | Tính khoảng cách từ người cao tuổi đến tâm vùng an toàn. Nếu vượt bán kính → `triggerSOS`. |
| **Kết nối chập chờn** | 5% cơ hội đổi trạng thái WebSocket (online/offline). |

### 6.3. Công thức Haversine (Tính khoảng cách GPS)

```dart
double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const p = 0.017453292519943295; // π / 180
  final a = 0.5 - cos((lat2 - lat1) * p) / 2 +
      cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
  return 12742 * asin(sqrt(a)) * 1000; // Kết quả: mét
}
```

**Ý nghĩa:** Tính khoảng cách giữa 2 điểm trên mặt đất từ tọa độ GPS (độ) sang mét. Dùng để kiểm tra người cao tuổi có ra khỏi vùng an toàn không.

---

## 7. Hệ Thống Giao Diện (Theme & Dark Mode)

**File:** `lib/utils/theme.dart`

### 7.1. Material 3

```dart
ThemeData(
  useMaterial3: true,
  ...
)
```

**Giải thích:** Material 3 là phiên bản mới nhất của thiết kế Material Design. Nó có các nút bo tròn đẹp hơn, màu sắc tự động điều chỉnh, và hỗ trợ Dark Mode tốt hơn.

### 7.2. Bảng màu chính

```dart
// Màu chủ đạo y tế (Teal)
static const Color primaryTeal = Color(0xFF0F766E);   // Xanh ngọc đậm
static const Color secondaryTeal = Color(0xFF14B8A6); // Xanh ngọc sáng

// Màu trạng thái
static const Color statusSafe = Color(0xFF10B981);     // Xanh lá (An toàn)
static const Color statusWarning = Color(0xFFF59E0B);  // Cam (Cảnh báo)
static const Color statusCritical = Color(0xFFEF4444); // Đỏ (Khẩn cấp)
```

### 7.3. Light Theme vs Dark Theme

```dart
// Light
scaffoldBackgroundColor: Color(0xFFF8FAFC);  // Nền xám rất nhạt
cardLight: Colors.white;

// Dark
scaffoldBackgroundColor: Color(0xFF0F172A);   // Nền xanh đen
cardDark: Color(0xFF1E293B);                  // Thẻ xanh đen nhạt hơn
```

**Cách dùng trong màn hình:**

```dart
final isDark = Theme.of(context).brightness == Brightness.dark;
return Card(
  color: isDark ? const Color(0xFF1E293B) : Colors.white,
  ...
);
```

---

## 8. Đa Ngôn Ngữ (Localization)

**File:** `lib/utils/localization.dart`

### 8.1. Cách hoạt động

Thay vì ghi chữ cứng `"Đăng xuất"`, ta ghi:

```dart
Localization.translate('logout')
```

Hệ thống sẽ tự động trả về:
- `"Đăng xuất"` nếu `currentLanguage == 'vi'`
- `"Logout"` nếu `currentLanguage == 'en'`

### 8.2. Cấu trúc

```dart
static final Map<String, Map<String, String>> _localizedValues = {
  'vi': { 'logout': 'Đăng xuất', ... },
  'en': { 'logout': 'Logout', ... },
};
```

**Ý nghĩa:** Map lồng Map. Map ngoài là `languageCode`, map trong là `key → value`.

---

## 9. Các Màn Hình Chính (Screens)

### 9.1. `LoginScreen` — Đăng nhập

**File:** `lib/screens/login_screen.dart`

- Kiểm tra kết nối Database (MySQL online hay Mock offline).
- Hỗ trợ "Ghi nhớ đăng nhập" lưu vào SharedPreferences.
- Tự động điền tài khoản/mật khẩu đã lưu khi mở app.
- Hiển thị badge trạng thái DB (Online/Offline) cho lập trình viên.
- Khi đăng nhập thành công → chuyển sang `MainShell`.

**Lưu ý quan trọng:**
```dart
final messenger = ScaffoldMessenger.of(context);
Navigator.pushReplacement(...);
messenger.showSnackBar(...);  // An toàn sau khi navigate
```

Tại sao phải lưu `messenger` trước? Vì sau `pushReplacement`, widget hiện tại bị hủy (dispose). Nếu gọi `ScaffoldMessenger.of(context)` sau khi hủy sẽ báo lỗi.

---

### 9.2. `MainShell` — Khung 3 Tab

**File:** `lib/screens/main_shell.dart`

```dart
class MainShell extends StatefulWidget {
  // Chứa PageView + BottomNavigationBar
}
```

**Cấu trúc:**
- `PageView` hiển thị 3 màn hình con:
  - Index 0: `HomeScreen` (Trang chủ)
  - Index 1: `AlertsScreen` (Cảnh báo)
  - Index 2: `SettingsScreen` (Cài đặt)
- `PageController` điều khiển chuyển trang.
- `SosBottomNav` là thanh điều hướng dưới cùng.

**Tại sao dùng `PageView` thay vì `IndexedStack`?**
- `PageView` cho phép chuyển trang có animation (trượt ngang).
- `physics: const NeverScrollableScrollPhysics()` ngăn người dùng vuốt tay — chỉ cho phép chuyển qua nút bấm.

---

### 9.3. `HomeScreen` — Trang Chủ

**File:** `lib/screens/home_screen.dart`

**Thành phần:**
1. **SosAppHeader** — Thanh tiêu đề tên app.
2. **_UserHeader** — Hiển thị avatar + tên người giám sát + số thiết bị online. Bấm vào → vào `ProfileScreen`.
3. **StatusBanner** — Banner lớn màu xanh/cam/đỏ thông báo trạng thái an toàn tổng quan.
4. **Danh sách ElderlyListCard** — Các thẻ người cao tuổi, hiển thị nhịp tim, SpO2, pin, trạng thái.

**Tính năng đặc biệt: Tự động popup cảnh báo khẩn cấp**

```dart
if (activeAlert != null && _pushedAlertId != activeAlert.id) {
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await Navigator.push(...AlertDetailScreen...);
    state.acknowledgeAlert(activeAlert.id);
  });
}
```

**Giải thích:**
- Khi `AppState` có `_activeAlert` (cảnh báo critical), màn hình Home tự động đẩy `AlertDetailScreen` lên.
- `addPostFrameCallback` đảm bảo chỉ chuyển màn **sau khi** khung hình hiện tại vẽ xong. Nếu không sẽ lỗi.
- `_pushedAlertId` tránh popup lặp lại nhiều lần cho cùng một cảnh báo.

---

### 9.4. `DetailScreen` — Chi Tiết Người Cao Tuổi

**File:** `lib/screens/detail_screen.dart`

**Thành phần:**
1. **ProfileHeader** — Ảnh đại diện, tên, tuổi, địa chỉ, badge trạng thái màu.
2. **CustomMap** — Bản đồ nhỏ hiển thị vị trí hiện tại + vùng an toàn hình tròn. Bấm vào → mở `MapViewScreen` toàn màn hình.
3. **ActionButtonGrid** — 4 nút nhanh: Gọi điện, Bật chuông, Nghe xung quanh, Nhắn tin.
4. **HealthMetricsPanel** — Bảng chỉ số sức khỏe (nhịp tim, SpO2, nhiệt độ, huyết áp).
5. **SafeZoneSlider** — Thanh trượt điều chỉnh bán kính vùng an toàn (mét).
6. **BigButton "BÁO ĐỘNG TỪ XA"** — Nút đỏ lớn kích hoạt SOS từ xa.

---

### 9.5. `AlertsScreen` — Danh Sách Cảnh Báo

**File:** `lib/screens/alerts_screen.dart`

- **FilterChipBar** — 4 nút lọc: "Tất cả", "Khẩn cấp", "Cảnh báo", "Chưa xử lý".
- **AlertListItem** — Thẻ cảnh báo hiển thị tên người, thời gian, mức độ, địa điểm.
- **FloatingActionButton** — Nút đỏ tròn góc phải dưới để thêm cảnh báo thủ công.

---

### 9.6. `SettingsScreen` — Cài Đặt & Tài Khoản

**File:** `lib/screens/settings_screen.dart`

**Thành phần:**
1. **Thẻ tài khoản** — Avatar, tên, email, role. Bấm → `ProfileScreen`.
2. **Danh sách người thân** — Hiển thị người đang giám sát, trạng thái màu chấm tròn.
3. **Cài đặt hệ thống** — Ngôn ngữ (Switch Vi/En), Dark Mode, Âm thanh cảnh báo, Tự động gọi.
4. **Thông tin & Đăng xuất** — Phiên bản app, nút đăng xuất.
5. **Developer Tools** (ExpansionTile) — Các nút mô phỏng sự cố để test:
   - "Mô phỏng té ngã"
   - "Mô phỏng vượt vùng an toàn"
   - "Mô phỏng nhịp tim/SpO2 xấu"
   - "Đổi online/offline thiết bị"

---

### 9.7. `ProfileScreen` — Hồ Sơ Cá Nhân (MỚI NHẤT)

**File:** `lib/screens/profile_screen.dart`

**Thành phần:**
1. **AvatarPicker** — Ảnh đại diện lớn, bấm icon camera → chọn ảnh từ thư viện.
2. **Tên** — Bấm icon bút → mở dialog sửa tên.
3. **Email & SĐT** — Từng dòng, bấm vào sửa riêng.
4. **Đang giám sát** — Hiển thị số người thân (không sửa được).
5. **Nút Cài đặt & Đăng xuất**.

**Cách sửa thông tin:**
- Mỗi trường (tên, email, SĐT) có dialog riêng (`EditSingleFieldDialog`).
- Validate trước khi lưu (VD: SĐT phải đúng 10 chữ số).
- Sau khi lưu → hiện SnackBar xanh (thành công) hoặc đỏ (thất bại).

---

## 10. Các Widget Tái Sử Dụng Quan Trọng

Widget là khối LEGO của Flutter. Ta tách thành file riêng để dùng lại nhiều nơi.

### 10.1. `SosAppHeader` — Thanh tiêu đề chuẩn

**File:** `lib/widgets/sos_app_header.dart`

```dart
class SosAppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  ...
}
```

- Tự động hiển thị nút quay lại (`arrow_back_ios_new`) khi có thể pop.
- Tự đổi màu chữ/trang trí theo Dark/Light mode.
- Có thể thêm `subtitle` (dòng chữ nhỏ dưới tiêu đề).
- `implements PreferredSizeWidget` bắt buộc vì `AppBar` cần biết chiều cao chính xác.

### 10.2. `SosBottomNav` — Thanh điều hướng dưới

**File:** `lib/widgets/sos_bottom_nav.dart`

- 3 tab: Trang chủ (icon nhà), Cảnh báo (icon chuông), Cài đặt (icon bánh răng).
- Màu đỏ (`E53935`) khi được chọn. Màu xám khi không chọn.
- Tự đổi nền theo Dark Mode.

### 10.3. `ElderlyListCard` — Thẻ người cao tuổi

**File:** `lib/widgets/elderly_list_card.dart`

- Hiển thị avatar, tên, tên thiết bị đeo.
- 3 badge chỉ số: Nhịp tim (đỏ), SpO2 (xanh), Pin (xanh/cam).
- Viền thẻ đổi màu theo trạng thái: Xanh lá (safe), Cam (warning), Đỏ (critical), Xám (offline).
- Chấm tròn trạng thái ở góc phải tên.

### 10.4. `StatusBanner` — Banner trạng thái tổng quan

**File:** `lib/widgets/status_banner.dart`

- Màu xanh: "HỆ THỐNG AN TOÀN"
- Màu cam: "CẦN CHÚ Ý — Chỉ số sức khỏe có bất thường"
- Màu đỏ: "SOS KHẨN CẤP! — Có người thân cần trợ giúp ngay!"

### 10.5. `AvatarPicker` — Chọn ảnh đại diện (MỚI)

**File:** `lib/widgets/avatar_picker.dart`

```dart
class AvatarPicker extends StatefulWidget {
  final String avatarUrl;        // URL từ internet
  final String avatarLocalPath;  // Đường dẫn file local
  final ValueChanged<String> onPicked;  // Callback khi chọn xong
}
```

**Cách dùng `image_picker`:**
```dart
final XFile? file = await _picker.pickImage(
  source: ImageSource.gallery,  // Mở thư viện ảnh
  maxWidth: 1024,               // Giới hạn kích thước
  maxHeight: 1024,
  imageQuality: 85,             // Nén ảnh 85%
);
```

**Giải thích `ValueChanged<String>`:**
- Đây là kiểu typedef (bí danh) của Flutter, định nghĩa: `void Function(String value)`.
- Nghĩa là "một hàm nhận vào 1 chuỗi String và không trả về gì".
- Dùng để báo cho cha biết: "Người dùng vừa chọn ảnh, đây là đường dẫn file".

### 10.6. `ProfileAvatar` — Hiển thị avatar nhỏ (MỚI)

**File:** `lib/widgets/profile_avatar.dart`

- Dùng ở `_UserHeader` (HomeScreen) và `SettingsScreen`.
- Ưu tiên ảnh local (`FileImage`), nếu không có thì dùng URL (`NetworkImage`).
- Nếu cả hai đều không có → hiển thị icon `Icons.person`.

### 10.7. `EditSingleFieldDialog` — Dialog sửa 1 trường (MỚI)

**File:** `lib/widgets/edit_single_field_dialog.dart`

- Dùng chung cho sửa Tên, Email, SĐT.
- Có `validator` (hàm kiểm tra hợp lệ) truyền từ ngoài vào.
- Có `keyboardType` (bàn phím chữ, số, email...).
- Có `inputFormatters` (giới hạn ký tự nhập, VD: chỉ cho nhập số cho SĐT).

**Ví dụ validate email:**
```dart
final re = RegExp(r'^[\w\.\-\+]+@([\w\-]+\.)+[A-Za-z]{2,}$');
if (!re.hasMatch(v.trim())) return 'Email không hợp lệ';
```

---

## 11. Bản Đồ & Vùng An Toàn

**File chính:** `lib/widgets/custom_map.dart`

### 11.1. Công nghệ

- **flutter_map:** Thư viện bản đồ miễn phí, dùng tile từ OpenStreetMap. Không cần API key như Google Maps.
- **latlong2:** Xử lý tọa độ latitude/longitude.
- **geocoding:** Chuyển tọa độ → địa chỉ chữ (reverse geocoding qua Nominatim).

### 11.2. Hiển thị trên bản đồ

- **Marker người cao tuổi:** Vị trí hiện tại, có popup tên.
- **Vùng an toàn:** Hình tròn màu xanh trong suốt (`CircleMarker`), tâm là `safeZoneLat/safeZoneLng`, bán kính `safeZoneRadius` mét.
- **Tên địa chỉ:** Hiển thị chữ bên dưới bản đồ (VD: "268 Lý Thường Kiệt, Quận 10").

---

## 12. Dependencies (Thư Viện Bên Ngoài)

**File:** `pubspec.yaml`

| Package | Phiên bản | Tác dụng |
|---------|-----------|----------|
| `mysql1` | ^0.20.0 | Kết nối MySQL trực tiếp (Windows/Linux) |
| `shared_preferences` | ^2.3.2 | Lưu dữ liệu nhỏ local (settings, profile) |
| `http` | ^1.2.2 | Gọi API REST (Web → Backend) |
| `flutter_map` | ^7.0.2 | Bản đồ miễn phí (OpenStreetMap) |
| `latlong2` | ^0.9.1 | Tính toán tọa độ GPS |
| `geocoding` | ^3.0.0 | Chuyển tọa độ → địa chỉ chữ |
| `image_picker` | ^1.1.2 | Chọn ảnh từ thư viện/camera (MỚI) |
| `cupertino_icons` | ^1.0.8 | Icon kiểu iOS |

---

## 13. Các Pattern (Mẫu Thiết Kế) Quan Trọng Cho Người Mới

### 13.1. Singleton
Đảm bảo một class chỉ có 1 instance duy nhất. Dùng cho `AppState` để toàn app dùng chung 1 bộ dữ liệu.

### 13.2. Immutable Data (copyWith)
Không sửa object trực tiếp, mà tạo object mới. Giúp Flutter theo dõi thay đổi chính xác, tránh bug khó tìm.

### 13.3. Observer Pattern (ChangeNotifier + AnimatedBuilder)
- `ChangeNotifier` là "bên phát" (publisher).
- `AnimatedBuilder` (hoặc `ListenableBuilder`) là "bên nhận" (subscriber).
- Khi dữ liệu thay đổi → tất cả subscriber tự động rebuild.

### 13.4. Composition over Inheritance
Thay vì kế thừa (extends), ta **tổng hợp** (composition). Ví dụ: `DetailScreen` không kế thừa `CustomMap`, mà **chứa** `CustomMap` bên trong.

### 13.5. Separation of Concerns (SoC)
- **Model:** Chỉ chứa dữ liệu.
- **State:** Chỉ quản lý logic và dữ liệu.
- **UI (Widget):** Chỉ vẽ giao diện, không chứa logic nghiệp vụ.
- **Screen:** Ghép các widget lại thành màn hình hoàn chỉnh.

---

## 14. Lưu Ý Về Git & Lưu Trữ

### Các commit đã thực hiện
1. `bd8ec83` — update lần 5: Thêm 5 màn hình điều khiển từ xa.
2. `e45bffd` — update lần 6: Thay đổi giao diện toàn diện, bản đồ hoàn chỉnh.

### Thay đổi chưa commit (07/06)
- Thêm `UserProfile`, `ProfileScreen`, `AvatarPicker`, `image_picker`.
- Xóa `account_screen.dart` (gộp vào Settings).
- Xóa `test/widget_test.dart` cũ → thay bằng `test/user_profile_test.dart`.
- Cập nhật plugin registrant cho Linux, macOS, Windows.

---

## 15. Tóm Tắt Cho Người Mới — "Mình Cần Nhớ Gì?"

| Khái niệm | Nhớ gì? |
|-----------|---------|
| **Widget** | Mọi thứ trên màn hình đều là Widget. Tách nhỏ ra để dùng lại. |
| **ChangeNotifier** | Quản lý dữ liệu chung. Gọi `notifyListeners()` sau khi sửa dữ liệu. |
| **Singleton** | `AppState()` luôn trả về 1 object duy nhất. Dùng `factory` + `static`. |
| **copyWith** | Tạo bản sao object với vài trường thay đổi. Không sửa trực tiếp. |
| **SharedPreferences** | Lưu nhỏ trên điện thoại. Dùng `getString`/`setString`. |
| **Timer.periodic** | Chạy code lặp lại theo chu kỳ (mô phỏng realtime). |
| **context.mounted** | Kiểm tra widget còn "sống" không trước khi dùng `context` sau `await`. |
| **Theme.of(context)** | Lấy theme hiện tại để biết đang sáng hay tối. |
| **ValueChanged<T>** | Kiểu hàm callback `void Function(T value)`. Dùng để truyền dữ liệu ngược lên cha. |

---

*Ngày tổng hợp: 07/06/2026*
*Tác giả: Claude Code (tổng hợp từ git history & codebase)*
