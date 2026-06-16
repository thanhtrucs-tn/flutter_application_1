import '../../domain/entities/care_device_status.dart';

class CareDeviceStatusModel {
  final String id;
  final String deviceId;
  final int batteryPercent;
  final int? heartRateBpm;
  final bool isOnline;
  final DateTime timestamp;

  const CareDeviceStatusModel({
    required this.id,
    required this.deviceId,
    required this.batteryPercent,
    this.heartRateBpm,
    required this.isOnline,
    required this.timestamp,
  });

  factory CareDeviceStatusModel.fromJson(Map<String, dynamic> json) {
    return CareDeviceStatusModel(
      id: json['id'] as String,
      deviceId: json['deviceId'] as String,
      batteryPercent: _toInt(json['batteryPercent']),
      heartRateBpm: json['heartRateBpm'] != null ? _toInt(json['heartRateBpm']) : null,
      isOnline: json['isOnline'] as bool? ?? true,
      timestamp: _parseDate(json['timestamp']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  CareDeviceStatus toEntity() {
    return CareDeviceStatus(
      id: id,
      deviceId: deviceId,
      batteryPercent: batteryPercent,
      heartRateBpm: heartRateBpm,
      isOnline: isOnline,
      timestamp: timestamp,
    );
  }
}
