/// Payload sent to the general events endpoint.
///
/// Supported types: `FALL_DETECTED` and `HEART_RATE_ALERT`.
class EventPayloadModel {
  final String deviceId;
  final String elderlyId;
  final String timestamp;
  final double latitude;
  final double longitude;
  final String type;

  const EventPayloadModel({
    required this.deviceId,
    required this.elderlyId,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'elderlyId': elderlyId,
    'timestamp': timestamp,
    'latitude': latitude,
    'longitude': longitude,
    'type': type,
  };

  factory EventPayloadModel.fromJson(Map<String, dynamic> json) {
    return EventPayloadModel(
      deviceId: json['deviceId'] as String,
      elderlyId: json['elderlyId'] as String,
      timestamp: json['timestamp'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      type: json['type'] as String,
    );
  }
}
