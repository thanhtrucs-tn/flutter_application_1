import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/alert_model.dart';
import '../models/app_settings.dart';
import '../models/elderly_model.dart';
import '../models/user_profile.dart';
import '../services/alerts_api_service.dart';
import '../services/auth_service.dart';
import '../services/relatives_api_service.dart';
import '../services/token_storage.dart';
import 'localization.dart';

/// Trạng thái toàn cục của ứng dụng. Dữ liệu người thân + cảnh báo được tải từ
/// backend (REST/JWT) và cập nhật realtime qua Socket.IO. Không còn mock hay
/// mô phỏng — khi chưa kết nối thiết bị, UI hiển thị trạng thái rỗng/0.
class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal() {
    _loadSettings();
  }

  List<ElderlyModel> _relatives = [];
  List<AlertModel> _alerts = [];
  AppSettings _settings = AppSettings.defaultSettings();
  UserProfile _userProfile = UserProfile.defaultProfile();
  AlertModel? _activeAlert;
  bool _isWebSocketConnected = false;
  int _currentNavIndex = 0;
  String? _currentAccountId;

  List<ElderlyModel> get relatives => _relatives;
  List<AlertModel> get alerts => _alerts;
  AppSettings get settings => _settings;
  UserProfile get userProfile => _userProfile;
  AlertModel? get activeAlert => _activeAlert;
  bool get isWebSocketConnected => _isWebSocketConnected;
  int get currentNavIndex => _currentNavIndex;
  String? get currentAccountId => _currentAccountId;
  bool get isAuthenticated => _currentAccountId != null;

  int get alertBadgeCount =>
      _alerts.where((a) => !a.read || !a.acknowledged).length;

  void setNavIndex(int index) {
    _currentNavIndex = index;
    notifyListeners();
  }

  void setRealtimeConnection(bool connected) {
    _isWebSocketConnected = connected;
    notifyListeners();
  }

  // --- CÀI ĐẶT (AppSettings lưu trong SharedPreferences) ---

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('app_settings');
    if (jsonStr != null) {
      try {
        _settings = AppSettings.fromMap(json.decode(jsonStr) as Map<String, dynamic>);
        Localization.currentLanguage = _settings.languageCode;
      } catch (e) {
        debugPrint('Lỗi đọc settings: $e');
      }
    }
    notifyListeners();
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    _settings = newSettings;
    Localization.currentLanguage = _settings.languageCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_settings', json.encode(_settings.toMap()));
    notifyListeners();
  }

  Future<void> toggleDarkMode(bool enabled) =>
      updateSettings(_settings.copyWith(isDarkMode: enabled));

  Future<void> toggleLanguage(String langCode) =>
      updateSettings(_settings.copyWith(languageCode: langCode));

  // --- TÀI KHOẢN & HỒ SƠ ---

  /// Đặt tài khoản sau đăng nhập: lưu JWT, set profile, tải relatives + alerts.
  Future<void> setCurrentAccount(UserProfile profile, String token) async {
    await TokenStorage.saveToken(token);
    _currentAccountId = profile.email;
    _userProfile = profile;
    await _loadAvatarLocalPath();
    _activeAlert = null;
    await reloadRelatives();
    await reloadAlerts();
    notifyListeners();
  }

  /// Đăng xuất: xóa JWT, reset danh sách về rỗng (không dùng mock default).
  Future<void> logout() async {
    await TokenStorage.clearToken();
    _currentAccountId = null;
    _currentNavIndex = 0;
    _activeAlert = null;
    _userProfile = UserProfile.defaultProfile();
    _relatives = [];
    _alerts = [];
    notifyListeners();
  }

  /// Cập nhật hồ sơ (name/phone/avatarUrl) lên server. Email không sửa được.
  Future<bool> updateUserProfile(UserProfile updated) async {
    if (updated.name.trim().isEmpty) return false;
    try {
      final profile = await AuthService.instance.updateProfile(
        name: updated.name,
        phone: updated.phone,
        avatarUrl: updated.avatarUrl.isNotEmpty ? updated.avatarUrl : null,
      );
      _userProfile = profile.copyWith(avatarLocalPath: updated.avatarLocalPath);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Lỗi cập nhật profile: $e');
      return false;
    }
  }

  /// Cập nhật đường dẫn ảnh đại diện local (lưu trong SharedPreferences).
  Future<bool> updateUserAvatarLocalPath(String path) async {
    if (path.isEmpty) return false;
    _userProfile = _userProfile.copyWith(avatarLocalPath: path);
    final p = await SharedPreferences.getInstance();
    await p.setString(_userAvatarLocalKey, path);
    notifyListeners();
    return true;
  }

  static const _userAvatarLocalKey = 'user_avatar_local';

  Future<void> _loadAvatarLocalPath() async {
    final p = await SharedPreferences.getInstance();
    final path = p.getString(_userAvatarLocalKey);
    if (path != null && path.isNotEmpty) {
      _userProfile = _userProfile.copyWith(avatarLocalPath: path);
    }
  }

  // --- NGƯỜI THÂN (relatives) ---

  Future<void> reloadRelatives() async {
    try {
      _relatives = await RelativesApiService.instance.list();
      await _applyRelAvatarCache();
      _recomputeStatus();
    } catch (e) {
      debugPrint('Lỗi tải relatives: $e');
      _relatives = [];
    }
    notifyListeners();
  }

  /// Thêm người thân mới (POST /api/relatives).
  Future<void> addElderly(ElderlyModel newRelative) async {
    final created = await RelativesApiService.instance.create(newRelative);
    _relatives.add(created);
    _recomputeStatus();
    notifyListeners();
  }

  /// Cập nhật profile người thân (PUT /api/relatives/:id) — dùng cho sửa tên,
  /// vùng an toàn, contacts, avatar URL. Giữ vitals realtime + avatar local.
  Future<void> updateElderly(ElderlyModel updated) async {
    final saved = await RelativesApiService.instance.update(updated);
    final idx = _relatives.indexWhere((e) => e.id == updated.id);
    if (idx >= 0) {
      _relatives[idx] = saved.copyWith(
        avatarLocalPath: _relatives[idx].avatarLocalPath,
        battery: _relatives[idx].battery,
        heartRate: _relatives[idx].heartRate,
        spo2: _relatives[idx].spo2,
        isOffline: _relatives[idx].isOffline,
        latitude: _relatives[idx].latitude,
        longitude: _relatives[idx].longitude,
        lastUpdated: _relatives[idx].lastUpdated,
      );
    }
    _recomputeStatus();
    notifyListeners();
  }

  /// Patch vitals realtime từ Socket.IO (chỉ in-memory, không gọi API).
  void patchElderlyVitals(ElderlyModel updated) {
    final idx = _relatives.indexWhere((e) => e.id == updated.id);
    if (idx < 0) return;
    _relatives[idx] = updated;
    _recomputeStatus();
    notifyListeners();
  }

  /// Đặt ảnh đại diện local cho 1 relative (cache trong SharedPreferences).
  Future<bool> patchElderlyLocalAvatar(int id, String path) async {
    if (path.isEmpty) return false;
    final idx = _relatives.indexWhere((e) => e.id == id);
    if (idx < 0) return false;
    _relatives[idx] = _relatives[idx].copyWith(avatarLocalPath: path);
    final p = await SharedPreferences.getInstance();
    await p.setString('rel_avatar_local_$id', path);
    notifyListeners();
    return true;
  }

  /// Xóa người thân (DELETE /api/relatives/:id) + dọn alert liên quan.
  Future<bool> deleteElderly(int id) async {
    final idx = _relatives.indexWhere((e) => e.id == id);
    if (idx == -1) return false;
    try {
      await RelativesApiService.instance.remove(id);
    } catch (e) {
      debugPrint('Lỗi xóa relative: $e');
      return false;
    }
    _relatives.removeAt(idx);
    _alerts.removeWhere((a) => a.elderlyId == id);
    if (_activeAlert?.elderlyId == id) _activeAlert = null;
    final p = await SharedPreferences.getInstance();
    await p.remove('rel_avatar_local_$id');
    _recomputeStatus();
    notifyListeners();
    return true;
  }

  /// Sắp xếp lại thứ tự người thân (in-memory; không có trường order trên server).
  void reorderRelatives(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _relatives.length) return;
    if (newIndex < 0 || newIndex > _relatives.length) return;
    if (oldIndex == newIndex) return;
    final moved = _relatives.removeAt(oldIndex);
    _relatives.insert(newIndex, moved);
    notifyListeners();
  }

  Future<void> _applyRelAvatarCache() async {
    final p = await SharedPreferences.getInstance();
    for (int i = 0; i < _relatives.length; i++) {
      final path = p.getString('rel_avatar_local_${_relatives[i].id}');
      if (path != null && path.isNotEmpty && _relatives[i].avatarLocalPath.isEmpty) {
        _relatives[i] = _relatives[i].copyWith(avatarLocalPath: path);
      }
    }
  }

  // --- CẢNH BÁO (alerts) ---

  Future<void> reloadAlerts() async {
    try {
      _alerts = await AlertsApiService.instance.list();
      _fillAlertNames();
      _alerts.sort((a, b) => b.time.compareTo(a.time));
      _recomputeStatus();
    } catch (e) {
      debugPrint('Lỗi tải alerts: $e');
      _alerts = [];
    }
    notifyListeners();
  }

  /// Điền tên người thân cho alert (backend không trả elderlyName).
  void _fillAlertNames() {
    for (int i = 0; i < _alerts.length; i++) {
      if (_alerts[i].elderlyName.isEmpty) {
        _alerts[i] = _alerts[i].copyWith(elderlyName: _nameFor(_alerts[i].elderlyId));
      }
    }
  }

  String _nameFor(int elderlyId) {
    final i = _relatives.indexWhere((e) => e.id == elderlyId);
    return i >= 0 ? _relatives[i].name : '';
  }

  /// Chèn/cập nhật alert trong bộ nhớ (từ Socket.IO hoặc sau khi POST manual).
  void upsertAlert(AlertModel alert) {
    final idx = _alerts.indexWhere((a) => a.id == alert.id);
    if (idx >= 0) {
      _alerts[idx] = alert;
    } else {
      _alerts.insert(0, alert);
    }
    _alerts.sort((a, b) => b.time.compareTo(a.time));
    if (alert.urgency == 'critical' && !alert.acknowledged) {
      _activeAlert = alert;
    } else if (_activeAlert?.id == alert.id && alert.acknowledged) {
      _activeAlert = null;
    }
    _recomputeStatus();
    notifyListeners();
  }

  /// Xác nhận alert (PATCH /api/alerts/:id/acknowledge).
  Future<void> acknowledgeAlert(String alertId) async {
    await AlertsApiService.instance.acknowledge(alertId);
    final idx = _alerts.indexWhere((a) => a.id == alertId);
    if (idx >= 0) {
      _alerts[idx] = _alerts[idx].copyWith(acknowledged: true, read: true);
    }
    if (_activeAlert?.id == alertId) _activeAlert = null;
    _recomputeStatus();
    notifyListeners();
  }

  /// Đánh dấu toàn bộ alert đã đọc (POST /api/alerts/mark-all-read).
  Future<void> markAllAlertsRead() async {
    await AlertsApiService.instance.markAllRead();
    for (int i = 0; i < _alerts.length; i++) {
      if (!_alerts[i].read) _alerts[i] = _alerts[i].copyWith(read: true);
    }
    notifyListeners();
  }

  /// Kích hoạt SOS thủ công (POST /api/alerts type=sos).
  Future<void> triggerSOS(
    int elderlyId,
    String message,
    String urgency,
    double lat,
    double lng, {
    String? type,
  }) async {
    final alert = await AlertsApiService.instance.createManual(
      relativeId: elderlyId,
      message: message,
      urgency: urgency,
      type: type ?? 'sos',
      latitude: lat,
      longitude: lng,
    );
    upsertAlert(alert.copyWith(elderlyName: _nameFor(elderlyId)));
  }

  /// Thêm cảnh báo thủ công từ form (POST /api/alerts).
  Future<void> addAlert(AlertModel alert) async {
    final created = await AlertsApiService.instance.createManual(
      relativeId: alert.elderlyId,
      message: alert.message,
      urgency: alert.urgency,
      type: alert.type,
      locationName: alert.locationName.isNotEmpty ? alert.locationName : null,
      latitude: alert.latitude,
      longitude: alert.longitude,
    );
    upsertAlert(created.copyWith(elderlyName: _nameFor(alert.elderlyId)));
  }

  List<AlertModel> get sortedAlerts {
    final unacked = _alerts.where((a) => !a.acknowledged).toList()
      ..sort((a, b) => b.time.compareTo(a.time));
    final acked = _alerts.where((a) => a.acknowledged).toList()
      ..sort((a, b) => b.time.compareTo(a.time));
    return [...unacked, ...acked];
  }

  // --- RECOMPUTE trạng thái (safe/warning/critical) + isFallen từ alert thật ---

  void _recomputeStatus() {
    for (int i = 0; i < _relatives.length; i++) {
      final e = _relatives[i];
      final relAlerts = _alerts.where((a) => a.elderlyId == e.id).toList();
      final hasUnackedCritical = relAlerts.any((a) =>
          !a.acknowledged &&
          (a.type == 'sos' || a.type == 'fall' || a.type == 'geofence'));
      final hasUnackedFall =
          relAlerts.any((a) => a.type == 'fall' && !a.acknowledged);
      String status;
      if (hasUnackedCritical) {
        status = 'critical';
      } else if ((e.heartRate > 0 && e.heartRate > 100) ||
          (e.spo2 > 0 && e.spo2 < 93)) {
        status = 'warning';
      } else {
        status = 'safe';
      }
      if (e.status != status || e.isFallen != hasUnackedFall) {
        _relatives[i] = e.copyWith(status: status, isFallen: hasUnackedFall);
      }
    }
  }
}