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
  final Debouncer _heartRateDebouncer;
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
        _heartRateDebouncer = Debouncer(
          delay: AppConstants.heartRateDebounceDelay,
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
    _heartRateDebouncer.dispose();
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
    _reportPresence(isOnline);
  }

  /// Pushes the online/offline transition to the backend so the caregiver
  /// app's device badge updates in real time. Not gated by the online flag:
  /// the OFF transition must also reach the backend (otherwise a device that
  /// was online would stay online forever). Fire-and-forget; a network
  /// failure overrides the optimistic success message via
  /// [lastOperationResult]. Unlike [_sendIfOnline], this is invoked after the
  /// local state flip so it always reports the new value.
  void _reportPresence(bool isOnline) {
    // ignore: discarded_futures
    () async {
      final requestId = ++_requestId;
      final result = await _repository.updateStatus(
        deviceId: state.deviceId,
        elderlyId: state.elderlyId,
        timestamp: DateTime.now(),
        batteryPercent: state.batteryPercent,
        isOnline: isOnline,
        heartRateBpm: state.heartRateBpm,
      );
      if (requestId != _requestId || !mounted) return;
      result.fold(
        (failure) => state = state.copyWith(
          lastOperationResult: OperationFailure(failure),
        ),
        (_) {},
      );
    }();
  }

  /// Validate a device/elderly identifier against the wearable code pattern
  /// accepted by the caregiver app's "add relative" form: letters, digits,
  /// hyphen, underscore; 3..30 chars. Keeping this in sync with the app's
  /// validator (add_relative_dialog.dart) guarantees a code set here is
  /// accepted there, so the pairing (relative.deviceElderlyId == elderlyId)
  /// always wires up.
  static bool isValidDeviceCode(String code) =>
      RegExp(r'^[A-Za-z0-9_\-]{3,30}$').hasMatch(code);

  /// Update the simulated device serial. Ignored if [id] is empty/invalid; the
  /// editor dialog validates with the same regex before calling.
  void setDeviceId(String id) {
    final trimmed = id.trim();
    if (!isValidDeviceCode(trimmed)) return;
    state = state.copyWith(
      deviceId: trimmed,
      lastUpdatedAt: DateTime.now(),
      lastOperationResult: const OperationSuccess('Đã cập nhật mã thiết bị'),
    );
  }

  /// Update the elderly pairing key — the value the caregiver must type into
  /// the "Mã/Tên thiết bị" field when adding a relative, so the relative's
  /// deviceElderlyId links to this device's telemetry stream on the backend.
  void setElderlyId(String id) {
    final trimmed = id.trim();
    if (!isValidDeviceCode(trimmed)) return;
    state = state.copyWith(
      elderlyId: trimmed,
      lastUpdatedAt: DateTime.now(),
      lastOperationResult: const OperationSuccess('Đã cập nhật mã ghép đôi'),
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

    // Push the new heart rate to the backend (debounced) so the caregiver
    // app's heart-rate vital updates in realtime. Mirrors the battery slider.
    // Fire-and-forget (no Snackbar) to avoid spam during dragging.
    if (state.isOnline) {
      _heartRateDebouncer.run(_pushStatus);
    }

    if (state.isOnline && clamped > AppConstants.heartRateAlertThreshold) {
      _heartRateThrottle.run(() => sendEvent('HEART_RATE_ALERT'));
    }
  }

  /// Fire-and-forget status push for continuous controls (heart-rate slider)
  /// so the caregiver app receives the latest vitals in realtime. Gated on
  /// [DeviceStatus.isOnline] — an offline device sends no telemetry. Only
  /// network failures surface via [lastOperationResult]; success is silent to
  /// avoid Snackbar spam on every debounced update. Unlike [_reportPresence],
  /// this is skipped while offline (the OFF transition itself is still
  /// handled by [_reportPresence], which is not gated).
  void _pushStatus() {
    // ignore: discarded_futures
    () async {
      final requestId = ++_requestId;
      final result = await _repository.updateStatus(
        deviceId: state.deviceId,
        elderlyId: state.elderlyId,
        timestamp: DateTime.now(),
        batteryPercent: state.batteryPercent,
        isOnline: state.isOnline,
        heartRateBpm: state.heartRateBpm,
      );
      if (requestId != _requestId || !mounted) return;
      result.fold(
        (failure) => state = state.copyWith(
          lastOperationResult: OperationFailure(failure),
        ),
        (_) {},
      );
    }();
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
    // The device defaults to Online (see DeviceStatus.isOnline); report that
    // initial state so a freshly started simulator is not stuck "Offline" in
    // the caregiver app until the user manually toggles the switch.
    _reportPresence(state.isOnline);
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
