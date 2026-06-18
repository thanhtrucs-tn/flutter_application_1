/// Payload sent when the simulated device reports its online/offline state.
///
/// Mirrors the backend `POST /api/device/status` Joi schema: `deviceId`,
/// `timestamp`, `batteryPercent` are required; `elderlyId`, `isOnline`, and
/// `heartRateBpm` are optional. Only schema-defined fields are emitted so the
/// backend validator does not reject unknown keys.
class DeviceStatusPayloadModel {
  final String deviceId;
  final String elderlyId;
  final String timestamp;
  final int batteryPercent;
  final bool isOnline;
  final int heartRateBpm;

  const DeviceStatusPayloadModel({
    required this.deviceId,
    required this.elderlyId,
    required this.timestamp,
    required this.batteryPercent,
    required this.isOnline,
    required this.heartRateBpm,
  });

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'elderlyId': elderlyId,
        'timestamp': timestamp,
        'batteryPercent': batteryPercent,
        'isOnline': isOnline,
        'heartRateBpm': heartRateBpm,
      };

  factory DeviceStatusPayloadModel.fromJson(Map<String, dynamic> json) {
    return DeviceStatusPayloadModel(
      deviceId: json['deviceId'] as String,
      elderlyId: json['elderlyId'] as String,
      timestamp: json['timestamp'] as String,
      batteryPercent: json['batteryPercent'] as int,
      isOnline: json['isOnline'] as bool,
      heartRateBpm: json['heartRateBpm'] as int,
    );
  }
}