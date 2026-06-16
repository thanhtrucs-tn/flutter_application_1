/// Realtime alert received from the SOS Care backend.
class CareAlert {
  final String id;
  final String deviceId;
  final String elderlyId;
  final String type;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final DateTime createdAt;
  final bool isRead;

  const CareAlert({
    required this.id,
    required this.deviceId,
    required this.elderlyId,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.createdAt,
    this.isRead = false,
  });

  CareAlert copyWith({bool? isRead}) {
    return CareAlert(
      id: id,
      deviceId: deviceId,
      elderlyId: elderlyId,
      type: type,
      latitude: latitude,
      longitude: longitude,
      timestamp: timestamp,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  bool get isCritical => type == 'SOS' || type == 'FALL_DETECTED' || type == 'HEART_RATE_ALERT';
}
