import 'api_client.dart';
import '../models/elderly_model.dart';
import '../models/emergency_contact_model.dart';

/// Gọi các endpoint /api/relatives (CRUD + contacts) trên backend.
///
/// Backend trả về relative DTO đã "fuse" (profile + contacts + latest location/
/// status). Service này map DTO → [ElderlyModel]. Contacts lưu trong
/// [ElderlyModel] dưới dạng `List<String>` (chuỗi "Tên (Quan hệ): SĐT") để giữ
/// tương thích UI; parse ngược thành structured contacts khi gửi lên server.
class RelativesApiService {
  RelativesApiService._();
  static final RelativesApiService instance = RelativesApiService._();

  Future<List<ElderlyModel>> list() async {
    final data = await ApiClient.instance.get('/api/relatives');
    final list = (data as List?) ?? const [];
    return list
        .map((e) => _toElderly(e as Map<String, dynamic>))
        .toList();
  }

  Future<ElderlyModel> create(ElderlyModel e) async {
    final data = await ApiClient.instance.post(
      '/api/relatives',
      body: _toPayload(e),
    ) as Map<String, dynamic>;
    return _toElderly(data);
  }

  Future<ElderlyModel> update(ElderlyModel e) async {
    final data = await ApiClient.instance.put(
      '/api/relatives/${e.id}',
      body: _toPayload(e),
    ) as Map<String, dynamic>;
    return _toElderly(data);
  }

  /// Upload ảnh đại diện mới (multipart PUT /api/relatives/:id/avatar).
  /// Trả về relative đã cập nhật với `avatar` trỏ tới file đã upload.
  Future<ElderlyModel> updateAvatar(int id, String localPath) async {
    final data = await ApiClient.instance.uploadMultipart(
      '/api/relatives/$id/avatar',
      filePath: localPath,
    );
    return _toElderly(data);
  }

  Future<void> remove(int id) async {
    await ApiClient.instance.delete('/api/relatives/$id');
  }

  /// Bulk-replace toàn bộ contacts của 1 relative.
  Future<void> setContacts(int relativeId, List<String> contacts) async {
    await ApiClient.instance.put(
      '/api/relatives/$relativeId',
      body: {'contacts': _parseContacts(contacts)},
    );
  }

  Map<String, dynamic> _toPayload(ElderlyModel e) {
    final payload = <String, dynamic>{
      'name': e.name,
      'safeZoneRadius': e.safeZoneRadius,
      'safeZoneLat': e.safeZoneLat,
      'safeZoneLng': e.safeZoneLng,
      'contacts': _parseContacts(e.emergencyContacts),
      // Luôn gửi age/address: null khi trống để cho phép XÓA trường trên server.
      'age': e.age,
      'address': e.address.isEmpty ? null : e.address,
    };
    if (e.avatar.isNotEmpty) payload['avatar'] = e.avatar;
    // wearableDevice (UI) = deviceElderlyId (business key thiết bị emit, vd ELDERLY-001).
    if (e.wearableDevice.isNotEmpty) {
      payload['deviceElderlyId'] = e.wearableDevice;
      payload['wearableDevice'] = e.wearableDevice;
    }
    return payload;
  }

  List<Map<String, dynamic>> _parseContacts(List<String> contacts) {
    return contacts
        .map((s) => EmergencyContactModel.fromStorageString(s).toMap())
        .toList();
  }

  ElderlyModel _toElderly(Map<String, dynamic> d) {
    final loc = d['latestLocation'] as Map<String, dynamic>?;
    final status = d['latestStatus'] as Map<String, dynamic>?;
    final contacts = (d['contacts'] as List?) ?? const [];
    // Sequelize lưu DECIMAL → JSON trả về dạng String (giữ precision), nên
    // parse linh hoạt thay vì cast cứng `as num?`/`as num` (gây type cast crash).
    final safeLat = _doubleVal(d['safeZoneLat']);
    final safeLng = _doubleVal(d['safeZoneLng']);
    final lat = loc != null ? _doubleVal(loc['latitude']) : safeLat;
    final lng = loc != null ? _doubleVal(loc['longitude']) : safeLng;
    final battery = _intVal(status?['batteryPercent']);
    final heartRate = _intVal(status?['heartRateBpm']);
    final spo2 = _intVal(status?['spo2Percent']);
    final isOnline = _boolVal(status?['isOnline']);
    final lastTs = status?['timestamp'] ?? loc?['timestamp'];
    return ElderlyModel(
      id: (d['id'] as num).toInt(),
      name: (d['name'] as String?) ?? '',
      avatar: _toAbsoluteUrl((d['avatar'] as String?) ?? ''),
      battery: battery,
      lastUpdated: lastTs != null
          ? DateTime.parse(lastTs.toString()).toLocal()
          : DateTime.now(),
      status: 'safe', // recompute từ alerts trong AppState
      latitude: lat,
      longitude: lng,
      heartRate: heartRate,
      spo2: spo2,
      isOffline: !isOnline,
      wearableDevice:
          (d['deviceElderlyId'] as String?) ?? (d['wearableDevice'] as String?) ?? '',
      isFallen: false, // recompute từ alerts trong AppState
      safeZoneRadius: _doubleVal(d['safeZoneRadius'], fallback: 500.0),
      safeZoneLat: safeLat == 0.0 ? lat : safeLat,
      safeZoneLng: safeLng == 0.0 ? lng : safeLng,
      emergencyContacts: contacts
          .map((c) => EmergencyContactModel.fromMap(c as Map<String, dynamic>)
              .toStorageString())
          .toList(),
      address: (d['address'] as String?) ?? '',
      age: d['age'] != null ? (d['age'] as num).toInt() : null,
    );
  }

  int _intVal(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  /// Parse double từ num hoặc String — Sequelize DECIMAL trả về String để giữ
  /// precision, không ép kiểu trực tiếp sang `num` được. [fallback] áp dụng khi
  /// null hoặc chuỗi không hợp lệ (mặc định 0.0; safeZoneRadius truyền 500.0).
  double _doubleVal(dynamic v, {double fallback = 0.0}) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? fallback;
  }

  bool _boolVal(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;
    return v.toString().toLowerCase() == 'true';
  }

  /// Backend lưu avatar dưới dạng đường dẫn tương đối `/uploads/...` — chuyển
  /// thành URL tuyệt đối theo base URL của client (tự đổi host trên Android).
  String _toAbsoluteUrl(String url) {
    if (url.isEmpty) return '';
    if (url.startsWith('/')) return '${ApiClient.instance.baseUrl}$url';
    return url;
  }
}