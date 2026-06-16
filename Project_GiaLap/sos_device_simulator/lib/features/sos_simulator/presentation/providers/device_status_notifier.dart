import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/utils/debouncer.dart';
import '../../../../core/utils/throttle_helper.dart';
import '../../application/services/location_service.dart';
import '../../domain/entities/device_status.dart';
import '../../domain/entities/operation_result.dart';
import '../../domain/repositories/sos_simulator_repository.dart';

/// Manages the simulated device state and coordinates API calls.
///
/// The notifier owns battery/heart-rate sliders, online/offline toggle,
/// GPS updates, and automatic heart-rate alerts. All backend operations
/// are reflected in [DeviceStatus.lastOperationResult] so the UI can show
/// Snackbar feedback. A monotonic request id guards against stale results
/// when operations overlap.
class DeviceStatusNotifier extends StateNotifier<DeviceStatus> {
  final SosSimulatorRepository _repository;
  final LocationService _locationService;
  final Debouncer _batteryDebouncer;
  final ThrottleHelper _heartRateThrottle;

  int _requestId = 0;

  DeviceStatusNotifier({
    required SosSimulatorRepository repository,
    required LocationService locationService,
  })  : _repository = repository,
        _locationService = locationService,
        _batteryDebouncer = Debouncer(
          delay: AppConstants.batteryDebounceDelay,
        ),
        _heartRateThrottle = ThrottleHelper(
          duration: AppConstants.heartRateAlertThrottle,
        ),
        super(
          DeviceStatus(
            deviceId: AppConstants.defaultDeviceId,
            elderlyId: AppConstants.defaultElderlyId,
            lastUpdatedAt: DateTime.now(),
          ),
        );

  @override
  void dispose() {
    _batteryDebouncer.dispose();
    super.dispose();
  }

  void setOnline(bool isOnline) {
    state = state.copyWith(
      isOnline: isOnline,
      lastUpdatedAt: DateTime.now(),
      lastOperationResult: isOnline
          ? const OperationSuccess('Thiết bị đã Online')
          : const OperationSuccess('Thiết bị đã Offline'),
    );
  }

  void setBattery(int percent) {
    final clamped = percent.clamp(0, 100);
    state = state.copyWith(
      batteryPercent: clamped,
      lastUpdatedAt: DateTime.now(),
    );
    _batteryDebouncer.run(() => _sendIfOnline(
      action: () => _repository.updateBattery(
        deviceId: state.deviceId,
        elderlyId: state.elderlyId,
        timestamp: DateTime.now(),
        batteryPercent: clamped,
      ),
      success: 'Đã cập nhật mức pin',
    ));
  }

  void setHeartRate(int bpm) {
    final clamped = bpm.clamp(
      AppConstants.minHeartRate,
      AppConstants.maxHeartRate,
    );
    state = state.copyWith(
      heartRateBpm: clamped,
      lastUpdatedAt: DateTime.now(),
    );

    if (state.isOnline && clamped > AppConstants.heartRateAlertThreshold) {
      _heartRateThrottle.run(() => sendEvent('HEART_RATE_ALERT'));
    }
  }

  /// Populates the cached coordinates from the last known GPS fix and
  /// kicks off a background warm-up. Safe to call multiple times.
  Future<void> bootstrap() async {
    final coords = await _locationService.getLastKnown();
    state = state.copyWith(
      latitude: coords.latitude,
      longitude: coords.longitude,
      lastUpdatedAt: DateTime.now(),
    );
    _locationService.warmUp();
  }

  Future<void> sendSosAlert() async {
    await _sendIfOnline(
      action: () => _repository.sendSosAlert(
        deviceId: state.deviceId,
        elderlyId: state.elderlyId,
        timestamp: DateTime.now(),
        latitude: state.latitude,
        longitude: state.longitude,
      ),
      success: 'Đã gửi cảnh báo SOS',
    );
    _refreshLocationInBackground();
  }

  Future<void> sendEvent(String type) async {
    await _sendIfOnline(
      action: () => _repository.sendEvent(
        deviceId: state.deviceId,
        elderlyId: state.elderlyId,
        timestamp: DateTime.now(),
        latitude: state.latitude,
        longitude: state.longitude,
        type: type,
      ),
      success: 'Đã gửi sự kiện $type',
    );
    _refreshLocationInBackground();
  }

  Future<void> sendFallEvent() async {
    await sendEvent('FALL_DETECTED');
  }

  Future<void> simulateOffline() async {
    setOnline(false);
  }

  /// Explicit "send current location" — waits for a fresh GPS fix before
  /// POSTing. Used by the dedicated location button.
  Future<void> sendCurrentLocation() async {
    final coords = await _locationService.getCurrentLocation();
    state = state.copyWith(
      latitude: coords.latitude,
      longitude: coords.longitude,
      lastUpdatedAt: DateTime.now(),
    );
    await _sendIfOnline(
      action: () => _repository.sendLocation(
        deviceId: state.deviceId,
        elderlyId: state.elderlyId,
        timestamp: DateTime.now(),
        latitude: coords.latitude,
        longitude: coords.longitude,
      ),
      success: 'Đã gửi vị trí hiện tại',
    );
  }

  /// Fire-and-forget GPS refresh. Updates cached coords in state for
  /// the next event. Errors are swallowed — GPS may legitimately be
  /// unavailable (desktop, denied permission).
  void _refreshLocationInBackground() {
    // ignore: discarded_futures
    () async {
      try {
        final coords = await _locationService.getCurrentLocation();
        if (!mounted) return;
        state = state.copyWith(
          latitude: coords.latitude,
          longitude: coords.longitude,
          lastUpdatedAt: DateTime.now(),
        );
      } catch (_) {
        // Silent — cached coords are still valid for the next send.
      }
    }();
  }

  Future<void> _sendIfOnline({
    required Future<Either<Failure, Unit>> Function() action,
    required String success,
  }) async {
    if (!state.isOnline) {
      state = state.copyWith(
        lastOperationResult: const OperationFailure(
          NetworkFailure(message: 'Thiết bị đang Offline, không gửi dữ liệu'),
        ),
      );
      return;
    }

    final requestId = ++_requestId;
    final result = await action();
    if (requestId != _requestId) return;

    result.fold(
      (failure) => state = state.copyWith(
        lastOperationResult: OperationFailure(failure),
      ),
      (_) => state = state.copyWith(
        lastOperationResult: OperationSuccess(success),
      ),
    );
  }
}
