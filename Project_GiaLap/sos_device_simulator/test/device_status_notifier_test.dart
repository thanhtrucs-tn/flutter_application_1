import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sos_device_simulator/core/constants/app_constants.dart';
import 'package:sos_device_simulator/core/errors/failure.dart';
import 'package:sos_device_simulator/features/sos_simulator/application/services/location_service.dart';
import 'package:sos_device_simulator/features/sos_simulator/domain/entities/operation_result.dart';
import 'package:sos_device_simulator/features/sos_simulator/domain/repositories/sos_simulator_repository.dart';
import 'package:sos_device_simulator/features/sos_simulator/presentation/providers/device_status_notifier.dart';

/// Fake repository that records invocations and returns a configurable
/// result. Used to test the notifier in isolation.
class FakeRepository implements SosSimulatorRepository {
  final Either<Failure, Unit> result;
  final List<String> calls = [];

  FakeRepository({this.result = const Right(unit)});

  @override
  Future<Either<Failure, Unit>> sendSosAlert({
    required String deviceId,
    required String elderlyId,
    required DateTime timestamp,
    required double latitude,
    required double longitude,
  }) async {
    calls.add('sendSosAlert');
    return result;
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
    calls.add('sendEvent:$type');
    return result;
  }

  @override
  Future<Either<Failure, Unit>> sendLocation({
    required String deviceId,
    required String elderlyId,
    required DateTime timestamp,
    required double latitude,
    required double longitude,
  }) async {
    calls.add('sendLocation');
    return result;
  }

  @override
  Future<Either<Failure, Unit>> updateBattery({
    required String deviceId,
    required String elderlyId,
    required DateTime timestamp,
    required int batteryPercent,
  }) async {
    calls.add('updateBattery:$batteryPercent');
    return result;
  }
}

class FakeLocationService implements LocationService {
  @override
  Future<({double latitude, double longitude})> getCurrentLocation() async {
    return (
      latitude: AppConstants.defaultLatitude,
      longitude: AppConstants.defaultLongitude,
    );
  }

  @override
  Future<({double latitude, double longitude})> getLastKnown() async {
    return (
      latitude: AppConstants.defaultLatitude,
      longitude: AppConstants.defaultLongitude,
    );
  }

  @override
  void warmUp() {
    // No-op in tests.
  }
}

void main() {
  late FakeRepository repository;
  late FakeLocationService locationService;
  late DeviceStatusNotifier notifier;

  setUp(() {
    repository = FakeRepository();
    locationService = FakeLocationService();
    notifier = DeviceStatusNotifier(
      repository: repository,
      locationService: locationService,
    );
  });

  tearDown(() {
    notifier.dispose();
  });

  test('setBattery updates state and debounces repository call', () async {
    notifier.setBattery(80);
    expect(notifier.state.batteryPercent, 80);

    // Wait for debounce delay.
    await Future.delayed(AppConstants.batteryDebounceDelay + const Duration(milliseconds: 50));

    expect(repository.calls, contains('updateBattery:80'));
  });

  test('heart rate above threshold triggers HEART_RATE_ALERT when online', () async {
    notifier.setHeartRate(120);
    await Future.delayed(const Duration(milliseconds: 100));

    expect(repository.calls, contains('sendEvent:HEART_RATE_ALERT'));
  });

  test('all outgoing calls are blocked when offline', () async {
    notifier.setOnline(false);
    await notifier.sendSosAlert();
    await notifier.sendFallEvent();
    await notifier.sendCurrentLocation();

    expect(repository.calls, isEmpty);
    expect(notifier.state.lastOperationResult, isA<OperationFailure>());
  });
}
