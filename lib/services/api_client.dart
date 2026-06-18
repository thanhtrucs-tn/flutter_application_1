import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'device_event_mapper.dart';
import 'token_storage.dart';

/// Lỗi chuẩn từ API: mang message + statusCode để UI hiển thị phù hợp.
class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, [this.statusCode = 0]);
  @override
  String toString() => message;
}

/// Singleton HTTP client tới SOS Care backend (Express + JWT, port 8080).
///
/// - Base URL được resolve qua [DeviceEventMapper.resolveBackendUrl]
///   (tự đổi `localhost` → `10.0.2.2` trên Android emulator).
/// - Tự gắn `Authorization: Bearer <jwt>` từ [TokenStorage].
/// - Unwrap envelope `{success, data, message, errors}` — trả về `data`.
/// - HTTP 401 → xóa token + báo `onUnauthorized` (main.dart dùng để về login).
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  String _baseUrl = '';
  void Function()? onUnauthorized;

  /// HTTP client thật (tạo lười khi cần). Trong test, thay bằng MockClient qua
  /// [setHttpClientForTesting] để giả lập response mà không chạm network.
  http.Client? _httpClient;
  http.Client get _client => _httpClient ??= http.Client();

  /// Test seam: thay http.Client bằng mock (vd `package:http/testing` MockClient).
  @visibleForTesting
  void setHttpClientForTesting(http.Client client) => _httpClient = client;

  /// Thiết lập base URL (gọi 1 lần trong main.dart trước khi chạy app).
  void configure(String rawUrl) {
    _baseUrl = DeviceEventMapper.resolveBackendUrl(rawUrl);
  }

  String get baseUrl => _baseUrl;

  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    return (await _send('GET', path, query: query))['data'];
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    return (await _send('POST', path, body: body))['data'];
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    return (await _send('PUT', path, body: body))['data'];
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    return (await _send('PATCH', path, body: body))['data'];
  }

  Future<dynamic> delete(String path) async {
    return (await _send('DELETE', path))['data'];
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
  }) async {
    final base = _baseUrl.isEmpty ? path : '$_baseUrl$path';
    final uri = query == null
        ? Uri.parse(base)
        : Uri.parse(base).replace(queryParameters: query);
    final req = http.Request(method, uri);
    final token = await TokenStorage.getToken();
    if (token != null && token.isNotEmpty) {
      req.headers['Authorization'] = 'Bearer $token';
    }
    if (body != null) {
      req.headers['Content-Type'] = 'application/json';
      req.body = json.encode(body);
    }
    final streamed = await _client.send(req).timeout(const Duration(seconds: 15));
    final res = await http.Response.fromStream(streamed);
    return _parse(res);
  }

  Map<String, dynamic> _parse(http.Response res) {
    Map<String, dynamic> data;
    try {
      data = res.body.isEmpty
          ? <String, dynamic>{}
          : json.decode(res.body) as Map<String, dynamic>;
    } catch (_) {
      data = <String, dynamic>{};
    }
    if (res.statusCode == 401) {
      TokenStorage.clearToken();
      if (onUnauthorized != null) onUnauthorized!();
      throw ApiException(
        (data['message'] as String?) ?? 'Phiên đăng nhập hết hạn',
        401,
      );
    }
    if (res.statusCode >= 400) {
      throw ApiException(
        (data['message'] as String?) ?? 'Lỗi máy chủ (${res.statusCode})',
        res.statusCode,
      );
    }
    return data;
  }
}