import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/db_helper.dart';
import '../database/mock_data.dart';
import '../models/elderly_model.dart';
import '../models/alert_model.dart';
import '../models/app_settings.dart';
import '../models/user_profile.dart';
import 'localization.dart';

/// Lớp quản lý trạng thái toàn cục của ứng dụng và mô phỏng dữ liệu realtime
class AppState extends ChangeNotifier {
  // Singleton
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal() {
    _loadSettings();
    _loadUserProfile();
    _loadElderlyData();
    _loadAlertHistory();
    startSimulation();
  }

  // Dữ liệu trong bộ nhớ
  List<ElderlyModel> _relatives = [];
  List<AlertModel> _alerts = [];
  AppSettings _settings = AppSettings.defaultSettings();
  UserProfile _userProfile = UserProfile.defaultProfile();
  AlertModel? _activeAlert; // Cảnh báo nguy cấp đang diễn ra
  bool _isWebSocketConnected =
      true; // Trạng thái kết nối realtime với ESP32/Backend
  Timer? _simulationTimer;
  int _currentNavIndex = 0; // Chỉ số tab bottom navigation hiện tại
  String? _currentAccountId; // Tài khoản đang đăng nhập (username)

  // Getters
  List<ElderlyModel> get relatives => _relatives;
  List<AlertModel> get alerts => _alerts;
  AppSettings get settings => _settings;
  UserProfile get userProfile => _userProfile;
  AlertModel? get activeAlert => _activeAlert;
  bool get isWebSocketConnected => _isWebSocketConnected;
  int get currentNavIndex => _currentNavIndex;
  String? get currentAccountId => _currentAccountId;

  /// Số cảnh báo chưa đọc hoặc chưa xử lý để hiển thị badge trên tab Thông báo.
  int get alertBadgeCount =>
      _alerts.where((a) => !a.read || !a.acknowledged).length;

  /// Đổi tab bottom navigation
  void setNavIndex(int index) {
    _currentNavIndex = index;
    notifyListeners();
  }

  /// Cập nhật trạng thái kết nối realtime từ backend / thiết bị thật.
  void setRealtimeConnection(bool connected) {
    _isWebSocketConnected = connected;
    notifyListeners();
  }

  // --- CẤU HÌNH & THIẾT LẬP ---

  /// Tải cài đặt từ SharedPreferences
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

  /// Cập nhật cài đặt
  Future<void> updateSettings(AppSettings newSettings) async {
    _settings = newSettings;
    Localization.currentLanguage = _settings.languageCode;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_settings', json.encode(_settings.toMap()));
    notifyListeners();
  }

  /// Toggle chế độ tối/sáng nhanh
  Future<void> toggleDarkMode(bool enabled) async {
    await updateSettings(_settings.copyWith(isDarkMode: enabled));
  }

  /// Đổi ngôn ngữ nhanh
  Future<void> toggleLanguage(String langCode) async {
    await updateSettings(_settings.copyWith(languageCode: langCode));
  }

  // --- QUẢN LÝ HỒ SƠ NGƯỜI DÙNG ---

  /// Khóa lưu trữ ID tài khoản hiện tại.
  static const String _currentAccountKey = 'current_account_id_v1';

  /// Khóa lưu trữ hồ sơ người dùng offline.
  /// Mỗi tài khoản có một profile riêng biệt, key được gắn với username.
  static String _offlineUserProfileKey(String? accountId) =>
      accountId == null || accountId.isEmpty
      ? 'offline_user_profile_v1'
      : 'offline_user_profile_${accountId}_v1';

  /// Tải ID tài khoản đang đăng nhập.
  Future<void> _loadCurrentAccount() async {
    final prefs = await SharedPreferences.getInstance();
    _currentAccountId = prefs.getString(_currentAccountKey);
  }

