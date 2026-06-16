/// Centralized API and Socket.IO configuration for the SOS Care app.
class ApiConfig {
  const ApiConfig._();

  /// Base URL for the SOS Care backend.
  ///
  /// Use `http://10.0.2.2:8080` when running on the Android emulator,
  /// or the deployed backend URL in production.
  static const String baseUrl = 'http://localhost:8080';

  /// Socket.IO server URL. Normally the same host as the REST API.
  static const String socketUrl = 'http://localhost:8080';

  /// Default connection timeout for Dio.
  static const Duration connectTimeout = Duration(seconds: 5);

  /// Default receive timeout for Dio.
  static const Duration receiveTimeout = Duration(seconds: 10);

  /// Endpoints
  static const String historyEndpoint = '/api/history';
  static const String deviceEndpoint = '/api/device';
  static const String loginEndpoint = '/api/auth/login';
}
