import 'package:mysql1/mysql1.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'dart:convert';
import '../services/auth_api_service.dart';

/// Lớp hỗ trợ kết nối database MySQL với chế độ tự động dự phòng Offline (SharedPreferences)
class DbHelper {
  static bool _isUsingMock = false;

  /// Kiểm tra xem có đang dùng cơ sở dữ liệu giả lập (offline mode) không
  static bool get isUsingMock => _isUsingMock;

  /// Kiểm tra đang chạy trên nền tảng web (Chrome, Edge, Firefox...) hay không
  static bool get isRunningOnWeb => kIsWeb;

  /// Kiểm tra đang chạy trên Windows không
  static bool get isRunningOnWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  /// Trạng thái backend API trên web (Chrome): true nếu backend sẵn sàng
  static bool backendAvailable = false;

  /// Trạng thái kết nối hiện tại:
  /// - 'mysql': Đang dùng MySQL trực tiếp (Windows có MySQL chạy)
  /// - 'api': Đang dùng Backend API (Chrome + backend Node.js)
  /// - 'offline': Dùng localStorage/SharedPreferences (không có gì cả)
  static String get connectionMode {
    if (_isUsingMock) {
      // Trên web: nếu backend OK thì mode = 'api', nếu không thì 'offline'
      if (kIsWeb) {
        return backendAvailable ? 'api' : 'offline';
      }
      // Native: nếu MySQL fail thì 'offline'
      return 'offline';
    }
    return 'mysql';
  }

  /// Khóa lưu trữ danh sách user offline (theo nền tảng để tránh xung đột)
  /// - Web (Chrome/Edge...): mỗi origin (domain) có localStorage riêng
  /// - Windows/Android/iOS: mỗi máy có file SharedPreferences riêng
  /// Hai nền tảng lưu ở hai nơi khác nhau, nên tài khoản tách biệt theo môi trường.
  static String get _offlineUsersKey => kIsWeb
      ? 'web_offline_users_v2'
      : 'native_offline_users_v2';

  /// Hàm tạo kết nối tới MySQL
  static Future<MySqlConnection?> getConnection() async {
    // Nếu đang chạy trên web (Chrome/Edge/Firefox/Safari...), MySQL không khả dụng
    // Bỏ qua kết nối, chuyển thẳng sang chế độ Offline (SharedPreferences)
    if (kIsWeb) {
      _isUsingMock = true;
      print('--- ĐANG CHẠY TRÊN WEB (Chrome): SỬ DỤNG OFFLINE MODE ---');
      return null;
    }

    String hostIp = '127.0.0.1';
    // Chỉ kiểm tra Android trên native (không có Platform trên web)
    if (defaultTargetPlatform == TargetPlatform.android) {
      hostIp = '10.0.2.2';
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
    // Trên web (Chrome): Ưu tiên gọi Backend API để xác thực với MySQL thật
    if (kIsWeb && backendAvailable) {
      return await AuthApiService.login(username, password);
    }

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
    // Trên web (Chrome): Ưu tiên gọi Backend API để insert vào MySQL thật
    if (kIsWeb && backendAvailable) {
      return await AuthApiService.register(username, password);
    }

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

  // --- LOGIC ĐĂNG NHẬP / ĐĂNG KÝ OFFLINE (SHARED PREFERENCES) ---
  //
  // Dữ liệu được lưu dưới dạng JSON Array để tránh lỗi khi username/password
  // chứa ký tự đặc biệt (đặc biệt là dấu ':').
  // Ví dụ lưu: [{"u":"admin","p":"admin123"},{"u":"an","p":"1:2"}]
  //
  // Mỗi nền tảng (web vs native) có key lưu trữ riêng, đảm bảo tài khoản
  // đăng ký ở Chrome chỉ dùng được trên Chrome, và tài khoản ở Windows
  // chỉ dùng được trên Windows — đúng theo yêu cầu "Giữ tách biệt".

  static Future<bool> _loginOffline(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    // Tài khoản admin mặc định — luôn hoạt động trên mọi nền tảng
    if (username == 'admin' && password == 'admin123') {
      return true;
    }

    final List<dynamic> userList = _readOfflineUsers(prefs);
    for (final item in userList) {
      if (item is Map &&
          item['u'].toString() == username &&
          item['p'].toString() == password) {
        return true;
      }
    }
    return false;
  }

  static Future<String?> _registerOffline(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final List<dynamic> userList = _readOfflineUsers(prefs);

    // Kiểm tra trùng username
    for (final item in userList) {
      if (item is Map && item['u'].toString() == username) {
        return 'Tài khoản này đã tồn tại.';
      }
    }

    // Thêm user mới
    userList.add({'u': username, 'p': password});
    await prefs.setString(_offlineUsersKey, json.encode(userList));
    return null; // Đăng ký thành công
  }

  /// Đọc danh sách user offline từ SharedPreferences.
  /// Hỗ trợ cả 2 format:
  /// - Cũ (lỗi): "username:password" phân cách bằng dấu ':'
  /// - Mới: JSON Array [{"u":"...","p":"..."}]
  /// Nếu dữ liệu cũ tồn tại, tự động migrate sang format mới.
  static List<dynamic> _readOfflineUsers(SharedPreferences prefs) {
    final raw = prefs.getString(_offlineUsersKey);
    if (raw == null || raw.isEmpty) {
      return <dynamic>[];
    }

    // Thử parse dạng JSON trước (format mới)
    try {
      final decoded = json.decode(raw);
      if (decoded is List) {
        return decoded;
      }
    } catch (_) {
      // Không phải JSON, thử đọc dạng cũ bên dưới
    }

    // Fallback: đọc dạng cũ "user1:pass1,user2:pass2"
    // (một số phiên bản trước có thể đã lưu dạng này)
    final legacy = <dynamic>[];
    for (final entry in raw.split(',')) {
      final parts = entry.split(':');
      if (parts.length >= 2) {
        legacy.add({'u': parts[0], 'p': parts.sublist(1).join(':')});
      }
    }
    return legacy;
  }
}
