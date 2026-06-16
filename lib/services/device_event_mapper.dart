import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/elderly_model.dart';
import '../utils/app_state.dart';

/// Pure helpers để parse payload backend và ánh xạ `elderlyId`/`deviceId`
/// sang [ElderlyModel.id]. Không chứa logic kết nối Socket.IO.
class DeviceEventMapper {
  const DeviceEventMapper._();

  /// Chuyển `localhost` thành `10.0.2.2` khi chạy trên Android emulator.
  static String resolveBackendUrl(String url) {
    if (kIsWeb) return url;
    if (Platform.isAndroid) {
      return url.replaceFirst('localhost', '10.0.2.2');
    }
    return url;
  }

  /// Tạo id thông báo ổn định, dương, dựa trên loại và elderlyId.
  static int notificationId(int elderlyId, int base) {
    return base + (elderlyId.abs() % 100000);
  }

  /// Tìm elderly đã tồn tại hoặc tạo một bản ghi tạm nếu chưa có.
  static int resolveOrCreate(
    String elderlyId,
    String deviceId,
    double lat,
    double lng,
  ) {
    final existing = resolveElderlyId(elderlyId, deviceId: deviceId);
    if (existing != null) return existing;

    final tempId = 1000000 + (DateTime.now().millisecondsSinceEpoch % 9000000);
    final temp = ElderlyModel(
      id: tempId,
      name: 'Người thân $elderlyId',
      avatar: 'https://cdn-icons-png.flaticon.com/512/10014/10014656.png',
      battery: 80,
      lastUpdated: DateTime.now(),
      status: 'safe',
      latitude: lat,
      longitude: lng,
      heartRate: 0,
      spo2: 0,
      isOffline: false,
      wearableDevice: deviceId,
      isFallen: false,
      safeZoneRadius: 500,
      safeZoneLat: lat,
      safeZoneLng: lng,
      emergencyContacts: const [],
    );
    AppState().addElderly(temp);
    return tempId;
  }

  /// Ánh xạ `elderlyId` (vd `ELDERLY-001`) sang id số của [ElderlyModel].
  /// Nếu không tìm thấy, thử khớp theo `deviceId` == `wearableDevice`.
  static int? resolveElderlyId(String elderlyId, {String? deviceId}) {
    int? numeric;
    final match = RegExp(r'(\d+)').firstMatch(elderlyId);
    if (match != null) numeric = int.tryParse(match.group(1)!);

    final relatives = AppState().relatives;
    if (numeric != null && relatives.any((e) => e.id == numeric)) {
      return numeric;
    }
    if (deviceId != null && deviceId.isNotEmpty) {
      final byDevice = relatives.cast<ElderlyModel?>().firstWhere(
        (e) => e!.wearableDevice == deviceId,
        orElse: () => null,
      );
      if (byDevice != null) return byDevice.id;
    }
    return null;
  }

  /// Parse payload từ backend thành Map<String, dynamic> an toàn.
  static Map<String, dynamic>? asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      try {
        return Map<String, dynamic>.from(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static String string(dynamic value) => value?.toString() ?? '';

  static double doubleVal(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  static int intVal(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool boolVal(dynamic value) {
    if (value is bool) return value;
    if (value == null) return false;
    return value.toString().toLowerCase() == 'true';
  }
}
