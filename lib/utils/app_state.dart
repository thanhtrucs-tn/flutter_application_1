import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool _isWebSocketConnected = true; // Trạng thái kết nối realtime với ESP32/Backend
  Timer? _simulationTimer;
  int _currentNavIndex = 0; // Chỉ số tab bottom navigation hiện tại

  // Getters
  List<ElderlyModel> get relatives => _relatives;
  List<AlertModel> get alerts => _alerts;
  AppSettings get settings => _settings;
  UserProfile get userProfile => _userProfile;
  AlertModel? get activeAlert => _activeAlert;
  bool get isWebSocketConnected => _isWebSocketConnected;
  int get currentNavIndex => _currentNavIndex;

  /// Đổi tab bottom navigation
  void setNavIndex(int index) {
    _currentNavIndex = index;
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

  /// Khóa lưu trữ hồ sơ người dùng offline
  static const String _offlineUserProfileKey = 'offline_user_profile_v1';

  /// Tải hồ sơ người dùng từ SharedPreferences
  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_offlineUserProfileKey);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final map = json.decode(jsonStr) as Map<String, dynamic>;
        _userProfile = UserProfile.fromMap(map);
      } catch (e) {
        print('Lỗi đọc user profile: $e');
        _userProfile = UserProfile.defaultProfile();
      }
    } else {
      _userProfile = UserProfile.defaultProfile();
    }
    notifyListeners();
  }

  /// Lưu hồ sơ người dùng xuống SharedPreferences
  Future<void> _saveUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _offlineUserProfileKey,
      json.encode(_userProfile.toMap()),
    );
  }

  /// Cập nhật thông tin hồ sơ người dùng (validate trước khi gọi)
  Future<bool> updateUserProfile(UserProfile updated) async {
    print('[DEBUG] updateUserProfile được gọi với: name="${updated.name}", email="${updated.email}", phone="${updated.phone}"');
    if (updated.name.trim().isEmpty) {
      print('[DEBUG] updateUserProfile FAIL: name rỗng ("${updated.name}")');
      return false;
    }
    if (updated.email.trim().isEmpty) {
      print('[DEBUG] updateUserProfile FAIL: email rỗng ("${updated.email}")');
      return false;
    }
    if (updated.email.trim().length > 48) {
      print('[DEBUG] updateUserProfile FAIL: email dài ${updated.email.trim().length} ký tự > 48 ("${updated.email}")');
      return false;
    }
    if (!RegExp(r'^[0-9]{10}$').hasMatch(updated.phone.trim())) {
      print('[DEBUG] updateUserProfile FAIL: phone sai format ("${updated.phone}", length=${updated.phone.trim().length})');
      return false;
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

  /// Khóa lưu trữ danh sách người thân offline
  /// v2: thêm trường address (địa chỉ chữ)
  static const String _offlineElderlyKey = 'offline_elderly_v2';

  Future<void> _loadElderlyData() async {
    final prefs = await SharedPreferences.getInstance();
    // Xóa cache cũ (v1) để buộc load lại từ MockData mới có address
    await prefs.remove('offline_elderly_v1');
    final jsonStr = prefs.getString(_offlineElderlyKey);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final decoded = json.decode(jsonStr) as List<dynamic>;
        _relatives = decoded
            .map((e) => ElderlyModel.fromMap(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        print('Lỗi đọc elderly data: $e');
        _relatives = List.from(MockData.initialElderly);
      }
    } else {
      _relatives = List.from(MockData.initialElderly);
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

  /// Lưu danh sách người thân xuống SharedPreferences
  Future<void> _saveElderlyData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _relatives.map((e) => e.toMap()).toList();
    await prefs.setString(_offlineElderlyKey, json.encode(data));
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

  // --- QUẢN LÝ CẢNH BÁO SOS ---

  Future<void> _loadAlertHistory() async {
    _alerts = List.from(MockData.initialAlerts);
    // Sắp xếp cảnh báo gần nhất lên đầu
    _alerts.sort((a, b) => b.time.compareTo(a.time));
    notifyListeners();
  }

  /// Kích hoạt cảnh báo SOS mới
  void triggerSOS(int elderlyId, String message, String urgency, double lat, double lng) {
    final elderly = _relatives.firstWhere((e) => e.id == elderlyId);
    
    // Cập nhật trạng thái người cao tuổi thành warning/critical
    final updatedElderly = elderly.copyWith(
      status: urgency == 'critical' ? 'critical' : 'warning',
      lastUpdated: DateTime.now(),
      latitude: lat,
      longitude: lng,
      isFallen: message.contains('Té') || message.toLowerCase().contains('fall'),
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
      latitude: lat,
      longitude: lng,
    );

    // Thêm vào danh sách lịch sử
    _alerts.insert(0, newAlert);
    
    // Đặt làm cảnh báo khẩn cấp đang kích hoạt (để bật popup cảnh báo đẩy)
    if (urgency == 'critical') {
      _activeAlert = newAlert;
    }
    
    notifyListeners();
  }

  /// Xác nhận đã nhận cảnh báo (Acknowledge)
  void acknowledgeAlert(String alertId) {
    // Cập nhật trạng thái trong lịch sử
    final index = _alerts.indexWhere((a) => a.id == alertId);
    if (index != -1) {
      final oldAlert = _alerts[index];
      _alerts[index] = oldAlert.copyWith(acknowledged: true);

      // Cập nhật trạng thái người già tương ứng về bình thường (safe)
      final elderly = _relatives.firstWhere((e) => e.id == oldAlert.elderlyId);
      final updatedElderly = elderly.copyWith(
        status: 'safe',
        isFallen: false,
        lastUpdated: DateTime.now(),
      );
      updateElderly(updatedElderly);
    }

    // Nếu là cảnh báo active hiện tại, xóa nó đi
    if (_activeAlert?.id == alertId) {
      _activeAlert = null;
    }
    notifyListeners();
  }

  /// Xóa toàn bộ lịch sử cảnh báo
  void clearAlertHistory() {
    _alerts.clear();
    notifyListeners();
  }

  /// Thêm cảnh báo thủ công từ form
  void addAlert(AlertModel alert) {
    _alerts.insert(0, alert);
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
        double distance = _calculateDistance(newLat, newLng, elderly.safeZoneLat, elderly.safeZoneLng);
        bool isOutsideSafeZone = distance > elderly.safeZoneRadius;

        String newStatus = 'safe';
        if (elderly.isFallen || newHeart > 100 || newSpo2 < 93) {
          newStatus = 'warning';
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
        //  - HOẶC elderly đang ở critical nhưng vừa về trong vùng (để reset)
        // Tránh spam alert mỗi 4 giây khi người dùng đã acknowledge nhưng vẫn ở ngoài.
        final wasOutside = elderly.status == 'critical'; // trước đó đã ở ngoài
        if (isOutsideSafeZone && !wasOutside) {
          triggerSOS(
            elderly.id,
            'Ra khỏi vùng an toàn (${distance.toStringAsFixed(0)}m > ${elderly.safeZoneRadius.toStringAsFixed(0)}m)',
            'critical',
            newLat,
            newLng,
          );
        } else if (!isOutsideSafeZone && wasOutside) {
          // Đã quay về vùng an toàn, tự động reset active alert
          if (_activeAlert?.elderlyId == elderly.id) {
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
    );
  }

  /// Công thức Haversine tính khoảng cách (mét) giữa 2 tọa độ GPS
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 - cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) *
            (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)) * 1000; // 2 * R * 1000 m
  }

  @override
  void dispose() {
    stopSimulation();
    super.dispose();
  }
}
