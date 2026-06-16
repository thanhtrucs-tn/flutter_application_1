import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/repositories/sos_simulator_repository.dart';

/// Mock implementation that simulates a successful backend without
/// performing any real HTTP request.
///
/// Useful for demonstrations and UI testing when the backend is not
/// available. All payloads are printed to the console.
class SosSimulatorMockDataSource implements SosSimulatorRepository {
  const SosSimulatorMockDataSource();

  @override
  Future<Either<Failure, Unit>> sendSosAlert({
    required String deviceId,
    required String elderlyId,
    required DateTime timestamp,
    required double latitude,
    required double longitude,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _log('SOS', {
      'deviceId': deviceId,
      'elderlyId': elderlyId,
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'type': 'SOS',
    });
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> sendEvent({
    required String deviceId,
    required String elderlyId,
    required DateTime timestamp,
    required double latitude,
    required double longitude,
    required String type,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _log('EVENT', {
      'deviceId': deviceId,
      'elderlyId': elderlyId,
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'type': type,
    });
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> sendLocation({
    required String deviceId,
    required String elderlyId,
    required DateTime timestamp,
    required double latitude,
    required double longitude,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _log('LOCATION', {
      'deviceId': deviceId,
      'elderlyId': elderlyId,
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
    });
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> updateBattery({
    required String deviceId,
    required String elderlyId,
    required DateTime timestamp,
    required int batteryPercent,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _log('BATTERY', {
      'deviceId': deviceId,
      'elderlyId': elderlyId,
      'timestamp': timestamp.toIso8601String(),
      'batteryPercent': batteryPercent,
    });
    return const Right(unit);
  }

  void _log(String tag, Map<String, dynamic> payload) {
    // ignore: avoid_print
    print('🧪 MOCK $tag: $payload');
  }
}