  /// Tải hồ sơ người dùng từ SharedPreferences theo tài khoản hiện tại.
  Future<void> _loadUserProfile() async {
    await _loadCurrentAccount();
    final prefs = await SharedPreferences.getInstance();
    final key = _offlineUserProfileKey(_currentAccountId);
    final jsonStr = prefs.getString(key);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final map = json.decode(jsonStr) as Map<String, dynamic>;
        _userProfile = UserProfile.fromMap(map);
      } catch (e) {
        print('Lỗi đọc user profile: $e');
        _userProfile = _defaultProfileForAccount(_currentAccountId);
      }
    } else {
      _userProfile = _defaultProfileForAccount(_currentAccountId);
    }
    notifyListeners();
  }

  /// Tạo profile mặc định cho một tài khoản.
  /// [accountId] thường là username; nếu chưa đăng nhập thì dùng profile mặc định.
  UserProfile _defaultProfileForAccount(String? accountId) {
    final base = UserProfile.defaultProfile();
    if (accountId == null || accountId.isEmpty) return base;
    return base.copyWith(id: accountId, name: accountId);
  }

  /// Lưu hồ sơ người dùng xuống SharedPreferences theo tài khoản hiện tại.
  Future<void> _saveUserProfile() async {
    final accountId = _currentAccountId;
    final prefs = await SharedPreferences.getInstance();
    final key = _offlineUserProfileKey(accountId);
    await prefs.setString(key, json.encode(_userProfile.toMap()));
  }

  /// Đặt tài khoản hiện tại sau đăng nhập và tải profile riêng của tài khoản đó.
  ///
  /// [accountId] thường là username. [displayName], [email], [phone] là thông
  /// tin lấy từ cơ sở dữ liệu khi đăng nhập; nếu chưa có thì dùng profile đã
  /// lưu hoặc khởi tạo mặc định.
  Future<void> setCurrentAccount(
    String accountId, {
    String? displayName,
    String? email,
    String? phone,
  }) async {
    _currentAccountId = accountId;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentAccountKey, accountId);

    final key = _offlineUserProfileKey(accountId);
    final jsonStr = prefs.getString(key);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        _userProfile = UserProfile.fromMap(
          json.decode(jsonStr) as Map<String, dynamic>,
        );
      } catch (e) {
        print('Lỗi đọc user profile cho $accountId: $e');
        _userProfile = _defaultProfileForAccount(accountId);
      }
    } else {
      _userProfile = _defaultProfileForAccount(accountId).copyWith(
        name: displayName?.trim().isNotEmpty == true ? displayName : null,
        email: email?.trim().isNotEmpty == true ? email : null,
        phone: phone?.trim().isNotEmpty == true ? phone : null,
      );
      await _saveUserProfile();
    }

    // Tải lại dữ liệu người thân + cảnh báo của tài khoản vừa đăng nhập,
    // đồng thời xóa cảnh báo đang active của tài khoản trước.
    _activeAlert = null;
    await _loadElderlyData();
    await _loadAlertHistory();

    notifyListeners();
  }

  /// Đăng xuất: xóa tài khoản hiện tại, tải lại trạng thái mặc định (dữ liệu
  /// demo chung khi chưa đăng nhập) để tránh lộ dữ liệu của tài khoản trước.
  Future<void> logout() async {
    _currentAccountId = null;
    _currentNavIndex = 0;
    _activeAlert = null;
    _userProfile = UserProfile.defaultProfile();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentAccountKey);

    await _loadElderlyData();
    await _loadAlertHistory();

    notifyListeners();
  }

  /// Cập nhật thông tin hồ sơ người dùng (validate trước khi gọi).
  /// Dữ liệu được cập nhật vào cơ sở dữ liệu trước, sau đó mới persist cục bộ.
  Future<bool> updateUserProfile(UserProfile updated) async {
    print(
      '[DEBUG] updateUserProfile được gọi với: name="${updated.name}", email="${updated.email}", phone="${updated.phone}"',
    );
    if (updated.name.trim().isEmpty) {
      print('[DEBUG] updateUserProfile FAIL: name rỗng ("${updated.name}")');
      return false;
    }
    if (updated.email.trim().isEmpty) {
      print('[DEBUG] updateUserProfile FAIL: email rỗng ("${updated.email}")');
      return false;
    }
    if (updated.email.trim().length > 48) {
      print(
        '[DEBUG] updateUserProfile FAIL: email dài ${updated.email.trim().length} ký tự > 48 ("${updated.email}")',
      );
      return false;
    }
    if (!RegExp(r'^[0-9]{10}$').hasMatch(updated.phone.trim())) {
      print(
        '[DEBUG] updateUserProfile FAIL: phone sai format ("${updated.phone}", length=${updated.phone.trim().length})',
      );
      return false;
    }

    // Nếu đã đăng nhập, đồng bộ lên cơ sở dữ liệu trước.
    if (_currentAccountId != null && _currentAccountId!.isNotEmpty) {
      final dbOk = await DbHelper.updateUserProfile(
        _currentAccountId!,
        updated.name,
        updated.email,
        updated.phone,
      );
      if (!dbOk) {
        print('[DEBUG] updateUserProfile FAIL: lỗi cập nhật DB');
        return false;
      }
    }

    _userProfile = updated;
    await _saveUserProfile();
    notifyListeners();
    return true;
  }

  /// Cập nhập nhanh avatar (không validate name/email).
  /// Trả về true nếu thành công.
  Future<bool> updateUserAvatarLocalPath(String path) async {
    if (path.isEmpty) return false;
    _userProfile = _userProfile.copyWith(avatarLocalPath: path);
    await _saveUserProfile();
    notifyListeners();
    return true;
  }

  // --- QUẢN LÝ DỮ LIỆU NGƯỜI THÂN ---

  /// Khóa lưu trữ danh sách người thân offline.
  /// v2: thêm trường address (địa chỉ chữ).
  /// Mỗi tài khoản có key riêng để cô lập dữ liệu.
  static String _offlineElderlyKey(String? accountId) =>
      accountId == null || accountId.isEmpty
      ? 'offline_elderly_v2'
      : 'offline_elderly_${accountId}_v2';

  Future<void> _loadElderlyData() async {
    final accountId = _currentAccountId;
    final prefs = await SharedPreferences.getInstance();
    // Xóa cache cũ (v1) để buộc load lại từ MockData mới có address
    await prefs.remove('offline_elderly_v1');
    final key = _offlineElderlyKey(accountId);
    final jsonStr = prefs.getString(key);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final decoded = json.decode(jsonStr) as List<dynamic>;
        _relatives = decoded
            .map((e) => ElderlyModel.fromMap(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        print('Lỗi đọc elderly data: $e');
        _relatives = _defaultElderlyForAccount(accountId);
      }
    } else {
      _relatives = _defaultElderlyForAccount(accountId);
    }
    // Tự động fill địa chỉ nếu elderly chưa có (migrate từ phiên bản cũ)
    bool hasMigration = false;
    _relatives = _relatives.map((e) {
      if (e.address.isEmpty) {
        final mockMatch = MockData.initialElderly.firstWhere(
          (m) => m.id == e.id,
          orElse: () => e,
        );
        if (mockMatch.address.isNotEmpty) {
          hasMigration = true;
          return e.copyWith(address: mockMatch.address);
        }
      }
      return e;
    }).toList();
    if (hasMigration) {
      await _saveElderlyData();
    }
    notifyListeners();
  }

  /// Dữ liệu người thân mặc định cho một tài khoản.
  /// - Tài khoản `admin` hoặc chưa đăng nhập nhận MockData demo.
  /// - Các tài khoản khác bắt đầu rỗng.
  List<ElderlyModel> _defaultElderlyForAccount(String? accountId) {
    if (accountId == null || accountId.isEmpty || accountId == 'admin') {
      return List.from(MockData.initialElderly);
    }
    return <ElderlyModel>[];
  }

  /// Lưu danh sách người thân xuống SharedPreferences theo tài khoản hiện tại.
  Future<void> _saveElderlyData() async {
    // Chụp accountId và danh sách hiện tại trước khi await để tránh ghi nhầm
    // sang tài khoản khác hoặc ghi đè dữ liệu mới nếu account đổi trong khi save.
    final accountId = _currentAccountId;
    final relativesToSave = _relatives;
    final prefs = await SharedPreferences.getInstance();
    final key = _offlineElderlyKey(accountId);
    final data = relativesToSave.map((e) => e.toMap()).toList();
    await prefs.setString(key, json.encode(data));
  }

  /// Public entry để lưu danh sách người thân hiện tại xuống SharedPreferences.
  Future<void> persistRelatives() => _saveElderlyData();

  /// Sắp xếp lại thứ tự người thân trong danh sách.
  ///
  /// [oldIndex] là vị trí cũ của item. [newIndex] là vị trí cuối cùng item
  /// cần được chèn vào, đã được điều chỉnh theo quy ước của [ReorderableListView.onReorderItem].
  void reorderRelatives(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _relatives.length) return;
    if (newIndex < 0 || newIndex > _relatives.length) return;
    if (oldIndex == newIndex) return;

    final moved = _relatives.removeAt(oldIndex);
    _relatives.insert(newIndex, moved);

    notifyListeners();
    persistRelatives().catchError((e) {
      debugPrint('Lỗi lưu thứ tự người thân: $e');
    });
  }

  /// Thêm người thân mới
  void addElderly(ElderlyModel newRelative) {
    _relatives.add(newRelative);
    _saveElderlyData();
    notifyListeners();
  }

  /// Cập nhật thông tin người thân
  void updateElderly(ElderlyModel updated) {
    final index = _relatives.indexWhere((e) => e.id == updated.id);
    if (index != -1) {
      _relatives[index] = updated;
      _saveElderlyData();
      notifyListeners();
    }
  }

  /// Xóa người thân khỏi danh sách theo dõi, đồng thời dọn dẹp cảnh báo liên kết.
  ///
  /// Trả về `true` nếu tìm thấy và lưu thành công, `false` nếu không tìm thấy
  /// hoặc lưu thất bại. Nếu lưu thất bại, danh sách trong bộ nhớ được khôi
  /// phục để đồng bộ với dữ liệu persist.
  Future<bool> deleteElderly(int id) async {
    final index = _relatives.indexWhere((e) => e.id == id);
    if (index == -1) return false;

    final removedRelative = _relatives[index];
    final removedAlerts = _alerts.where((a) => a.elderlyId == id).toList();
    final previousActiveAlert = _activeAlert;

    _relatives.removeAt(index);
    _alerts.removeWhere((a) => a.elderlyId == id);

    if (_activeAlert?.elderlyId == id) {
      _activeAlert = null;
    }

    try {
      await _saveElderlyData();
      await _saveAlertHistory();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Lỗi lưu danh sách sau xóa: $e');

      // Khôi phục trạng thái trong bộ nhớ khi lưu thất bại.
      _relatives.insert(index, removedRelative);
      _alerts.addAll(removedAlerts);
      _alerts.sort((a, b) => b.time.compareTo(a.time));
      _activeAlert = previousActiveAlert;

      notifyListeners();
      return false;
    }
  }

  // --- QUẢN LÝ CẢNH BÁO SOS ---

  /// Khóa lưu trữ lịch sử cảnh báo SOS, mỗi tài khoản có key riêng.
  static String _offlineAlertHistoryKey(String? accountId) =>
      accountId == null || accountId.isEmpty
      ? 'offline_alert_history_v1'
      : 'offline_alert_history_${accountId}_v1';

  Future<void> _loadAlertHistory() async {
    final accountId = _currentAccountId;
    final prefs = await SharedPreferences.getInstance();
    final key = _offlineAlertHistoryKey(accountId);
    final jsonStr = prefs.getString(key);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final decoded = json.decode(jsonStr) as List<dynamic>;
        _alerts = decoded
            .map((e) => AlertModel.fromMap(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        print('Lỗi đọc alert history: $e');
        _alerts = _defaultAlertsForAccount(accountId);
      }
    } else {
      _alerts = _defaultAlertsForAccount(accountId);
    }
    // Sắp xếp cảnh báo gần nhất lên đầu
    _alerts.sort((a, b) => b.time.compareTo(a.time));
    notifyListeners();
  }

  /// Lưu lịch sử cảnh báo xuống SharedPreferences theo tài khoản hiện tại.
  Future<void> _saveAlertHistory() async {
    final accountId = _currentAccountId;
    final alertsToSave = _alerts;
    final prefs = await SharedPreferences.getInstance();
    final key = _offlineAlertHistoryKey(accountId);
    final data = alertsToSave.map((a) => a.toMap()).toList();
    await prefs.setString(key, json.encode(data));
  }

  /// Dữ liệu cảnh báo mặc định cho một tài khoản.
  /// - Tài khoản `admin` hoặc chưa đăng nhập nhận MockData demo.
  /// - Các tài khoản khác bắt đầu rỗng.
  List<AlertModel> _defaultAlertsForAccount(String? accountId) {
    if (accountId == null || accountId.isEmpty || accountId == 'admin') {
      return List.from(MockData.initialAlerts);
    }
    return <AlertModel>[];
  }

  /// Kích hoạt cảnh báo SOS mới
  void triggerSOS(
    int elderlyId,
    String message,
    String urgency,
    double lat,
    double lng, {
    String? type,
  }) {
    final elderly = _relatives.firstWhere((e) => e.id == elderlyId);

    final inferredType = type ?? _inferAlertType(message);

    // Cập nhật trạng thái người cao tuổi thành warning/critical
    final updatedElderly = elderly.copyWith(
      status: urgency == 'critical' ? 'critical' : 'warning',
      lastUpdated: DateTime.now(),
      latitude: lat,
      longitude: lng,
      isFallen: inferredType == 'fall',
    );
    updateElderly(updatedElderly);

    // Tạo sự kiện Alert mới
    final newAlert = AlertModel(
      id: 'alert_${DateTime.now().millisecondsSinceEpoch}',
      elderlyId: elderlyId,
      elderlyName: elderly.name,
      time: DateTime.now(),
      locationName: lat == elderly.safeZoneLat && lng == elderly.safeZoneLng
          ? 'Khu vực nhà ở (Vùng An Toàn)'
          : 'Khu vực đường đi tự do (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})',
      urgency: urgency,
      message: message,
      acknowledged: false,
      type: inferredType,
      latitude: lat,
      longitude: lng,
    );

    // Thêm vào danh sách lịch sử
    _alerts.insert(0, newAlert);

    // Đặt làm cảnh báo khẩn cấp đang kích hoạt (để bật popup cảnh báo đẩy)
    if (urgency == 'critical') {
      _activeAlert = newAlert;
    }

    _saveAlertHistory().catchError((e) {
      debugPrint('Lỗi lưu lịch sử cảnh báo: $e');
    });
    notifyListeners();
  }

  /// Phân loại cảnh báo từ nội dung tin nhắn.
  static String _inferAlertType(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('té') ||
        lower.contains('fall') ||
        lower.contains('ngã')) {
      return 'fall';
    }
    if (lower.contains('vùng an toàn') ||
        lower.contains('ngoài') ||
        lower.contains('safe zone')) {
      return 'geofence';
    }
    if (lower.contains('nhịp tim') ||
        lower.contains('spo2') ||
        lower.contains('bpm')) {
      return 'vital';
    }
    return 'manual';
  }

  /// Danh sách cảnh báo đã sắp xếp: chưa xử lý mới nhất lên đầu, sau đó đã xử lý mới nhất.
  List<AlertModel> get sortedAlerts {
    final unacked = _alerts.where((a) => !a.acknowledged).toList()
      ..sort((a, b) => b.time.compareTo(a.time));
    final acked = _alerts.where((a) => a.acknowledged).toList()
      ..sort((a, b) => b.time.compareTo(a.time));
    return [...unacked, ...acked];
  }

  /// Xác nhận đã nhận cảnh báo (Acknowledge)
  void acknowledgeAlert(String alertId) {
    // Cập nhật trạng thái trong lịch sử
    final index = _alerts.indexWhere((a) => a.id == alertId);
    if (index != -1) {
      final oldAlert = _alerts[index];
      _alerts[index] = oldAlert.copyWith(acknowledged: true, read: true);

      // Cập nhật trạng thái người già tương ứng về bình thường (safe)
      final elderly = _relatives.firstWhere((e) => e.id == oldAlert.elderlyId);
      final updatedElderly = elderly.copyWith(
        status: 'safe',
        // Chỉ xóa cờ té ngã khi đang xác nhận đúng cảnh báo té ngã, tránh
        // reset nhầm cờ do cảnh báo geofence/sinh tồn khác tự động acknowledge.
        isFallen: oldAlert.type == 'fall' ? false : elderly.isFallen,
        lastUpdated: DateTime.now(),
      );
      updateElderly(updatedElderly);
    }

    // Nếu là cảnh báo active hiện tại, xóa nó đi
    if (_activeAlert?.id == alertId) {
      _activeAlert = null;
    }
    _saveAlertHistory().catchError((e) {
      debugPrint('Lỗi lưu lịch sử sau acknowledge: $e');
    });
    notifyListeners();
  }

  /// Đánh dấu toàn bộ cảnh báo đã được mở/xem qua tab Thông báo.
  /// Giữ nguyên trạng thái `acknowledged`, chỉ xóa cờ `read` khỏi badge count.
  void markAllAlertsRead() {
    bool changed = false;
    for (int i = 0; i < _alerts.length; i++) {
      if (!_alerts[i].read) {
        _alerts[i] = _alerts[i].copyWith(read: true);
        changed = true;
      }
    }
    if (!changed) return;

    _saveAlertHistory().catchError((e) {
      debugPrint('Lỗi lưu lịch sử sau markAllAlertsRead: $e');
    });
    notifyListeners();
  }

  /// Xóa toàn bộ lịch sử cảnh báo
  void clearAlertHistory() {
    _alerts.clear();
    _saveAlertHistory().catchError((e) {
      debugPrint('Lỗi lưu lịch sử sau clear: $e');
    });
    notifyListeners();
  }

  /// Thêm cảnh báo thủ công từ form
  void addAlert(AlertModel alert) {
    _alerts.insert(0, alert);
    _saveAlertHistory().catchError((e) {
      debugPrint('Lỗi lưu lịch sử sau add alert: $e');
    });
    notifyListeners();
  }

  // --- MÔ PHỎNG DỮ LIỆU REALTIME ESP32 ---

  /// Bắt đầu Timer mô phỏng dữ liệu ESP32 cập nhật
  void startSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      final random = Random();

      // Thi thoảng mô phỏng kết nối WebSocket chập chờn
      if (random.nextInt(100) < 5) {
        _isWebSocketConnected = !_isWebSocketConnected;
        notifyListeners();
      }

      // Chỉ cập nhật dữ liệu nếu WebSocket/Realtime online
      if (!_isWebSocketConnected) return;

      for (int i = 0; i < _relatives.length; i++) {
        final elderly = _relatives[i];

        // Nếu thiết bị đang offline (hết pin), không có dữ liệu cập nhật
        if (elderly.isOffline) continue;

        // 1. Phục hồi chỉ số pin (giảm dần)
        int newBattery = elderly.battery - (random.nextInt(2) == 0 ? 1 : 0);
        if (newBattery < 0) newBattery = 0;
        bool becomeOffline = newBattery == 0;

        // 2. Dao động nhịp tim động (65 -> 95 bpm)
        int newHeart = elderly.heartRate;
        if (newHeart > 0) {
          newHeart += random.nextInt(7) - 3;
          if (newHeart < 60) newHeart = 60;
          if (newHeart > 105) newHeart = 105;
        }

        // 3. Dao động SpO2 (95% -> 100%)
        int newSpo2 = elderly.spo2;
        if (newSpo2 > 0) {
          newSpo2 += random.nextInt(3) - 1;
          if (newSpo2 < 92) newSpo2 = 92;
          if (newSpo2 > 100) newSpo2 = 100;
        }

        // 4. Mô phỏng di chuyển nhẹ (GPS)
        double newLat = elderly.latitude;
        double newLng = elderly.longitude;

        // Tỷ lệ di chuyển nhỏ (chỉ đổi tọa độ nhỏ)
        if (random.nextInt(10) < 4) {
          newLat += (random.nextDouble() - 0.5) * 0.0006;
          newLng += (random.nextDouble() - 0.5) * 0.0006;
        }

        // 5. Kiểm tra khoảng cách tới Tâm vùng an toàn để cảnh báo Geofence
        double distance = _calculateDistance(
          newLat,
          newLng,
          elderly.safeZoneLat,
          elderly.safeZoneLng,
        );
        bool isOutsideSafeZone = distance > elderly.safeZoneRadius;

        // Tính trạng thái vùng an toàn TRƯỚC khi cập nhật, dựa trên tọa độ thực tế
        // thay vì dùng elderly.status == 'critical' làm proxy (vì critical cũng có thể
        // do té ngã).
        final previousDistance = _calculateDistance(
          elderly.latitude,
          elderly.longitude,
          elderly.safeZoneLat,
          elderly.safeZoneLng,
        );
        final wasOutsideSafeZone = previousDistance > elderly.safeZoneRadius;

        // Tính trạng thái sức khỏe mới. Té ngã và cảnh báo geofence đang active
        // phải giữ critical cho đến khi người dùng xác nhận, không tự động hạ cấp.
        String newStatus = elderly.status;
        if (elderly.isFallen ||
            (_activeAlert?.elderlyId == elderly.id &&
                _activeAlert?.type == 'geofence')) {
          newStatus = 'critical';
        } else if (newHeart > 100 || newSpo2 < 93) {
          newStatus = 'warning';
        } else {
          newStatus = 'safe';
        }

        // Tạo cập nhật cho người cao tuổi
        ElderlyModel updated = elderly.copyWith(
          battery: newBattery,
          isOffline: becomeOffline,
          heartRate: becomeOffline ? 0 : newHeart,
          spo2: becomeOffline ? 0 : newSpo2,
          latitude: newLat,
          longitude: newLng,
          lastUpdated: DateTime.now(),
          status: newStatus,
        );

        _relatives[i] = updated;

        // Chỉ trigger SOS khi có sự kiện BIÊN xảy ra:
        //  - Từ trong vùng (status safe/warning) chuyển ra NGOÀI vùng an toàn
        //  - HOẶC elderly đang ở ngoài vùng an toàn nhưng vừa về trong vùng (để reset)
        // Tránh spam alert mỗi 4 giây khi người dùng đã acknowledge nhưng vẫn ở ngoài.
        if (isOutsideSafeZone && !wasOutsideSafeZone) {
          triggerSOS(
            elderly.id,
            'Ra khỏi vùng an toàn (${distance.toStringAsFixed(0)}m > ${elderly.safeZoneRadius.toStringAsFixed(0)}m)',
            'critical',
            newLat,
            newLng,
            type: 'geofence',
          );
        } else if (!isOutsideSafeZone &&
            (wasOutsideSafeZone ||
                (_activeAlert?.elderlyId == elderly.id &&
                    _activeAlert?.type == 'geofence'))) {
          // Đã quay về vùng an toàn, chỉ tự động reset active alert nếu đó là
          // cảnh báo geofence. Cảnh báo té ngã hoặc sinh tồn phải do người dùng
          // xác nhận thủ công.
          if (_activeAlert?.elderlyId == elderly.id &&
              _activeAlert?.type == 'geofence') {
            acknowledgeAlert(_activeAlert!.id);
          }
        }
      }
      notifyListeners();
    });
  }

  /// Dừng mô phỏng
  void stopSimulation() {
    _simulationTimer?.cancel();
  }

  // --- KỊCH BẢN KIỂM THỬ THỦ CÔNG (TEST SCENARIOS) ---

  /// Giả lập Sự cố té ngã (Nguy cấp)
  void simulateFall(int elderlyId) {
    final elderly = _relatives.firstWhere((e) => e.id == elderlyId);
    triggerSOS(
      elderlyId,
      'Cảnh báo: Phát hiện TÉ NGÃ (Fall Detected)!',
      'critical',
      elderly.latitude + 0.0008,
      elderly.longitude + 0.0008,
      type: 'fall',
    );
  }

  /// Giả lập Đi ra ngoài vùng an toàn (Nguy cấp)
  void simulateExitSafeZone(int elderlyId) {
    final elderly = _relatives.firstWhere((e) => e.id == elderlyId);
    // Dịch tọa độ ra xa tâm
    double newLat = elderly.safeZoneLat + 0.004;
    double newLng = elderly.safeZoneLng + 0.004;
    triggerSOS(
      elderlyId,
      'Cảnh báo: Đi ra ngoài Vùng An Toàn (> ${elderly.safeZoneRadius.toStringAsFixed(0)}m)',
      'critical',
      newLat,
      newLng,
      type: 'geofence',
    );
  }

  /// Giả lập thiết bị của người thân đang ONLINE (đeo lại, có pin, có tín hiệu).
  /// - Nếu người thân không tồn tại → bỏ qua (không throw).
  /// - Đặt lại pin về 80%, isOffline = false, khôi phục nhịp tim/SpO2 nếu đang = 0
  ///   (vì khi offline ta set các chỉ số về 0), cập nhật lastUpdated.
  /// - Trả về true nếu cập nhật thành công, false nếu elderlyId không tồn tại.
  bool simulateDeviceOnline(int elderlyId) {
    final index = _relatives.indexWhere((e) => e.id == elderlyId);
    if (index == -1) return false;

    final elderly = _relatives[index];
    final updated = elderly.copyWith(
      isOffline: false,
      battery: 80,
      heartRate: elderly.heartRate > 0 ? elderly.heartRate : 75,
      spo2: elderly.spo2 > 0 ? elderly.spo2 : 98,
      lastUpdated: DateTime.now(),
    );
    _relatives[index] = updated;
    _saveElderlyData();
    notifyListeners();
    return true;
  }

  /// Giả lập thiết bị của người thân đang OFFLINE (hết pin, mất tín hiệu).
  /// - Nếu người thân không tồn tại → bỏ qua (không throw).
  /// - Đặt pin về 0%, isOffline = true, nhịp tim/SpO2 về 0, cập nhật lastUpdated.
  /// - Trả về true nếu cập nhật thành công, false nếu elderlyId không tồn tại.
  bool simulateDeviceOffline(int elderlyId) {
    final index = _relatives.indexWhere((e) => e.id == elderlyId);
    if (index == -1) return false;

    final elderly = _relatives[index];
    final updated = elderly.copyWith(
      isOffline: true,
      battery: 0,
      heartRate: 0,
      spo2: 0,
      lastUpdated: DateTime.now(),
    );
    _relatives[index] = updated;
    _saveElderlyData();
    notifyListeners();
    return true;
  }

  /// Giả lập Nhịp tim & SpO2 bất thường (Cần lưu ý)
  void simulateHeartRateSpike(int elderlyId) {
    final elderly = _relatives.firstWhere((e) => e.id == elderlyId);
    final updated = elderly.copyWith(
      heartRate: 118,
      spo2: 91,
      status: 'warning',
      lastUpdated: DateTime.now(),
    );
    updateElderly(updated);

    // Kích hoạt alert thường
    triggerSOS(
      elderlyId,
      'Chỉ số sinh tồn bất thường (Nhịp tim: 118 bpm, SpO2: 91%)',
      'warning',
      elderly.latitude,
      elderly.longitude,
      type: 'vital',
    );
  }

  /// Công thức Haversine tính khoảng cách (mét) giữa 2 tọa độ GPS
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a =
        0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)) * 1000; // 2 * R * 1000 m
  }

  @override
  void dispose() {
    stopSimulation();
    super.dispose();
  }
}
