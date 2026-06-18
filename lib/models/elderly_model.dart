import 'dart:convert';

/// Lớp mô tả thông tin sức khỏe và thiết bị của Người cao tuổi
class ElderlyModel {
  final int id;
  final String name;
  final String avatar;
  final int battery;
  final DateTime lastUpdated;
  final String status; // 'safe' (Bình thường), 'warning' (Cần lưu ý), 'critical' (SOS/Khẩn cấp)
  final double latitude;
  final double longitude;
  final int heartRate;
  final int spo2;
  final bool isOffline; // Trạng thái kết nối của thiết bị ESP32 (true: Offline, false: Online)
  final String wearableDevice;
  final bool isFallen; // Phát hiện té ngã hay không
  final double safeZoneRadius; // Bán kính vùng an toàn (mét)
  final double safeZoneLat; // Vĩ độ tâm vùng an toàn
  final double safeZoneLng; // Kinh độ tâm vùng an toàn
  final List<String> emergencyContacts;
  final String address; // Địa chỉ chữ (ví dụ: "268 Lý Thường Kiệt, Q.10, TP.HCM")
  final int? age; // Tuổi (năm). Null nếu elderly cũ chưa cập nhật hoặc chưa nhập.

  /// Đường dẫn file ảnh đại diện local do người dùng chọn.
  /// Nếu khác rỗng thì ưu tiên hiển thị ảnh local thay vì URL.
  final String avatarLocalPath;

  ElderlyModel({
    required this.id,
    required this.name,
    required this.avatar,
    required this.battery,
    required this.lastUpdated,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.heartRate,
    required this.spo2,
    required this.isOffline,
    required this.wearableDevice,
    required this.isFallen,
    required this.safeZoneRadius,
    required this.safeZoneLat,
    required this.safeZoneLng,
    required this.emergencyContacts,
    this.address = '',
    this.age,
    this.avatarLocalPath = '',
  });

  /// Tạo một bản sao mới với các trường thay đổi
  ElderlyModel copyWith({
    int? id,
    String? name,
    String? avatar,
    int? battery,
    DateTime? lastUpdated,
    String? status,
    double? latitude,
    double? longitude,
    int? heartRate,
    int? spo2,
    bool? isOffline,
    String? wearableDevice,
    bool? isFallen,
    double? safeZoneRadius,
    double? safeZoneLat,
    double? safeZoneLng,
    List<String>? emergencyContacts,
    String? address,
    int? age,
    String? avatarLocalPath,
  }) {
    return ElderlyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      battery: battery ?? this.battery,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      heartRate: heartRate ?? this.heartRate,
      spo2: spo2 ?? this.spo2,
      isOffline: isOffline ?? this.isOffline,
      wearableDevice: wearableDevice ?? this.wearableDevice,
      isFallen: isFallen ?? this.isFallen,
      safeZoneRadius: safeZoneRadius ?? this.safeZoneRadius,
      safeZoneLat: safeZoneLat ?? this.safeZoneLat,
      safeZoneLng: safeZoneLng ?? this.safeZoneLng,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      address: address ?? this.address,
      age: age ?? this.age,
      avatarLocalPath: avatarLocalPath ?? this.avatarLocalPath,
    );
  }

  /// Chuyển đổi từ Map (MySQL / SQLite / JSON)
  factory ElderlyModel.fromMap(Map<String, dynamic> map) {
    return ElderlyModel(
      id: map['id'] as int,
      name: map['name'] as String,
      avatar: map['avatar'] as String,
      battery: map['battery'] as int,
      lastUpdated: DateTime.parse(map['lastUpdated'] as String),
      status: map['status'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      heartRate: map['heartRate'] as int,
      spo2: map['spo2'] as int,
      isOffline: (map['isOffline'] as int? ?? 0) == 1,
      wearableDevice: map['wearableDevice'] as String? ?? 'ESP32 Smart Band V1',
      isFallen: (map['isFallen'] as int? ?? 0) == 1,
      safeZoneRadius: (map['safeZoneRadius'] as num? ?? 500.0).toDouble(),
      safeZoneLat: (map['safeZoneLat'] as num? ?? map['latitude'] ?? 10.762622).toDouble(),
      safeZoneLng: (map['safeZoneLng'] as num? ?? map['longitude'] ?? 106.660172).toDouble(),
      emergencyContacts: map['emergencyContacts'] is String
          ? List<String>.from(json.decode(map['emergencyContacts'] as String) as List)
          : List<String>.from(map['emergencyContacts'] as List? ?? []),
      address: map['address'] as String? ?? '',
      age: map['age'] as int?,
      avatarLocalPath: map['avatarLocalPath'] as String? ?? '',
    );
  }

  /// Tách (tên, số điện thoại) từ 1 chuỗi liên hệ khẩn cấp có dạng
  /// "Tên (Quan hệ): SĐT" hoặc "Tên: SĐT".
  /// Trả về `(name, phone)` — tên rỗng nếu chuỗi không có dấu ':' hợp lệ.
  /// Dùng record positional (.$1 = tên, .$2 = SĐT) thay vì named để tránh xung đột
  /// với field `name`/`phone` đã có sẵn của class ElderlyModel khi truy cập từ bên ngoài.
  static (String, String) splitContact(String contact) {
    final idx = contact.indexOf(':');
    if (idx < 0) return ('', contact.trim());
    var name = contact.substring(0, idx).trim();
    final phone = contact.substring(idx + 1).trim();
    // Bỏ hậu tố "(Quan hệ)" ở cuối tên để UI chỉ hiển thị tên.
    if (name.endsWith(')')) {
      final open = name.lastIndexOf('(');
      if (open > 0) {
        name = name.substring(0, open).trim();
      }
    }
    return (name, phone);
  }

  /// Chuyển sang Map để lưu trữ
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'battery': battery,
      'lastUpdated': lastUpdated.toIso8601String(),
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
      'heartRate': heartRate,
      'spo2': spo2,
      'isOffline': isOffline ? 1 : 0,
      'wearableDevice': wearableDevice,
      'isFallen': isFallen ? 1 : 0,
      'safeZoneRadius': safeZoneRadius,
      'safeZoneLat': safeZoneLat,
      'safeZoneLng': safeZoneLng,
      'emergencyContacts': json.encode(emergencyContacts),
      'address': address,
      'age': age,
      'avatarLocalPath': avatarLocalPath,
    };
  }
}
