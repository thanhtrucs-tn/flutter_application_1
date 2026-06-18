import 'dart:io';

import 'package:flutter/foundation.dart';

/// Pure helpers để parse payload backend và xử lý URL backend.
/// Không chứa logic kết nối Socket.IO hay tra cứu elderly
/// (backend đã augment payload với `relativeId` int → [ElderlyModel.id]).
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

  /// Tạo id thông báo ổn định, dương, dựa trên loại và relativeId.
  static int notificationId(int relativeId, int base) {
    return base + (relativeId.abs() % 100000);
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