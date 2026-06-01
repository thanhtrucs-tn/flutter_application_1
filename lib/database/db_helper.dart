import 'package:mysql1/mysql1.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;

/// Lớp hỗ trợ kết nối database MySQL với chế độ tự động dự phòng Offline (SharedPreferences)
class DbHelper {
  static bool _isUsingMock = false;

  /// Kiểm tra xem có đang dùng cơ sở dữ liệu giả lập (offline mode) không
  static bool get isUsingMock => _isUsingMock;

  /// Hàm tạo kết nối tới MySQL
  static Future<MySqlConnection?> getConnection() async {
    String hostIp = '127.0.0.1';
    try {
      if (Platform.isAndroid) {
        hostIp = '10.0.2.2';
      }
    } catch (e) {
      // Chạy trên web/nền tảng khác
    }

    final settings = ConnectionSettings(
      host: hostIp, 
      port: 3306,
      user: 'root',
      db: 'test_123',
      timeout: const Duration(seconds: 2), // Timeout nhanh để không bị treo giao diện
    );

    try {
      final conn = await MySqlConnection.connect(settings);
      _isUsingMock = false;
      return conn;
    } catch (e) {
      print('--- KHÔNG KẾT NỐI ĐƯỢC MYSQL, CHUYỂN SANG MOCK OFFLINE MODE ---');
      print('Chi tiết lỗi kết nối: $e');
      _isUsingMock = true;
      return null;
    }
  }

  /// Hàm đăng nhập
  static Future<bool> loginUser(String username, String password) async {
    try {
      final conn = await getConnection();
      if (conn != null) {
        // Sử dụng MySQL thực tế
        var results = await conn.query(
            'SELECT id FROM users WHERE username = ? AND password = ?',
            [username, password]);
        await conn.close();
        return results.isNotEmpty;
      } else {
        // Fallback: Sử dụng SharedPreferences lưu cục bộ
        return await _loginOffline(username, password);
      }
    } catch (e) {
      print('Lỗi đăng nhập: $e. Thử đăng nhập offline...');
      return await _loginOffline(username, password);
    }
  }

  /// Hàm đăng ký
  static Future<String?> registerUser(String username, String password) async {
    try {
      final conn = await getConnection();
      if (conn != null) {
        // Sử dụng MySQL thực tế
        var result = await conn.query(
            'INSERT INTO users (username, password) VALUES (?, ?)',
            [username, password]);
        await conn.close();
        
        if (result.affectedRows! > 0) {
          return null; // Thành công
        }
        return 'Không có dữ liệu nào được ghi.';
      } else {
        // Fallback: Lưu tài khoản offline
        return await _registerOffline(username, password);
      }
    } catch (e) {
      print('Lỗi đăng ký: $e. Thử đăng ký offline...');
      return await _registerOffline(username, password);
    }
  }

  // --- LOGIC ĐĂNG NHẬP / ĐĂNG KÝ OFFLINE (SHAPED PREFERENCES) ---

  static Future<bool> _loginOffline(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    // Tạo sẵn một tài khoản admin mặc định để dễ đăng nhập nhanh
    if (username == 'admin' && password == 'admin123') {
      return true;
    }

    final List<String> userList = prefs.getStringList('offline_users') ?? [];
    for (String userJson in userList) {
      final parts = userJson.split(':');
      if (parts.length == 2 && parts[0] == username && parts[1] == password) {
        return true;
      }
    }
    return false;
  }

  static Future<String?> _registerOffline(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> userList = prefs.getStringList('offline_users') ?? [];
    
    // Kiểm tra xem tài khoản đã tồn tại chưa
    for (String userJson in userList) {
      final parts = userJson.split(':');
      if (parts.length > 0 && parts[0] == username) {
        return 'Tài khoản này đã tồn tại.';
      }
    }

    // Lưu người dùng mới dạng "username:password"
    userList.add('$username:$password');
    await prefs.setStringList('offline_users', userList);
    return null; // Đăng ký thành công
  }
}
