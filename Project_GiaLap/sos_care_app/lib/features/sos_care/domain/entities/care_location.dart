/// GPS location update received in realtime.
class CareLocation {
  final String id;
  final String deviceId;
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  const CareLocation({
    required this.id,
    required this.deviceId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });
}
