import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';

/// Repository contract for all simulator backend operations.
///
/// Implementations decide whether to hit the real remote backend or
/// a local mock. All methods return an [Either] where [Right] means
/// success and [Left] carries a [Failure].
abstract class SosSimulatorRepository {
  /// Sends an SOS emergency alert.
  Future<Either<Failure, Unit>> sendSosAlert({
    required String deviceId,
    required String elderlyId,
    required DateTime timestamp,
    required double latitude,
    required double longitude,
  });

  /// Sends a device event such as fall detection or heart rate alert.
  Future<Either<Failure, Unit>> sendEvent({
    required String deviceId,
    required String elderlyId,
    required DateTime timestamp,
    required double latitude,
    required double longitude,
    required String type,
  });

  /// Sends the current device location.
  Future<Either<Failure, Unit>> sendLocation({
    required String deviceId,
    required String elderlyId,
    required DateTime timestamp,
    required double latitude,
    required double longitude,
  });

  /// Updates the simulated battery level on the backend.
  Future<Either<Failure, Unit>> updateBattery({
    required String deviceId,
    required String elderlyId,
    required DateTime timestamp,
    required int batteryPercent,
  });

  /// Reports the device online/offline state to the backend so the caregiver
  /// app's device badge updates in real time.
  Future<Either<Failure, Unit>> updateStatus({
    required String deviceId,
    required String elderlyId,
    required DateTime timestamp,
    required int batteryPercent,
    required bool isOnline,
    required int heartRateBpm,
  });
}
