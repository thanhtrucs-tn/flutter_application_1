/// Payload sent when the device reports its current GPS coordinates.
class LocationPayloadModel {
  final String deviceId;
  final String elderlyId;
  final String timestamp;
  final double latitude;
  final double longitude;

  const LocationPayloadModel({
    required this.deviceId,
    required this.elderlyId,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'elderlyId': elderlyId,
    'timestamp': timestamp,
    'latitude': latitude,
    'longitude': longitude,
  };

  factory LocationPayloadModel.fromJson(Map<String, dynamic> json) {
    return LocationPayloadModel(
      deviceId: json['deviceId'] as String,
      elderlyId: json['elderlyId'] as String,
      timestamp: json['timestamp'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
}
