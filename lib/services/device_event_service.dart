import 'package:flutter/foundation.dart';

import '../models/alert_model.dart';
import '../models/elderly_model.dart';
import '../utils/app_state.dart';
import 'device_event_mapper.dart';
import 'notification_service.dart';
import 'socket_io_service.dart';

/// Nhận sự kiện realtime từ SOS Care backend (Socket.IO) và cập nhật
/// [AppState]: cảnh báo (sos/fall/vital/geofence) → upsertAlert; telemetry
/// (location/status) → patch vitals. Backend đã augment payload với
/// `relativeId` (int, = ElderlyModel.id) và `alertId` (int) — không còn
/// tra cứu/giả lập phía client.
class DeviceEventService {
  static final DeviceEventService _instance = DeviceEventService._internal();
  factory DeviceEventService() => _instance;
  DeviceEventService._internal({
    SocketIoService? socket,
    NotificationService? notifications,
  })  : _socket = socket ?? SocketIoService(),
        _notifications = notifications ?? NotificationService();

  final SocketIoService _socket;
  final NotificationService _notifications;
  final Set<int> _lowBatteryNotified = {};
  String? _url;

  /// Bắt đầu lắng nghe backend tại [url] (tự đổi localhost→10.0.2.2 trên Android).
  /// Kết nối lúc đầu CHƯA có JWT → backend cho connect nhưng chưa join room.
  void start(String url) {
    _url = url;
    // Tránh đăng ký trùng khi start() gọi lại.
    for (final e in const [
      'sos:alert',
      'event:fall',
      'event:heart_rate',
      'geofence:alert',
      'device:location',
      'device:status',
      'connect',
      'disconnect',
      'connect_error',
      'error',
    ]) {
      _socket.off(e);
    }

    _socket.on('sos:alert', _onSosAlert);
    _socket.on('event:fall', _onFall);
    _socket.on('event:heart_rate', _onHeartRateAlert);
    _socket.on('geofence:alert', _onGeofence);
    _socket.on('device:location', _onLocation);
    _socket.on('device:status', _onDeviceStatus);

    _socket.on('connect', (_) => AppState().setRealtimeConnection(true));
    _socket.on('disconnect', (_) => AppState().setRealtimeConnection(false));
    _socket.on('connect_error', (_) => AppState().setRealtimeConnection(false));
    _socket.on('error', (_) => AppState().setRealtimeConnection(false));

    _connect(null);
  }

  /// Kết nối lại socket với JWT (sau đăng nhập) để backend join room `user:<id>`.
  /// Truyền `null` (đăng xuất) → kết nối lại không auth, rời room.
  void reauthenticate(String? token) {
    if (_url == null) return;
    _connect(token);
  }

  void _connect(String? token) {
    _socket.connect(DeviceEventMapper.resolveBackendUrl(_url!), token: token);
  }

  void dispose() => _socket.dispose();

  // --- Cảnh báo (alert) từ thiết bị: build AlertModel → upsertAlert ---

  void _onSosAlert(dynamic data) {
    final p = DeviceEventMapper.asMap(data);
    if (p == null) return;
    _emitAlert(
      relativeId: DeviceEventMapper.intVal(p['relativeId']),
      alertId: DeviceEventMapper.string(p['alertId']),
      type: 'sos',
      urgency: 'critical',
      message: _orDefault(p['message'], 'SOS khẩn cấp'),
      lat: DeviceEventMapper.doubleVal(p['latitude']),
      lng: DeviceEventMapper.doubleVal(p['longitude']),
      timestamp: p['timestamp'],
      notifyTitle: '🚨 SOS khẩn cấp',
      notifyBody:
          'Thiết bị ${DeviceEventMapper.string(p['deviceId'])} vừa kích hoạt SOS.',
    );
  }

  void _onFall(dynamic data) {
    final p = DeviceEventMapper.asMap(data);
    if (p == null) return;
    _emitAlert(
      relativeId: DeviceEventMapper.intVal(p['relativeId']),
      alertId: DeviceEventMapper.string(p['alertId']),
      type: 'fall',
      urgency: 'critical',
      message: _orDefault(p['message'], 'Phát hiện té ngã'),
      lat: DeviceEventMapper.doubleVal(p['latitude']),
      lng: DeviceEventMapper.doubleVal(p['longitude']),
      timestamp: p['timestamp'],
      notifyTitle: '⚠️ Phát hiện té ngã',
      notifyBody: _orDefault(p['message'], 'Có thể đã bị ngã.'),
    );
  }

  void _onHeartRateAlert(dynamic data) {
    final p = DeviceEventMapper.asMap(data);
    if (p == null) return;
    _emitAlert(
      relativeId: DeviceEventMapper.intVal(p['relativeId']),
      alertId: DeviceEventMapper.string(p['alertId']),
      type: 'vital',
      urgency: 'warning',
      message: _orDefault(p['message'], 'Nhịp tim bất thường'),
      lat: DeviceEventMapper.doubleVal(p['latitude']),
      lng: DeviceEventMapper.doubleVal(p['longitude']),
      timestamp: p['timestamp'],
      notifyTitle: '💓 Nhịp tim bất thường',
      notifyBody: _orDefault(p['message'], 'Thiết bị báo nhịp tim bất thường.'),
    );
  }

