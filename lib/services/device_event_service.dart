import 'package:flutter/foundation.dart';

import '../utils/app_state.dart';
import 'device_event_mapper.dart';
import 'notification_service.dart';
import 'socket_io_service.dart';

/// Nhận sự kiện realtime từ SOS Care backend và chuyển thành cảnh báo / cập nhật
/// trạng thái người thân trong [AppState].
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
  bool _realMode = false;
  final Set<int> _lowBatteryNotified = {};

  /// Bắt đầu lắng nghe backend tại [url].
  ///
  /// Tự động chuyển `localhost` thành `10.0.2.2` khi chạy trên Android emulator.
  void start(String url) {
    _socket.dispose();

    _socket.on('sos:alert', _onSosAlert);
    _socket.on('event:fall', _onFall);
    _socket.on('event:heart_rate', _onHeartRateAlert);
    _socket.on('device:location', _onLocation);
    _socket.on('device:status', _onDeviceStatus);

    _socket.on('connect', (_) => AppState().setRealtimeConnection(true));
    _socket.on('disconnect', (_) => AppState().setRealtimeConnection(false));
    _socket.on('connect_error', (_) => AppState().setRealtimeConnection(false));
    _socket.on('error', (_) => AppState().setRealtimeConnection(false));

    _socket.connect(DeviceEventMapper.resolveBackendUrl(url));
  }

  /// Ngắt kết nối backend.
  void dispose() {
    _socket.dispose();
  }

  void _onSosAlert(dynamic data) {
    final payload = DeviceEventMapper.asMap(data);
    if (payload == null) return;

    _enterRealMode();
    final deviceId = DeviceEventMapper.string(payload['deviceId']);
    final elderlyId = DeviceEventMapper.resolveOrCreate(
      DeviceEventMapper.string(payload['elderlyId']),
      deviceId,
      DeviceEventMapper.doubleVal(payload['latitude']),
      DeviceEventMapper.doubleVal(payload['longitude']),
    );
    debugPrint('[DeviceEvent] sos:alert elderlyId=$elderlyId deviceId=$deviceId');

    AppState().triggerSOS(
      elderlyId,
      'SOS khẩn cấp từ thiết bị $deviceId',
      'critical',
      DeviceEventMapper.doubleVal(payload['latitude']),
      DeviceEventMapper.doubleVal(payload['longitude']),
    );

    _notifications.show(
      id: DeviceEventMapper.notificationId(elderlyId, 1000),
      title: '🚨 SOS khẩn cấp',
      body: 'Thiết bị $deviceId vừa kích hoạt SOS.',
      critical: true,
    );
  }

  void _onFall(dynamic data) {
    final payload = DeviceEventMapper.asMap(data);
    if (payload == null) return;

    _enterRealMode();
    final deviceId = DeviceEventMapper.string(payload['deviceId']);
    final elderlyId = DeviceEventMapper.resolveOrCreate(
      DeviceEventMapper.string(payload['elderlyId']),
      deviceId,
      DeviceEventMapper.doubleVal(payload['latitude']),
      DeviceEventMapper.doubleVal(payload['longitude']),
    );
    debugPrint('[DeviceEvent] fall elderlyId=$elderlyId deviceId=$deviceId');

    final elderly = AppState().relatives.firstWhere((e) => e.id == elderlyId);
    AppState().updateElderly(
      elderly.copyWith(isFallen: true, status: 'critical', lastUpdated: DateTime.now()),
    );

    AppState().triggerSOS(
      elderlyId,
      'Phát hiện TÉ NGÃ từ thiết bị $deviceId',
      'critical',
      DeviceEventMapper.doubleVal(payload['latitude']),
      DeviceEventMapper.doubleVal(payload['longitude']),
    );

    _notifications.show(
      id: DeviceEventMapper.notificationId(elderlyId, 2000),
      title: '⚠️ Phát hiện té ngã',
      body: '${elderly.name} có thể đã bị ngã.',
      critical: true,
    );
  }

  void _onHeartRateAlert(dynamic data) {
    final payload = DeviceEventMapper.asMap(data);
    if (payload == null) return;

    _enterRealMode();
    final deviceId = DeviceEventMapper.string(payload['deviceId']);
    final elderlyId = DeviceEventMapper.resolveOrCreate(
      DeviceEventMapper.string(payload['elderlyId']),
      deviceId,
      DeviceEventMapper.doubleVal(payload['latitude']),
      DeviceEventMapper.doubleVal(payload['longitude']),
    );
    debugPrint('[DeviceEvent] heart_rate elderlyId=$elderlyId deviceId=$deviceId');

    final elderly = AppState().relatives.firstWhere((e) => e.id == elderlyId);
    AppState().updateElderly(
      elderly.copyWith(status: 'warning', lastUpdated: DateTime.now()),
    );

    AppState().triggerSOS(
      elderlyId,
      'Cảnh báo nhịp tim bất thường từ thiết bị $deviceId',
      'warning',
      DeviceEventMapper.doubleVal(payload['latitude']),
      DeviceEventMapper.doubleVal(payload['longitude']),
    );

    _notifications.show(
      id: DeviceEventMapper.notificationId(elderlyId, 3000),
      title: '💓 Nhịp tim bất thường',
      body: 'Thiết bị $deviceId báo nhịp tim cao.',
    );
  }

  void _onLocation(dynamic data) {
    final payload = DeviceEventMapper.asMap(data);
    if (payload == null) return;

    _enterRealMode();
    final elderlyId = DeviceEventMapper.resolveOrCreate(
      DeviceEventMapper.string(payload['elderlyId']),
      DeviceEventMapper.string(payload['deviceId']),
      DeviceEventMapper.doubleVal(payload['latitude']),
      DeviceEventMapper.doubleVal(payload['longitude']),
    );
    debugPrint('[DeviceEvent] location elderlyId=$elderlyId lat=${DeviceEventMapper.doubleVal(payload['latitude'])} lng=${DeviceEventMapper.doubleVal(payload['longitude'])}');

    final elderly = AppState().relatives.firstWhere((e) => e.id == elderlyId);
    AppState().updateElderly(
      elderly.copyWith(
        latitude: DeviceEventMapper.doubleVal(payload['latitude']),
        longitude: DeviceEventMapper.doubleVal(payload['longitude']),
        lastUpdated: DateTime.now(),
      ),
    );
  }

  void _onDeviceStatus(dynamic data) {
    final payload = DeviceEventMapper.asMap(data);
    if (payload == null) return;

    _enterRealMode();
    final elderlyId = DeviceEventMapper.resolveOrCreate(
      DeviceEventMapper.string(payload['elderlyId']),
      DeviceEventMapper.string(payload['deviceId']),
      0.0,
      0.0,
    );

    final elderly = AppState().relatives.firstWhere((e) => e.id == elderlyId);
    final battery = DeviceEventMapper.intVal(payload['batteryPercent']);
    final heartRate = DeviceEventMapper.intVal(payload['heartRateBpm']);
    final isOnline = DeviceEventMapper.boolVal(payload['isOnline']);
    debugPrint('[DeviceEvent] status elderlyId=$elderlyId battery=$battery heartRate=$heartRate isOnline=$isOnline');

    AppState().updateElderly(
      elderly.copyWith(
        battery: battery,
        heartRate: heartRate > 0 ? heartRate : elderly.heartRate,
        isOffline: !isOnline,
        lastUpdated: DateTime.now(),
      ),
    );

    if (battery <= 20 && battery >= 0 && !_lowBatteryNotified.contains(elderlyId)) {
      _lowBatteryNotified.add(elderlyId);
      _notifications.show(
        id: DeviceEventMapper.notificationId(elderlyId, 4000),
        title: '🔋 Pin thiết bị thấp',
        body: '${elderly.name}: pin còn $battery%',
      );
    } else if (battery > 20) {
      _lowBatteryNotified.remove(elderlyId);
    }
  }

  void _enterRealMode() {
    if (_realMode) return;
    _realMode = true;
    AppState().setRealtimeConnection(true);
    AppState().stopSimulation();
    debugPrint('[DeviceEvent] real mode active, local simulation stopped');
  }
}
