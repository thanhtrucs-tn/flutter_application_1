import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/services/dio_client.dart';
import '../../application/services/location_service.dart';
import '../../data/repositories/sos_simulator_mock_data_source.dart';
import '../../data/repositories/sos_simulator_remote_data_source.dart';
import '../../data/repositories/sos_simulator_repository_impl.dart';
import '../../domain/entities/device_status.dart';
import '../../domain/repositories/sos_simulator_repository.dart';
import 'device_status_notifier.dart';

/// Provides the configured Dio client used by the remote data source.
final dioProvider = Provider((ref) => DioClient.create().dio);

/// Provides the concrete backend abstraction.
///
/// Switches between mock and remote based on [ApiConfig.useMock] so the
/// app can be demonstrated without a real backend.
final sosSimulatorRepositoryProvider = Provider<SosSimulatorRepository>((ref) {
  if (ApiConfig.useMock) {
    return SosSimulatorRepositoryImpl.mock(
      const SosSimulatorMockDataSource(),
    );
  }
  final dio = ref.watch(dioProvider);
  return SosSimulatorRepositoryImpl.remote(
    SosSimulatorRemoteDataSource(dio),
  );
});

/// Provides the location service abstraction.
final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(),
);

/// Provides the mutable device state and backend coordination.
final deviceStatusNotifierProvider =
    StateNotifierProvider<DeviceStatusNotifier, DeviceStatus>((ref) {
  final repository = ref.watch(sosSimulatorRepositoryProvider);
  final locationService = ref.watch(locationServiceProvider);
  return DeviceStatusNotifier(
    repository: repository,
    locationService: locationService,
  );
});
