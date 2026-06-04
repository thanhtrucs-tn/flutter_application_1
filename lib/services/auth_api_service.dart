import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service gọi Backend API để đồng bộ tài khoản với MySQL từ trình duyệt web.
///
/// Lý do cần class này:
/// - Trình duyệt web KHÔNG thể kết nối TCP trực tiếp tới MySQL.
/// - Phải có backend Node.js trung gian (xem thư mục ../backend).
/// - Khi chạy trên web, sẽ gọi HTTP thay vì dùng package mysql1.
class AuthApiService {
  /// Base URL của backend. Có thể đổi trong Settings hoặc qua biến môi trường.
  /// - Web: mặc định http://localhost:3000 (backend chạy local)
  /// - Native: dùng MySQL trực tiếp, không cần API này
  static String get baseUrl {
    // Bạn có thể đổi URL tại đây nếu deploy backend lên server thật
    if (kIsWeb) {
      return 'http://localhost:3000';
    }
    return 'http://localhost:3000'; // Native vẫn dùng được nếu muốn test
  }

  /// Kiểm tra kết nối tới backend (chỉ dùng để debug)
  static Future<bool> healthCheck() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/health'))
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['database'] == 'connected';
      }
      return false;
    } catch (e) {
      debugPrint('Lỗi health check: $e');
      return false;
    }
  }

  /// Gọi API đăng ký tài khoản.
  /// Trả về `null` nếu thành công, ngược lại trả về thông báo lỗi.
  static Future<String?> register(String username, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/register'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'username': username, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        debugPrint('✅ Đăng ký thành công qua API: $username');
        return null; // null = không lỗi
      } else {
        return (data['error'] ?? 'Lỗi không xác định').toString();
      }
    } catch (e) {
      debugPrint('❌ Lỗi đăng ký qua API: $e');
      return 'Không kết nối được backend: $e';
    }
  }

  /// Gọi API đăng nhập.
  /// Trả về `true` nếu thành công, `false` nếu sai tài khoản.
  static Future<bool> login(String username, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/login'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'username': username, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      final data = json.decode(response.body) as Map<String, dynamic>;
      final success = response.statusCode == 200 && data['success'] == true;
      if (success) {
        debugPrint('✅ Đăng nhập thành công qua API: $username');
      }
      return success;
    } catch (e) {
      debugPrint('❌ Lỗi đăng nhập qua API: $e');
      return false;
    }
  }
}