  void _onGeofence(dynamic data) {
    final p = DeviceEventMapper.asMap(data);
    if (p == null) return;
    _emitAlert(
      relativeId: DeviceEventMapper.intVal(p['relativeId']),
      alertId: DeviceEventMapper.string(p['alertId']),
      type: 'geofence',
      urgency: 'critical',
      message: _orDefault(p['message'], 'Vượt vùng an toàn'),
      lat: DeviceEventMapper.doubleVal(p['latitude']),
      lng: DeviceEventMapper.doubleVal(p['longitude']),
      timestamp: p['timestamp'],
      notifyTitle: '📍 Vượt vùng an toàn',
      notifyBody: _orDefault(p['message'], 'Đã ra khỏi vùng an toàn.'),
    );
  }

  void _emitAlert({
    required int relativeId,
    required String alertId,
    required String type,
    required String urgency,
    required String message,
    required double lat,
    required double lng,
    required dynamic timestamp,
    required String notifyTitle,
    required String notifyBody,
  }) {
    if (alertId.isEmpty) return;
    final elderly = _findRelative(relativeId);
    AppState().upsertAlert(AlertModel(
      id: alertId,
      elderlyId: relativeId,
      elderlyName: elderly?.name ?? '',
      time: _parseTime(timestamp),
      locationName: '',
      urgency: urgency,
      message: message,
      acknowledged: false,
      read: false,
      type: type,
      latitude: lat,
      longitude: lng,
    ));
    _notifications.show(
      id: DeviceEventMapper.notificationId(relativeId, _notifyBase(type)),
      title: notifyTitle,
      body: notifyBody,
      critical: urgency == 'critical',
    );
    debugPrint('[DeviceEvent] $type relativeId=$relativeId alertId=$alertId');
  }

  // --- Telemetry: patch vitals in-memory ---

  void _onLocation(dynamic data) {
    final p = DeviceEventMapper.asMap(data);
    if (p == null) return;
    final elderly = _findRelative(
      DeviceEventMapper.intVal(p['relativeId']),
      deviceCode: DeviceEventMapper.string(p['elderlyId']),
    );
    if (elderly == null) {
      debugPrint(
        '[DeviceEvent] device:location dropped — no relative for device '
        '${p['elderlyId']} (relativeId=${p['relativeId']}); add a relative '
        'with this device code to receive realtime location.',
      );
      return;
    }
    AppState().patchElderlyVitals(
      elderly.copyWith(
        latitude: DeviceEventMapper.doubleVal(p['latitude']),
        longitude: DeviceEventMapper.doubleVal(p['longitude']),
        lastUpdated: _parseTime(p['timestamp']),
      ),
    );
  }

  void _onDeviceStatus(dynamic data) {
    final p = DeviceEventMapper.asMap(data);
    if (p == null) return;
    final relativeId = DeviceEventMapper.intVal(p['relativeId']);
    final elderly = _findRelative(
      relativeId,
      deviceCode: DeviceEventMapper.string(p['elderlyId']),
    );
    if (elderly == null) {
      debugPrint(
        '[DeviceEvent] device:status dropped — no relative for device '
        '${p['elderlyId']} (relativeId=$relativeId); add a relative with '
        'this device code to receive realtime status.',
      );
      return;
    }
    final battery = DeviceEventMapper.intVal(p['batteryPercent']);
    final heartRate = DeviceEventMapper.intVal(p['heartRateBpm']);
    final spo2 = DeviceEventMapper.intVal(p['spo2Percent']);
    final isOnline = DeviceEventMapper.boolVal(p['isOnline']);
    AppState().patchElderlyVitals(
      elderly.copyWith(
        battery: battery,
        heartRate: heartRate > 0 ? heartRate : elderly.heartRate,
        spo2: spo2 > 0 ? spo2 : elderly.spo2,
        isOffline: !isOnline,
        lastUpdated: _parseTime(p['timestamp']),
      ),
    );
    if (battery >= 0 && battery <= 20 && !_lowBatteryNotified.contains(relativeId)) {
      _lowBatteryNotified.add(relativeId);
      _notifications.show(
        id: DeviceEventMapper.notificationId(relativeId, 4000),
        title: '🔋 Pin thiết bị thấp',
        body: '${elderly.name}: pin còn $battery%',
      );
    } else if (battery > 20) {
      _lowBatteryNotified.remove(relativeId);
    }
  }

  // --- Helpers ---

  ElderlyModel? _findRelative(int relativeId, {String? deviceCode}) {
    if (relativeId != 0) {
      final idx = AppState().relatives.indexWhere((e) => e.id == relativeId);
      if (idx >= 0) return AppState().relatives[idx];
    }
    // Fallback: match by wearable device code (deviceElderlyId) for telemetry
    // arriving before the backend has linked the device to a relative, or when
    // relativeId is absent (global broadcast for an unpaired device). Lets the
    // caregiver see realtime updates as soon as they add a relative with the
    // matching device code, instead of dropping the event silently.
    if (deviceCode != null && deviceCode.isNotEmpty) {
      final idx = AppState().relatives.indexWhere(
        (e) => e.wearableDevice == deviceCode,
      );
      if (idx >= 0) return AppState().relatives[idx];
    }
    return null;
  }

  DateTime _parseTime(dynamic ts) {
    if (ts == null || ts.toString().isEmpty) return DateTime.now();
    return DateTime.tryParse(ts.toString())?.toLocal() ?? DateTime.now();
  }

  String _orDefault(dynamic value, String fallback) {
    final s = DeviceEventMapper.string(value);
    return s.isEmpty ? fallback : s;
  }

  int _notifyBase(String type) {
    switch (type) {
      case 'sos':
        return 1000;
      case 'fall':
        return 2000;
      case 'vital':
        return 3000;
      case 'geofence':
        return 5000;
      default:
        return 9000;
    }
  }
}