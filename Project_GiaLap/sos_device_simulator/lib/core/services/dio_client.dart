import 'package:dio/dio.dart';

import '../config/api_config.dart';

/// Configured Dio client for the SOS Care backend.
///
/// Provides connection/read timeouts and a logging interceptor so
/// that all outgoing requests and responses are visible during
/// development.
class DioClient {
  final Dio dio;

  DioClient._(this.dio);

  /// Creates a preconfigured [Dio] instance.
  factory DioClient.create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // ignore: avoid_print
          print('➡️ REQUEST: ${options.method} ${options.path}');
          // ignore: avoid_print
          print('Payload: ${options.data}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // ignore: avoid_print
          print('✅ RESPONSE: ${response.statusCode} ${response.data}');
          return handler.next(response);
        },
        onError: (error, handler) {
          // ignore: avoid_print
          print('❌ ERROR: ${error.type} ${error.message}');
          return handler.next(error);
        },
      ),
    );

    return DioClient._(dio);
  }
}
