import 'dart:io';

import 'package:flutter/foundation.dart';

/// Centralized API configuration.
///
/// Toggle [useMock] to switch between the mock data source and the
/// real remote backend. The base URL is a placeholder and should be
/// updated to point to the real SOS Care backend.
class ApiConfig {
  const ApiConfig._();

  /// Base URL for the real SOS Care backend.
  static const String baseUrl = 'http://localhost:8081';

  /// When `true`, the application uses the in-memory mock data source
  /// instead of performing real HTTP requests.
  static const bool useMock = false;

  /// Default connection timeout for Dio.
  static const Duration connectTimeout = Duration(seconds: 5);

  /// Default send timeout for Dio.
  static const Duration sendTimeout = Duration(seconds: 10);

  /// Default receive timeout for Dio.
  ///
  /// Raised from 10s to 30s because the SOS Care backend can take a while
  /// to process emergency alerts during high load.
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// Socket.IO server URL.
  static const String socketUrl = 'http://localhost:8081';

  /// Endpoint for SOS emergency alerts.
  static const String sosEndpoint = '/api/sos';

  /// Endpoint for general device events (fall, heart rate alert).
  static const String eventsEndpoint = '/api/events';

  /// Endpoint for location updates.
  static const String locationEndpoint = '/api/location';

  /// Endpoint for battery updates.
  static const String batteryEndpoint = '/api/device/battery';

  /// Endpoint for device online/offline status updates.
  static const String statusEndpoint = '/api/device/status';

  /// Chuyển `localhost` thành `10.0.2.2` khi chạy trên Android emulator để
  /// simulator kết nối được tới backend đang chạy trên máy host. Giữ nguyên
  /// trên web/desktop (localhost đã trỏ đúng).
  static String resolveBackendUrl(String url) {
    if (kIsWeb) return url;
    if (Platform.isAndroid) {
      return url.replaceFirst('localhost', '10.0.2.2');
    }
    return url;
  }
}
