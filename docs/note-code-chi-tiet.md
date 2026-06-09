# Note Code Chi Tiết — SOS Care Flutter

> **Mục đích:** Tài liệu này copy-paste từng đoạn code quan trọng trong dự án và giải thích **từng dòng** để người mới đọc hiểu ngay lập tức. Đọc kèm với `tong-hop-tien-do-06-06-den-07-06.md` để hiểu bối cảnh.

---

## Mục lục
- [1. Cấu trúc cơ bản một file Dart](#1-cấu-trúc-cơ-bản-một-file-dart)
- [2. Model — copyWith Pattern](#2-model--copywith-pattern)
- [3. Singleton — AppState](#3-singleton--appstate)
- [4. Widget lifecycle — initState, dispose](#4-widget-lifecycle--initstate-dispose)
- [5. Tương tác với SharedPreferences](#5-tương-tác-với-sharedpreferences)
- [6. ChangeNotifier + AnimatedBuilder](#6-changenotifier--animatedbuilder)
- [7. Navigation giữa các màn hình](#7-navigation-giữa-các-màn-hình)
- [8. Dialog và Form Validation](#8-dialog-và-form-validation)
- [9. Image Picker — chọn ảnh từ thư viện](#9-image-picker--chọn-ảnh-từ-thư-viện)
- [10. Timer và mô phỏng Realtime](#10-timer-và-mô-phỏng-realtime)
- [11. Tính toán GPS — Haversine](#11-tính-toán-gps--haversine)
- [12. Dark Mode — Theme.of(context)](#12-dark-mode--themeofcontext)
- [13. SnackBar an toàn sau async](#13-snackbar-an-toàn-sau-async)
- [14. Safe context check sau await](#14-safe-context-check-sau-await)
- [15. Widget tái sử dụng — Stateless vs Stateful](#15-widget-tái-sử-dụng--stateless-vs-stateful)

---

## 1. Cấu trúc cơ bản một file Dart

### Ví dụ từ `lib/models/user_profile.dart`

```dart
/// Lớp lưu trữ thông tin tài khoản của chủ tài khoản (người giám sát).
class UserProfile {
  final String id;
  final String name;
```
}

**Giải thích:**
- `///` là comment kiểu **docstring**. Flutter sẽ hiển thị khi bạn hover chuột vào class.
- `class UserProfile` định nghĩa một lớp (blueprint/template) tên là UserProfile.
- `final String id;` khai báo biến `id` kiểu `String` (chuỗi ký tự), `final` nghĩa là chỉ gán **một lần** (immutable).

```dart
  const UserProfile({
    required this.id,
    required this.name,
```
  })

**Giải thích:**
- `const` constructor nghĩa là object này có thể được tạo tại **thời điểm compile** (tối ưu bộ nhớ).
- `required this.id` nghĩa là khi tạo object, **bắt buộc** phải truyền giá trị cho `id`. `this.id` là cú pháp ngắn gọn của `id = id` (named parameter + field assignment).

```dart
  UserProfile copyWith({
    String? id,
    String? name,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }
```

**Giải thích:**
- `String? id` — dấu `?` nghĩa là có thể nhận `null`.
- `id ?? this.id` — toán tử **null coalescing**. Nếu `id` truyền vào là `null` thì giữ giá trị cũ (`this.id`). Nếu có giá trị thì dùng giá trị mới.

---

## 2. Model — copyWith Pattern

### Ví dụ từ `lib/models/elderly_model.dart`

```dart
  factory ElderlyModel.fromMap(Map<String, dynamic> map) {
    return ElderlyModel(
      id: map['id'] as int,
      name: map['name'] as String,
      battery: map['battery'] as int,
      lastUpdated: DateTime.parse(map['lastUpdated'] as String),
```

**Giải thích:**
- `factory` là constructor đặc biệt — không nhất thiết tạo instance mới, có thể trả về instance có sẵn (singleton) hoặc object từ cache.
- `Map<String, dynamic>` — kiểu dữ liệu key-value giống JSON. `dynamic` nghĩa là giá trị có thể là bất kỳ kiểu gì (String, int, double, List...).
- `map['id'] as int` — lấy giá trị từ Map rồi **ép kiểu** (cast) sang `int`. Nếu ép sai sẽ crash runtime.
- `DateTime.parse(...)` — chuyển chuỗi ISO 8601 (vd: `"2026-06-07T10:30:00"`) thành object `DateTime`.

```dart
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'lastUpdated': lastUpdated.toIso8601String(),
```

**Giải thích:**
- `toIso8601String()` chuyển `DateTime` thành chuỗi chuẩn ISO để lưu JSON.
- Kết quả của `toMap()` sẽ được đưa vào `json.encode()` để lưu SharedPreferences.

---

## 3. Singleton — AppState

### Ví dụ từ `lib/utils/app_state.dart`

```dart
class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal() {
    _loadSettings();
    _loadUserProfile();
    _loadElderlyData();
    _loadAlertHistory();
    startSimulation();
  }
```

**Giải thích từng dòng:**

| Dòng code | Ý nghĩa |
|-----------|---------|
| `static final AppState _instance` | Biến `static` thuộc về **class** chứ không thuộc instance. Chỉ tồn tại 1 bản duy nhất trong suốt vòng đời app. |
| `= AppState._internal()` | Khởi tạo ngay lập tức khi class được load lần đầu. |
| `factory AppState() => _instance;` | Khi ai đó gọi `AppState()`, factory **không** tạo object mới mà trả về `_instance` đã có. |
| `AppState._internal()` | Constructor **private** (có dấu `_`). Chỉ được gọi từ bên trong class, 1 lần duy nhất khi khởi tạo `_instance`. |
| `{ ... }` | Body của private constructor. Chạy các hàm load dữ liệu và bắt đầu mô phỏng. |

**Cách dùng:**
```dart
// Ở bất kỳ đâu trong app
final state = AppState();  // Luôn trả về cùng 1 object
```

---

## 4. Widget lifecycle — initState, dispose

### Ví dụ từ `lib/screens/login_screen.dart`

```dart
class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _checkDatabaseStatus();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }
```

**Giải thích vòng đời (lifecycle):**

```
Constructor của Widget
    ↓
initState()  ← Chạy 1 lần khi Widget được tạo
    ↓
build()      ← Vẽ UI
    ↓
build() lại  ← Khi setState() hoặc notifyListeners()
    ↓
dispose()    ← Chạy 1 lần khi Widget bị hủy
```

- `initState()`: Dùng để khởi tạo dữ liệu, gọi API, đăng ký listener. **Luôn gọi `super.initState()` đầu tiên.**
- `dispose()`: Dùng để giải phóng tài nguyên (controller, timer, listener). **Luôn gọi `super.dispose()` cuối cùng.**
- Nếu quên `dispose()` TextEditingController → **rò rỉ bộ nhớ** (memory leak).

---

## 5. Tương tác với SharedPreferences

### Ví dụ từ `lib/utils/app_state.dart`

```dart
Future<void> _loadSettings() async {
  final prefs = await SharedPreferences.getInstance();
  final jsonStr = prefs.getString('app_settings');
  if (jsonStr != null) {
    try {
      final map = json.decode(jsonStr) as Map<String, dynamic>;
      _settings = AppSettings.fromMap(map);
      Localization.currentLanguage = _settings.languageCode;
    } catch (e) {
      print('Lỗi đọc settings: $e');
    }
  }
  notifyListeners();
}
```

**Giải thích từng dòng:**

| Dòng code | Ý nghĩa |
|-----------|---------|
| `Future<void>` | Hàm này **bất đồng bộ** (async), trả về Future (lời hứa sẽ hoàn thành sau). Không trả về giá trị (`void`). |
| `await SharedPreferences.getInstance()` | Đợi lấy instance SharedPreferences. Có `await` nên hàm phải là `async`. |
| `prefs.getString('app_settings')` | Đọc chuỗi đã lưu với key là `'app_settings'`. Nếu chưa lưu → trả về `null`. |
| `json.decode(jsonStr)` | Chuyển chuỗi JSON thành Map. |
| `as Map<String, dynamic>` | Ép kiểu kết quả thành Map. Nếu không phải Map sẽ crash → nên bọc trong `try-catch`. |
| `notifyListeners()` | Báo cho UI: dữ liệu đã thay đổi, hãy vẽ lại! |

```dart
Future<void> updateSettings(AppSettings newSettings) async {
  _settings = newSettings;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('app_settings', json.encode(_settings.toMap()));
  notifyListeners();
}
```

**Giải thích:**
- `json.encode(...)`: Chuyển Map → chuỗi JSON để lưu.
- `prefs.setString(...)`: Lưu chuỗi vào bộ nhớ điện thoại. Bất đồng bộ nên cần `await`.

---

## 6. ChangeNotifier + AnimatedBuilder

### Ví dụ từ `lib/screens/home_screen.dart`

```dart
class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final state = AppState();
    return AnimatedBuilder(
      animation: state,
      builder: (context, child) {
        final relatives = state.relatives;
        return Scaffold(
          appBar: SosAppHeader(title: Localization.translate('appName')),
          body: ...
        );
      },
    );
  }
}
```

**Giải thích:**
- `AppState extends ChangeNotifier` → `state` có thể dùng làm `animation` trong `AnimatedBuilder`.
- Khi `AppState` gọi `notifyListeners()`, `AnimatedBuilder` tự động chạy lại `builder`.
- `child` trong builder là widget con tĩnh (nếu có) để tối ưu, tránh rebuild thừa.

**Cách khác: `ListenableBuilder`** (Flutter 3.0+)
```dart
ListenableBuilder(
  listenable: state,
  builder: (context, _) {
    // Tương tự AnimatedBuilder nhưng rõ ràng hơn
  },
)
```

---

## 7. Navigation giữa các màn hình

### 7.1. Chuyển màn hình thường

```dart
// Từ HomeScreen → DetailScreen
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => DetailScreen(elderlyId: r.id)),
);
```

**Giải thích:**
- `Navigator.push(...)`: Đẩy màn hình mới lên **trên cùng** của stack. Người dùng có thể quay lại bằng nút back.
- `MaterialPageRoute`: Hiệu ứng chuyển màn kiểu Material (trượt từ phải sang).
- `builder: (context) => ...`: Hàm trả về widget mới. `context` ở đây là context mới.

### 7.2. Thay thế màn hình (không cho quay lại)

```dart
// Từ LoginScreen → MainShell (không cho back về Login)
Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (context) => const MainShell()),
);
```

**Ý nghĩa:** Sau khi đăng nhập, không muốn người dùng bấm back để về màn Login.

### 7.3. Xóa tất cả và chuyển màn (Logout)

```dart
// Từ bất kỳ đâu → LoginScreen, xóa hết lịch sử
Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(builder: (_) => const LoginScreen()),
  (route) => false,  // Giữ lại route nào? false = không giữ cái nào
);
```

**Giải thích:**
- `pushAndRemoveUntil`: Đẩy màn hình mới lên và **xóa tất cả** các màn hình cũ thỏa điều kiện.
- `(route) => false`: Predicate trả về `false` cho mọi route → xóa hết.

---

## 8. Dialog và Form Validation

### 8.1. Mở dialog và nhận kết quả

```dart
final newName = await showDialog<String>(
  context: context,
  builder: (_) => EditSingleFieldDialog(
    title: 'Sửa họ và tên',
    label: 'Họ và tên',
    initialValue: state.userProfile.name,
    validator: (v) {
      if (v == null || v.trim().isEmpty) return 'Vui lòng nhập họ và tên';
      if (v.trim().length < 2) return 'Họ và tên quá ngắn';
      return null;  // null = hợp lệ
    },
  ),
);
if (newName == null) return false;  // Người dùng bấm Huỷ
```

**Giải thích:**
- `showDialog<String>`: Mở dialog, kỳ vọng trả về `String` (hoặc `null`).
- `builder: (_) => ...`: Dấu `_` nghĩa là "tham số này không dùng" (context ở đây không cần).
- `validator`: Hàm nhận giá trị nhập, trả về `String` (lỗi) hoặc `null` (hợp lệ).
- `await`: Đợi người dùng tương tác xong dialog mới tiếp tục.

### 8.2. Form với GlobalKey

```dart
class _EditSingleFieldDialogState extends State<EditSingleFieldDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _hasError = false;

  void _onSave() {
    setState(() => _hasError = true);
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, _ctrl.text.trim());
  }
```

**Giải thích:**
- `GlobalKey<FormState>`: Khóa toàn cục để truy cập `Form` từ bất kỳ đâu trong class.
- `_formKey.currentState!.validate()`: Chạy tất cả `validator` trong Form. Trả về `true` nếu tất cả hợp lệ.
- `Navigator.pop(context, value)`: Đóng dialog và trả về `value` cho `await showDialog` bên ngoài.

---

## 9. Image Picker — chọn ảnh từ thư viện

### Ví dụ từ `lib/widgets/avatar_picker.dart`

```dart
class _AvatarPickerState extends State<AvatarPicker> {
  final ImagePicker _picker = ImagePicker();
  bool _picking = false;

  Future<void> _pickImage() async {
    if (_picking) return;  // Tránh double-tap
    setState(() => _picking = true);  // Hiện loading
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (file != null && mounted) {
        widget.onPicked(file.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể mở thư viện ảnh: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }
```

**Giải thích:**
- `ImagePicker _picker = ImagePicker()`: Tạo instance của plugin image_picker.
- `await _picker.pickImage(...)`: Mở gallery, đợi người dùng chọn ảnh.
- `XFile?`: Kiểu file của plugin. `?` nghĩa là có thể `null` nếu người dùng huỷ.
- `mounted`: Kiểm tra widget còn "sống" trong cây widget không. **Rất quan trọng sau `await`** — nếu widget đã bị hủy (navigate đi nơi khác) thì không được dùng `context`.
- `widget.onPicked(file.path)`: Gọi callback được truyền từ cha (parent widget), trả về đường dẫn file.
- `try-catch-finally`: Bắt lỗi nếu người dùng từ chối quyền truy cập gallery.

---

## 10. Timer và mô phỏng Realtime

### Ví dụ từ `lib/utils/app_state.dart`

```dart
void startSimulation() {
  _simulationTimer?.cancel();  // Hủy timer cũ nếu có
  _simulationTimer = Timer.periodic(    // .periodic: 
    const Duration(seconds: 4),
    (timer) {
      final random = Random();
      
      // Mô phỏng kết nối chập chờn (5% cơ hội)
      if (random.nextInt(100) < 5) {
        _isWebSocketConnected = !_isWebSocketConnected;
        notifyListeners();
      }

      if (!_isWebSocketConnected) return;

      for (int i = 0; i < _relatives.length; i++) {
        final elderly = _relatives[i];
        if (elderly.isOffline) continue;  // Bỏ qua nếu offline

        int newBattery = elderly.battery - (random.nextInt(2) == 0 ? 1 : 0);
        if (newBattery < 0) newBattery = 0;

        int newHeart = elderly.heartRate;
        newHeart += random.nextInt(7) - 3;  // -3 đến +3
        if (newHeart < 60) newHeart = 60;
        if (newHeart > 105) newHeart = 105;

        _relatives[i] = elderly.copyWith(
          battery: newBattery,
          heartRate: newHeart,
          lastUpdated: DateTime.now(),
        );
      }
      notifyListeners();
    },
  );
}
```

**Giải thích:**
- `Timer.periodic(Duration, callback)`: Chạy callback lặp lại mỗi khoảng thời gian.
- `?.cancel()`: Null-aware operator. Nếu `_simulationTimer` không null thì hủy, nếu null thì không làm gì.
- `Random().nextInt(100) < 5`: Tạo số ngẫu nhiên 0-99, nếu < 5 thì xác suất là 5%.
- `continue`: Bỏ qua vòng lặp hiện tại, chuyển sang người cao tuổi tiếp theo.
- `random.nextInt(7) - 3`: Random từ -3 đến +3 (vì nextInt(7) cho 0..6, trừ 3 → -3..3).

---

## 11. Tính toán GPS — Haversine

### Ví dụ từ `lib/utils/app_state.dart`

```dart
double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const p = 0.017453292519943295; // Math.PI / 180
  final a = 0.5 - cos((lat2 - lat1) * p) / 2 +
      cos(lat1 * p) * cos(lat2 * p) *
          (1 - cos((lon2 - lon1) * p)) / 2;
  return 12742 * asin(sqrt(a)) * 1000; // Kết quả: mét
}
```

**Giải thích:**
- **Haversine** là công thức tính khoảng cách giữa 2 điểm trên mặt cầu (Trái Đất) từ tọa độ latitude/longitude.
- `p = π / 180`: Chuyển độ sang radian (đơn vị tính toán lượng giác).
- `12742`: Đường kính Trái Đất theo km (2 × bán kính 6371 km).
- `* 1000`: Chuyển km → mét.
- Kết quả: Khoảng cách giữa người cao tuổi và tâm vùng an toàn, đơn vị mét.

**Cách dùng:**
```dart
if (distance > elderly.safeZoneRadius) {
  triggerSOS(elderly.id, 'Ra khỏi vùng an toàn', 'critical', newLat, newLng);
}
```

---

## 12. Dark Mode — Theme.of(context)

### Ví dụ từ nhiều file

```dart
final isDark = Theme.of(context).brightness == Brightness.dark;
return Card(
  color: isDark ? const Color(0xFF1E293B) : Colors.white,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
    side: BorderSide(
      color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
    ),
  ),
);
```

**Giải thích:**
- `Theme.of(context)`: Lấy theme hiện tại của app (light hoặc dark).
- `brightness == Brightness.dark`: Kiểm tra có phải đang ở chế độ tối không.
- Toán tử 3 ngôi (ternary): `điều kiện ? giá_trị_đúng : giá_trị_sai`.
- `Colors.grey.shade800`: Màu xám đậm. `shade` là cách lấy các mức độ sáng/tối của một màu trong Flutter.

---

## 13. SnackBar an toàn sau async

### Ví dụ từ `lib/screens/login_screen.dart`

```dart
Future<void> _handleLogin() async {
  bool success = await DbHelper.loginUser(username, password);

  if (success) {
    // ❌ SAI: ScaffoldMessenger.of(context).showSnackBar(...) sau pushReplacement
    // ✅ ĐÚNG: Lưu messenger trước khi navigate
    final messenger = ScaffoldMessenger.of(context);
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainShell()),
    );

    messenger.showSnackBar(
      SnackBar(
        content: Text(statusMsg),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
```

**Vì sao phải lưu `messenger` trước?**
- Sau `pushReplacement`, widget `LoginScreen` bị hủy (dispose), `context` không còn hợp lệ.
- `ScaffoldMessenger.of(context)` sau khi dispose sẽ crash với lỗi "Looking up a deactivated widget's ancestor".
- Lưu instance `messenger` trước khi navigate thì vẫn dùng được sau.

---

## 14. Safe context check sau await

### Ví dụ từ `lib/screens/profile_screen.dart`

```dart
Future<void> _onAvatarPicked(BuildContext context, AppState state, String path) async {
  final ok = await state.updateUserAvatarLocalPath(path);
  if (!context.mounted) return;  // ← Dòng này cực kỳ quan trọng
  showProfileUpdateResult(context, ok, successMessage: 'Đã cập nhật ảnh đại diện');
}
```

**Giải thích:**
- `await state.updateUserAvatarLocalPath(path)`: Có thể mất vài mili-giây.
- Trong khi chờ, người dùng có thể bấm back → widget bị hủy.
- `context.mounted`: Kiểm tra widget còn trong cây widget không.
- **Quy tắc vàng:** Sau mọi `await` nếu dùng `context`, **phải kiểm tra `mounted` trước**.

---

## 15. Widget tái sử dụng — Stateless vs Stateful

### 15.1. StatelessWidget — Không có trạng thái

```dart
class StatusBanner extends StatelessWidget {
  final String status;  // Nhận dữ liệu từ ngoài vào

  const StatusBanner({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    // Chỉ vẽ dựa trên `status` được truyền vào
    return Container(...);
  }
}
```

**Khi nào dùng:** Widget chỉ hiển thị dữ liệu, không cần lưu trạng thái nội bộ, không thay đổi sau khi build.

### 15.2. StatefulWidget — Có trạng thái

```dart
class AvatarPicker extends StatefulWidget {
  final String avatarUrl;
  final ValueChanged<String> onPicked;  // Callback khi chọn xong

  const AvatarPicker({super.key, required this.avatarUrl, required this.onPicked});

  @override
  State<AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<AvatarPicker> {
  bool _picking = false;  // Trạng thái nội bộ: đang chọn ảnh hay không

  @override
  Widget build(BuildContext context) {
    // Dùng _picking để hiện loading hoặc ẩn
  }
}
```

**Khi nào dùng:** Widget cần lưu trạng thái thay đổi (loading, animation, input, checkbox) hoặc cần `initState`/`dispose`.

### 15.3. Truy cập props từ State

```dart
// Trong _AvatarPickerState
widget.avatarUrl     // ← Truy cập prop từ class cha AvatarPicker
widget.onPicked(path)  // ← Gọi callback được truyền từ cha
```

**Quy tắc:** Trong `State`, dùng `widget.` để truy cập các thuộc tính của `StatefulWidget`.

---

## 16. ValueChanged — Callback từ con lên cha

### Ví dụ từ `lib/widgets/avatar_picker.dart`

```dart
// Khai báo trong AvatarPicker (con)
final ValueChanged<String> onPicked;

// Sử dụng
widget.onPicked(file.path);
```

```dart
// Trong ProfileScreen (cha)
AvatarPicker(
  avatarUrl: profile.avatarUrl,
  avatarLocalPath: profile.avatarLocalPath,
  onPicked: (path) => _onAvatarPicked(context, state, path),
)
```

**Giải thích:**
- `ValueChanged<String>` là typedef của `void Function(String value)`.
- Nghĩa là "một hàm nhận vào 1 String, không trả về gì".
- Pattern này gọi là **"lifting state up"** — đưa trạng thái/dữ liệu lên cha, widget con chỉ báo cáo sự kiện.

---

## 17. ListTile và InkWell — Tương tác chuẩn Material

### Ví dụ từ `lib/screens/profile_screen.dart`

```dart
ListTile(
  onTap: onEdit,
  leading: Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Icon(icon, color: color, size: 22),
  ),
  title: Text(label),
  subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
  trailing: const Icon(Icons.edit, size: 18, color: Color(0xFFE53935)),
)
```

**Giải thích các thuộc tính ListTile:**
- `leading`: Widget hiển thị ở đầu (thường là icon hoặc avatar).
- `title`: Dòng chữ chính.
- `subtitle`: Dòng chữ phụ nhỏ hơn, dưới title.
- `trailing`: Widget ở cuối (thường là icon mũi tên hoặc checkbox).
- `onTap`: Hàm chạy khi người dùng bấm vào.

### InkWell — Hiệu ứng gợn sóng

```dart
InkWell(
  borderRadius: BorderRadius.circular(8),
  onTap: () => runEditName(context, state),
  child: Padding(...),
)
```

**Ý nghĩa:** `InkWell` bọc một widget và thêm hiệu ứng gợn sóng (ripple) khi bấm. Cần `borderRadius` khớp với widget con để ripple bo tròn đẹp.

---

## 18. Grid và Row/Column Layout

### Row — xếp ngang

```dart
Row(
  children: [
    Expanded(child: VitalBadge(...)),  // Chiếm không gian còn lại
    const SizedBox(width: 8),         // Khoảng cách 8px
    Expanded(child: VitalBadge(...)),
    const SizedBox(width: 8),
    Expanded(child: VitalBadge(...)),
  ],
)
```

**Giải thích:**
- `Expanded`: Bắt buộc widget chiếm hết không gian còn lại trong Row/Column.
- `SizedBox`: Widget tạo khoảng cách cố định. `width` cho Row, `height` cho Column.

### Column — xếp dọc

```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,  // Kéo dài full chiều ngang
  children: [
    const _UserHeader(),
    const SizedBox(height: 18),
    StatusBanner(status: overallStatus),
    const SizedBox(height: 24),
    ...
  ],
)
```

**Giải thích:**
- `crossAxisAlignment: CrossAxisAlignment.stretch`: Các con sẽ kéo dài theo chiều ngang (với Column) hoặc chiều dọc (với Row).

---

## 19. Stack — Chồng widget lên nhau

### Ví dụ từ `lib/widgets/avatar_picker.dart`

```dart
Stack(
  alignment: Alignment.bottomRight,
  children: [
    GestureDetector(
      onTap: _pickImage,
      child: CircleAvatar(radius: 48, ...),
    ),
    Material(
      color: const Color(0xFFE53935),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: _pickImage,
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: Icon(Icons.camera_alt, color: Colors.white, size: 16),
        ),
      ),
    ),
  ],
)
```

**Giải thích:**
- `Stack`: Chồng các widget lên nhau theo thứ tự (widget sau nằm trên).
- `alignment: Alignment.bottomRight`: Căn chỉnh các con ở góc dưới phải.
- Widget 1: `CircleAvatar` lớn (ảnh đại diện).
- Widget 2: `Material` + `InkWell` nhỏ (icon camera) nằm **chồng lên góc** avatar.

---

## 20. Builder Pattern trong Flutter

### `_buildSectionHeader` — Tách widget nhỏ

```dart
Widget _buildSectionHeader(String title) {
  return Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 12),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Color(0xFF64748B),
        letterSpacing: 0.8,
      ),
    ),
  );
}
```

**Ý nghĩa:** Thay vì viết `Padding` + `Text` lặp lại nhiều lần, tách thành hàm riêng, gọi `_buildSectionHeader('DANH SÁCH')`.

---

## 21. Pubspec.yaml — Khai báo thư viện

```yaml
dependencies:
  flutter:
    sdk: flutter
  mysql1: ^0.20.0
  shared_preferences: ^2.3.2
  http: ^1.2.2
  flutter_map: ^7.0.2
  latlong2: ^0.9.1
  geocoding: ^3.0.0
  image_picker: ^1.1.2
```

**Giải thích:**
- `^0.20.0`: Cho phép cập nhật phiên bản patch và minor (0.20.1, 0.21.0) nhưng không lên major (1.0.0).
- `flutter pub get`: Lệnh tải các package này về.
- `flutter_map`: Bản đồ miễn phí không cần API key.
- `image_picker`: Cần cấu hình thêm quyền trên Android (`AndroidManifest.xml`) và iOS (`Info.plist`).

---

## 22. Test đơn vị (Unit Test)

### Ví dụ từ `test/user_profile_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/user_profile.dart';

void main() {
  test('UserProfile defaultProfile tạo đúng giá trị mặc định', () {
    final profile = UserProfile.defaultProfile();
    expect(profile.name, 'Người Thân');
    expect(profile.email, 'nguoithan@example.com');
    expect(profile.avatarLocalPath, '');
  });

  test('UserProfile copyWith chỉ thay đổi trường được truyền', () {
    final profile = UserProfile.defaultProfile();
    final updated = profile.copyWith(name: 'Trần Văn B');
    expect(updated.name, 'Trần Văn B');
    expect(updated.email, profile.email);  // Không đổi
  });

  test('UserProfile toMap và fromMap hoàn nguyên', () {
    final original = UserProfile.defaultProfile();
    final map = original.toMap();
    final restored = UserProfile.fromMap(map);
    expect(restored.name, original.name);
    expect(restored.email, original.email);
  });
}
```

**Giải thích:**
- `test('mô tả', () { ... })`: Định nghĩa một test case.
- `expect(giá_trị, kỳ_vọng)`: So sánh. Nếu khác nhau, test FAIL.
- `flutter test`: Lệnh chạy tất cả test trong thư mục `test/`.

---

## 23. Các lỗi hay gặp và cách tránh

### Lỗi 1: "ScaffoldMessenger.of() called with a context that does not contain a Scaffold"

**Nguyên nhân:** Gọi `ScaffoldMessenger.of(context)` trong widget không có `Scaffold` cha.

**Sửa:** Đảm bảo widget được bọc trong `Scaffold` hoặc dùng `Builder` để lấy context mới.

### Lỗi 2: "setState() called after dispose()"

**Nguyên nhân:** Gọi `setState` sau khi widget đã bị hủy (thường do Timer hoặc await).

**Sửa:** Kiểm tra `mounted` trước khi gọi `setState`.

```dart
if (mounted) setState(() { ... });
```

### Lỗi 3: "Looking up a deactivated widget's ancestor"

**Nguyên nhân:** Dùng `context` sau khi widget bị hủy (thường sau `await` + `Navigator.push`).

**Sửa:** Lưu `ScaffoldMessenger` trước khi navigate, hoặc kiểm tra `context.mounted`.

### Lỗi 4: "A RenderFlex overflowed by X pixels"

**Nguyên nhân:** Nội dung trong Row/Column quá dài, vượt quá không gian có sở hữu.

**Sửa:**
- Dùng `Expanded` hoặc `Flexible` để widget co giãn.
- Bọc trong `SingleChildScrollView`.
- Dùng `ListView` thay vì `Column`.

---

## 24. Quy tắc viết code trong dự án này

| Quy tắc | Ví dụ |
|---------|-------|
| **File < 200 dòng** | Tách `HomeScreen` thành nhiều widget nhỏ: `StatusBanner`, `ElderlyListCard`... |
| **Tên file `snake_case.dart`** | `elderly_list_card.dart`, `edit_single_field_dialog.dart` |
| **Tên class `PascalCase`** | `ElderlyListCard`, `EditSingleFieldDialog` |
| **Biến/hàm `camelCase`** | `_onAvatarPicked`, `currentNavIndex` |
| **Hằng số `UPPER_SNAKE_CASE`** | `_offlineUserProfileKey` |
| **Comment docstring `///`** | Trước class và public API |
| **Validate trong AppState** | Không validate trong UI |
| **Kiểm tra `mounted` sau await** | `if (!context.mounted) return;` |

---

*File này là tài liệu sống — cập nhật khi codebase thay đổi.*
*Ngày viết: 07/06/2026*
