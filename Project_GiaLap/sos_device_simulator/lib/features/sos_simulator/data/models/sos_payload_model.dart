/// Payload sent to the SOS emergency endpoint.
///
/// Always carries `type: 'SOS'` to identify the alert.
class SosPayloadModel {
  final String deviceId;
  final String elderlyId;
  final String timestamp;
  final double latitude;
  final double longitude;
  final String type;

  const SosPayloadModel({
    required this.deviceId,
    required this.elderlyId,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    this.type = 'SOS',
  });

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'elderlyId': elderlyId,
    'timestamp': timestamp,
    'latitude': latitude,
    'longitude': longitude,
    'type': type,
  };

  factory SosPayloadModel.fromJson(Map<String, dynamic> json) {
    return SosPayloadModel(
      deviceId: json['deviceId'] as String,
      elderlyId: json['elderlyId'] as String,
      timestamp: json['timestamp'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      type: json['type'] as String? ?? 'SOS',
    );
  }
}
