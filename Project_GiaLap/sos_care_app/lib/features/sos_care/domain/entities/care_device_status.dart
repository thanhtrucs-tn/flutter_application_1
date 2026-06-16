/// Latest device status snapshot received in realtime.
class CareDeviceStatus {
  final String id;
  final String deviceId;
  final int batteryPercent;
  final int? heartRateBpm;
  final bool isOnline;
  final DateTime timestamp;

  const CareDeviceStatus({
    required this.id,
    required this.deviceId,
    required this.batteryPercent,
    this.heartRateBpm,
    required this.isOnline,
    required this.timestamp,
  });
}
