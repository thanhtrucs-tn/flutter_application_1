import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/repositories/sos_simulator_repository.dart';
import 'sos_simulator_mock_data_source.dart';
import 'sos_simulator_remote_data_source.dart';

/// Repository implementation that simply forwards to the selected data
/// source.
///
/// This class exists so the domain layer depends only on the abstract
/// [SosSimulatorRepository], while the concrete data source is chosen
/// at the composition root (main.dart / providers).
class SosSimulatorRepositoryImpl implements SosSimulatorRepository {
  final SosSimulatorRepository _dataSource;

  SosSimulatorRepositoryImpl.remote(SosSimulatorRemoteDataSource remote)
      : _dataSource = remote;

  SosSimulatorRepositoryImpl.mock(SosSimulatorMockDataSource mock)
      : _dataSource = mock;

  @override
  Future<Either<Failure, Unit>> sendSosAlert({
    required String deviceId,
    required String elderlyId,
    required DateTime timestamp,
    required double latitude,
    required double longitude,
  }) {
    return _dataSource.sendSosAlert(
      deviceId: deviceId,
      elderlyId: elderlyId,
      timestamp: timestamp,
      latitude: latitude,
      longitude: longitude,
    );
  }

  @override
  Future<Either<Failure, Unit>> sendEvent({
    required String deviceId,
    required String elderlyId,
    required DateTime timestamp,
    required double latitude,
    required double longitude,
    required String type,
  }) {
    return _dataSource.sendEvent(
      deviceId: deviceId,
      elderlyId: elderlyId,
      timestamp: timestamp,
      latitude: latitude,
      longitude: longitude,
      type: type,
    );
  }

  @override
  Future<Either<Failure, Unit>> sendLocation({
    required String deviceId,
    required String elderlyId,
    required DateTime timestamp,
    required double latitude,
    required double longitude,
  }) {
    return _dataSource.sendLocation(
      deviceId: deviceId,
      elderlyId: elderlyId,
      timestamp: timestamp,
      latitude: latitude,
      longitude: longitude,
    );
  }

  @override
  Future<Either<Failure, Unit>> updateBattery({
    required String deviceId,
    required String elderlyId,
    required DateTime timestamp,
    required int batteryPercent,
  }) {
    return _dataSource.updateBattery(
      deviceId: deviceId,
      elderlyId: elderlyId,
      timestamp: timestamp,
      batteryPercent: batteryPercent,
    );
  }

  @override
  Future<Either<Failure, Unit>> updateStatus({
    required String deviceId,
    required String elderlyId,
    required DateTime timestamp,
    required int batteryPercent,
    required bool isOnline,
    required int heartRateBpm,
  }) {
    return _dataSource.updateStatus(
      deviceId: deviceId,
      elderlyId: elderlyId,
      timestamp: timestamp,
      batteryPercent: batteryPercent,
      isOnline: isOnline,
      heartRateBpm: heartRateBpm,
    );
  }
}
