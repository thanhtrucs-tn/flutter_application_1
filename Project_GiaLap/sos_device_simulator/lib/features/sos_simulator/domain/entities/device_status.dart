import 'operation_result.dart';

/// Runtime representation of the simulated SOS device's current state.
class DeviceStatus {
  final String deviceId;
  final String elderlyId;
  final bool isOnline;
  final int batteryPercent;
  final int heartRateBpm;
  final double latitude;
  final double longitude;
  final DateTime lastUpdatedAt;
  final OperationResult? lastOperationResult;

  const DeviceStatus({
    required this.deviceId,
    required this.elderlyId,
    this.isOnline = true,
    this.batteryPercent = 100,
    this.heartRateBpm = 72,
    this.latitude = 10.762622,
    this.longitude = 106.660172,
    required this.lastUpdatedAt,
    this.lastOperationResult,
  });

  DeviceStatus copyWith({
    String? deviceId,
    String? elderlyId,
    bool? isOnline,
    int? batteryPercent,
    int? heartRateBpm,
    double? latitude,
    double? longitude,
    DateTime? lastUpdatedAt,
    OperationResult? lastOperationResult,
  }) {
    return DeviceStatus(
      deviceId: deviceId ?? this.deviceId,
      elderlyId: elderlyId ?? this.elderlyId,
      isOnline: isOnline ?? this.isOnline,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      heartRateBpm: heartRateBpm ?? this.heartRateBpm,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      lastOperationResult: lastOperationResult,
    );
  }
}
