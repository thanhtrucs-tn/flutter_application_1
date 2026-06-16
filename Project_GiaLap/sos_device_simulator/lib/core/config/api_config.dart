/// Centralized API configuration.
///
/// Toggle [useMock] to switch between the mock data source and the
/// real remote backend. The base URL is a placeholder and should be
/// updated to point to the real SOS Care backend.
class ApiConfig {
  const ApiConfig._();

  /// Base URL for the real SOS Care backend.
  static const String baseUrl = 'http://localhost:8080';

  /// When `true`, the application uses the in-memory mock data source
  /// instead of performing real HTTP requests.
  static const bool useMock = false;

  /// Default connection timeout for Dio.
  static const Duration connectTimeout = Duration(seconds: 5);

  /// Default receive timeout for Dio.
  static const Duration receiveTimeout = Duration(seconds: 10);

  /// Socket.IO server URL.
  static const String socketUrl = 'http://localhost:8080';

  /// Endpoint for SOS emergency alerts.
  static const String sosEndpoint = '/api/sos';

  /// Endpoint for general device events (fall, heart rate alert).
  static const String eventsEndpoint = '/api/events';

  /// Endpoint for location updates.
  static const String locationEndpoint = '/api/location';

  /// Endpoint for battery updates.
  static const String batteryEndpoint = '/api/device/battery';
}
