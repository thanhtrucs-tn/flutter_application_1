import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/care_device_status_model.dart';
import '../../data/models/care_location_model.dart';
import '../../domain/entities/care_device.dart';

/// Holds the set of monitored devices and their latest realtime
/// status / location.
class CareDevicesNotifier extends StateNotifier<List<CareDevice>> {
  CareDevicesNotifier() : super([]);

  void upsertDevice(CareDevice device) {
    final existingIndex = state.indexWhere((d) => d.id == device.id);
    if (existingIndex == -1) {
      state = [...state, device];
    } else {
      final updated = [...state];
      updated[existingIndex] = device;
      state = UnmodifiableListView(updated);
    }
  }

  void handleStatusEvent(Map<String, dynamic> payload) {
    final status = CareDeviceStatusModel.fromJson(payload).toEntity();
    final device = _findOrCreateDevice(payload);
    upsertDevice(device.copyWith(latestStatus: status));
  }

  void handleLocationEvent(Map<String, dynamic> payload) {
    final location = CareLocationModel.fromJson(payload).toEntity();
    final device = _findOrCreateDevice(payload);
    upsertDevice(device.copyWith(
      latestLocation: location,
      lastSeenAt: location.timestamp,
    ));
  }

  void handleAlertEvent(Map<String, dynamic> payload) {
    final device = _findOrCreateDevice(payload);
    upsertDevice(device.copyWith(
      lastSeenAt: DateTime.now(),
    ));
  }

  void loadDevices(List<CareDevice> devices) {
    state = devices;
  }

  CareDevice _findOrCreateDevice(Map<String, dynamic> payload) {
    final deviceId = payload['deviceId'] as String? ?? '';
    final elderlyId = payload['elderlyId'] as String? ?? deviceId;
    final existing = state.firstWhere(
      (d) => d.id == deviceId,
      orElse: () => CareDevice(id: deviceId, elderlyId: elderlyId),
    );
    return existing;
  }
}
