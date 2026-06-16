import 'package:dio/dio.dart';

import '../config/api_config.dart';

/// Configured Dio client for the SOS Care backend.
class DioClient {
  final Dio dio;

  DioClient._(this.dio);

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
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // ignore: avoid_print
          print('✅ RESPONSE: ${response.statusCode}');
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
