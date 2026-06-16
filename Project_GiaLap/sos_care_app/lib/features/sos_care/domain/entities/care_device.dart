import 'care_device_status.dart';
import 'care_location.dart';

/// Caregiver view of a monitored SOS device.
class CareDevice {
  final String id;
  final String elderlyId;
  final String? elderlyName;
  final String status;
  final DateTime? lastSeenAt;
  final CareDeviceStatus? latestStatus;
  final CareLocation? latestLocation;

  const CareDevice({
    required this.id,
    required this.elderlyId,
    this.elderlyName,
    this.status = 'active',
    this.lastSeenAt,
    this.latestStatus,
    this.latestLocation,
  });

  CareDevice copyWith({
    String? elderlyName,
    String? status,
    DateTime? lastSeenAt,
    CareDeviceStatus? latestStatus,
    CareLocation? latestLocation,
  }) {
    return CareDevice(
      id: id,
      elderlyId: elderlyId,
      elderlyName: elderlyName ?? this.elderlyName,
      status: status ?? this.status,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      latestStatus: latestStatus ?? this.latestStatus,
      latestLocation: latestLocation ?? this.latestLocation,
    );
  }

  bool get isOnline => latestStatus?.isOnline ?? false;

  int? get batteryPercent => latestStatus?.batteryPercent;

  int? get heartRateBpm => latestStatus?.heartRateBpm;
}
