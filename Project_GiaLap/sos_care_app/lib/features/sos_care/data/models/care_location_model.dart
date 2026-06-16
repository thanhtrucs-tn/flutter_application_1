import '../../domain/entities/care_location.dart';

class CareLocationModel {
  final String id;
  final String deviceId;
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  const CareLocationModel({
    required this.id,
    required this.deviceId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  factory CareLocationModel.fromJson(Map<String, dynamic> json) {
    return CareLocationModel(
      id: json['id'] as String,
      deviceId: json['deviceId'] as String,
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      timestamp: _parseDate(json['timestamp']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  CareLocation toEntity() {
    return CareLocation(
      id: id,
      deviceId: deviceId,
      latitude: latitude,
      longitude: longitude,
      timestamp: timestamp,
    );
  }
}
