import '../../domain/entities/care_alert.dart';

/// Serializable model for a realtime alert received from Socket.IO or REST.
class CareAlertModel {
  final String id;
  final String deviceId;
  final String elderlyId;
  final String type;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final DateTime createdAt;

  const CareAlertModel({
    required this.id,
    required this.deviceId,
    required this.elderlyId,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.createdAt,
  });

  factory CareAlertModel.fromJson(Map<String, dynamic> json) {
    return CareAlertModel(
      id: json['id'] as String,
      deviceId: json['deviceId'] as String,
      elderlyId: json['elderlyId'] as String? ?? json['deviceId'] as String,
      type: json['type'] as String,
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      timestamp: _parseDate(json['timestamp']),
      createdAt: _parseDate(json['createdAt']),
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

  CareAlert toEntity() {
    return CareAlert(
      id: id,
      deviceId: deviceId,
      elderlyId: elderlyId,
      type: type,
      latitude: latitude,
      longitude: longitude,
      timestamp: timestamp,
      createdAt: createdAt,
    );
  }
}
