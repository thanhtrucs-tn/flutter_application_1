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

  /// Hàm đăng nhập.
  ///
  /// Trả về thông tin tài khoản nếu thành công, ngược lại trả về `null`.
  /// Thông tin trả về gồm: `id`, `username`, `name`, `email`, `phone`.
  static Future<Map<String, String>?> loginUser(String username, String password) async {
    // Trên web (Chrome): Ưu tiên gọi Backend API để xác thực với MySQL thật
    if (kIsWeb && backendAvailable) {
      return await AuthApiService.login(username, password);
    }

    try {
      final conn = await getConnection();
      if (conn != null) {
        // Sử dụng MySQL thực tế; hỗ trợ đăng nhập bằng username hoặc email
        final isEmail = _isValidEmail(username);
        final column = isEmail ? 'email' : 'username';
        var results = await conn.query(
            'SELECT id, username, name, email, phone FROM users WHERE $column = ? AND password = ?',
            [username, password]);
        await conn.close();
        if (results.isNotEmpty) {
          final row = results.first;
          return _rowToUserInfo(row);
        }
        return null;
      } else {
        // Fallback: Sử dụng SharedPreferences lưu cục bộ
        return await _loginOffline(username, password);
      }
    } catch (e) {
      print('Lỗi đăng nhập: $e. Thử đăng nhập offline...');
      return await _loginOffline(username, password);
    }
  }

  /// Kiểm tra định dạng email cơ bản.
  static bool _isValidEmail(String value) {
    return RegExp(r"^[^\s@]+@[^\s@]+\.[^\s@]+$")
        .hasMatch(value.trim());
  }

  /// Hàm đăng ký.
  ///
  /// [email] là địa chỉ email, bắt buộc với form đăng ký mới.
  /// [name] là họ tên hiển thị (không còn dùng trong đăng ký, giữ lại để
  /// tương thích). Trả về `null` nếu thành công, ngược lại trả về thông báo lỗi.
  static Future<String?> registerUser(
    String username,
    String password, {
    String? email,
    String? name,
  }) async {
    // Trên web (Chrome): Ưu tiên gọi Backend API để insert vào MySQL thật
    if (kIsWeb && backendAvailable) {
      return await AuthApiService.register(
        username,
        password,
        email: email,
        name: name,
      );
    }

    try {
      final conn = await getConnection();
      if (conn != null) {
        // Sử dụng MySQL thực tế
        var result = await conn.query(
            'INSERT INTO users (username, password, email, name) VALUES (?, ?, ?, ?)',
            [username, password, email ?? '', name ?? '']);
        await conn.close();

        if (result.affectedRows! > 0) {
          return null; // Thành công
        }
        return 'Không có dữ liệu nào được ghi.';
      } else {
        // Fallback: Lưu tài khoản offline
        return await _registerOffline(
          username,
          password,
          email: email,
          name: name,
        );
      }
    } catch (e) {
      print('Lỗi đăng ký: $e. Thử đăng ký offline...');
      return await _registerOffline(
        username,
        password,
        email: email,
        name: name,
      );
    }
  }

  /// Cập nhật thông tin cá nhân (họ tên, email, SĐT) của một tài khoản.
  ///
  /// Trả về `true` nếu cập nhật thành công.
  static Future<bool> updateUserProfile(
    String username,
    String name,
    String email,
    String phone,
  ) async {
    if (kIsWeb && backendAvailable) {
      return await AuthApiService.updateProfile(
        username,
        name: name,
        email: email,
        phone: phone,
      );
    }

    try {
      final conn = await getConnection();
      if (conn != null) {
        var result = await conn.query(
          'UPDATE users SET name = ?, email = ?, phone = ? WHERE username = ?',
          [name, email, phone, username],
        );
        await conn.close();
        return result.affectedRows! >= 0;
      } else {
        return await _updateOfflineUserProfile(username, name, email, phone);
      }
    } catch (e) {
      print('Lỗi cập nhật profile: $e. Thử cập nhật offline...');
      return await _updateOfflineUserProfile(username, name, email, phone);
    }
  }

  // --- LOGIC ĐĂNG NHẬP / ĐĂNG KÝ OFFLINE (SHARED PREFERENCES) ---
  //
  // Dữ liệu được lưu dưới dạng JSON Array để tránh lỗi khi username/password
  // chứa ký tự đặc biệt (đặc biệt là dấu ':').
  // Ví dụ lưu: [{"u":"admin","p":"admin123","e":"admin@example.com","n":"Quản trị viên"}]
  //
  // Mỗi nền tảng (web vs native) có key lưu trữ riêng, đảm bảo tài khoản
  // đăng ký ở Chrome chỉ dùng được trên Chrome, và tài khoản ở Windows
  // chỉ dùng được trên Windows — đúng theo yêu cầu "Giữ tách biệt".

  static Future<Map<String, String>?> _loginOffline(
      String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    // Tài khoản admin mặc định — luôn hoạt động trên mọi nền tảng
    if (username == 'admin' && password == 'admin123') {
      return {
        'id': '1',
        'username': 'admin',
        'name': 'Quản trị viên',
        'email': 'admin@soscare.local',
        'phone': '0901234567',
      };
    }

    final List<dynamic> userList = _readOfflineUsers(prefs);
    for (final item in userList) {
      if (item is Map &&
          item['p'].toString() == password &&
          (item['u'].toString() == username ||
              item['e'].toString() == username)) {
        return _offlineUserToInfo(item);
      }
    }
    return null;
  }

  static Future<String?> _registerOffline(
    String username,
    String password, {
    String? email,
    String? name,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final List<dynamic> userList = _readOfflineUsers(prefs);

    // Kiểm tra trùng username
    for (final item in userList) {
      if (item is Map && item['u'].toString() == username) {
        return 'Tên tài khoản này đã tồn tại.';
      }
    }

    // Kiểm tra trùng email (nếu có)
    if (email != null && email.trim().isNotEmpty) {
      for (final item in userList) {
        if (item is Map && (item['e'] ?? '').toString() == email.trim()) {
          return 'Email này đã được sử dụng.';
        }
      }
    }

    // Thêm user mới
    userList.add({
      'u': username,
      'p': password,
      'e': email ?? '',
      'n': name ?? username,
    });
    await prefs.setString(_offlineUsersKey, json.encode(userList));
    return null; // Đăng ký thành công
  }

  static Future<bool> _updateOfflineUserProfile(
    String username,
    String name,
    String email,
    String phone,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final List<dynamic> userList = _readOfflineUsers(prefs);

    bool found = false;
    for (int i = 0; i < userList.length; i++) {
      final item = userList[i];
      if (item is Map && item['u'].toString() == username) {
        userList[i] = {
          ...item,
          'n': name,
          'e': email,
          'ph': phone,
        };
        found = true;
        break;
      }
    }

    // Nếu không tìm thấy user trong danh sách offline (ví dụ tài khoản admin
    // mặc định), vẫn coi là thành công để cho phép lưu profile cục bộ.
    if (!found) return true;
    await prefs.setString(_offlineUsersKey, json.encode(userList));
    return true;
  }

  /// Đọc danh sách user offline từ SharedPreferences.
  /// Hỗ trợ cả 2 format:
  /// - Cũ (lỗi): "username:password" phân cách bằng dấu ':'
  /// - Mới: JSON Array [{"u":"...","p":"...","n":"..."}]
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
        legacy.add({
          'u': parts[0],
          'p': parts.sublist(1).join(':'),
          'e': '',
        });
      }
    }
    return legacy;
  }

  /// Chuyển một dòng user offline thành thông tin tài khoản chuẩn.
  static Map<String, String> _offlineUserToInfo(Map<dynamic, dynamic> item) {
    return {
      'id': item['u'].toString(),
      'username': item['u'].toString(),
      'name': (item['n'] ?? item['u']).toString(),
      'email': (item['e'] ?? '').toString(),
      'phone': (item['ph'] ?? '').toString(),
    };
  }


  /// Chuyển một dòng kết quả MySQL thành thông tin tài khoản chuẩn.
  static Map<String, String> _rowToUserInfo(ResultRow row) {
    String value(dynamic field) {
      final v = row[field];
      return v == null ? '' : v.toString();
    }

    return {
      'id': value('id'),
      'username': value('username'),
      'name': value('name'),
      'email': value('email'),
      'phone': value('phone'),
    };
  }
}
