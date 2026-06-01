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
    );
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
    };
  }
}
