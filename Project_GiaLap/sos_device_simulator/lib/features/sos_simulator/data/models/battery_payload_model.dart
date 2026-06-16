/// Payload sent when the simulated battery level changes.
class BatteryPayloadModel {
  final String deviceId;
  final String elderlyId;
  final String timestamp;
  final int batteryPercent;

  const BatteryPayloadModel({
    required this.deviceId,
    required this.elderlyId,
    required this.timestamp,
    required this.batteryPercent,
  });

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'elderlyId': elderlyId,
    'timestamp': timestamp,
    'batteryPercent': batteryPercent,
  };

  factory BatteryPayloadModel.fromJson(Map<String, dynamic> json) {
    return BatteryPayloadModel(
      deviceId: json['deviceId'] as String,
      elderlyId: json['elderlyId'] as String,
      timestamp: json['timestamp'] as String,
      batteryPercent: json['batteryPercent'] as int,
    );
  }
}
