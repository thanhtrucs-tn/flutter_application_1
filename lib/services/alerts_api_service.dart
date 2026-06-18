import 'api_client.dart';
import '../models/alert_model.dart';

/// Gọi các endpoint /api/alerts (list/acknowledge/read/mark-all-read/manual).
///
/// Backend trả về alert row; service map → [AlertModel]. `elderlyName` để trống
/// (AppState sẽ điền từ relatives theo relativeId) cho list, và DeviceEventService
/// điền cho alert từ Socket.IO.
class AlertsApiService {
  AlertsApiService._();
  static final AlertsApiService instance = AlertsApiService._();

  Future<List<AlertModel>> list() async {
    final data = await ApiClient.instance.get('/api/alerts');
    final list = (data as List?) ?? const [];
    return list.map((e) => _toAlert(e as Map<String, dynamic>)).toList();
  }

  Future<void> acknowledge(String alertId) async {
    await ApiClient.instance.patch('/api/alerts/$alertId/acknowledge');
  }

  Future<void> markRead(String alertId) async {
    await ApiClient.instance.patch('/api/alerts/$alertId/read');
  }

  Future<void> markAllRead() async {
    await ApiClient.instance.post('/api/alerts/mark-all-read');
  }

  /// Tạo cảnh báo thủ công (từ form SOS/cảnh báo trong app).
  Future<AlertModel> createManual({
    int? relativeId,
    required String message,
    String urgency = 'warning',
    String type = 'manual',
    String? locationName,
    double? latitude,
    double? longitude,
  }) async {
    final body = <String, dynamic>{
      'message': message,
      'urgency': urgency,
      'type': type,
    };
    if (relativeId != null) body['relativeId'] = relativeId;
    if (locationName != null) body['locationName'] = locationName;
    if (latitude != null) body['latitude'] = latitude;
    if (longitude != null) body['longitude'] = longitude;
    final data = await ApiClient.instance.post('/api/alerts', body: body)
        as Map<String, dynamic>;
    return _toAlert(data);
  }

  AlertModel _toAlert(Map<String, dynamic> d) {
    return AlertModel(
      id: (d['id'] ?? '').toString(),
      elderlyId: (d['relativeId'] as num?)?.toInt() ?? 0,
      elderlyName: '',
      time: DateTime.parse((d['timestamp'] ?? DateTime.now()).toString()).toLocal(),
      locationName: (d['locationName'] as String?) ?? '',
      urgency: (d['urgency'] as String?) ?? 'warning',
      message: (d['message'] as String?) ?? '',
      acknowledged: _boolVal(d['acknowledged']),
      read: _boolVal(d['read']),
      type: (d['type'] as String?) ?? 'manual',
      // Sequelize DECIMAL trả về String; parse linh hoạt thay vì `as num?`.
      latitude: _doubleVal(d['latitude']),
      longitude: _doubleVal(d['longitude']),
    );
  }

  bool _boolVal(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;
    return v.toString().toLowerCase() == 'true';
  }

  /// Parse double từ num hoặc String — Sequelize DECIMAL trả về String để giữ
  /// precision, không ép kiểu trực tiếp sang `num` được.
  double _doubleVal(dynamic v, {double fallback = 0.0}) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? fallback;
  }
}