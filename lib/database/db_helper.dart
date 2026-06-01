import 'package:mysql1/mysql1.dart';
import 'dart:io' show Platform;

/// Lớp hỗ trợ kết nối database MySQL
class DbHelper {
  /// Hàm tạo kết nối tới MySQL
  static Future<MySqlConnection> getConnection() async {
    // Xác định IP host tùy thuộc vào nền tảng đang chạy
    // Nếu chạy trên máy ảo Android (Emulator) thì dùng 10.0.2.2 để trỏ về localhost của máy tính
    // Nếu chạy trên Windows/Web/iOS thật thì có thể dùng localhost hoặc 127.0.0.1
    String hostIp = '127.0.0.1';
    try {
      if (Platform.isAndroid) {
        hostIp = '10.0.2.2';
      }
    } catch (e) {
      // Bỏ qua lỗi nếu chạy trên nền tảng không hỗ trợ thư viện dart:io (ví dụ: Web)
    }

    // Cấu hình kết nối MySQL.
    final settings = ConnectionSettings(
      host: hostIp, 
      port: 3306,
      user: 'root', // Tên đăng nhập MySQL
      // Nếu không có mật khẩu (XAMPP), không truyền tham số password, hoặc truyền null
      db: 'test_123', // Tên database đã tạo
    );

    return await MySqlConnection.connect(settings);
  }

  /// Hàm đăng nhập
  /// Trả về true nếu tài khoản và mật khẩu đúng
  static Future<bool> loginUser(String username, String password) async {
    try {
      final conn = await getConnection();
      // Truy vấn kiểm tra username và password
      var results = await conn.query(
          'SELECT id FROM users WHERE username = ? AND password = ?',
          [username, password]);
      await conn.close();
      
      // Nếu kết quả trả về có dữ liệu, tức là đăng nhập thành công
      return results.isNotEmpty;
    } catch (e) {
      print('Lỗi đăng nhập: $e');
      return false;
    }
  }

  /// Hàm đăng ký
  /// Trả về null nếu thành công, hoặc chuỗi báo lỗi nếu thất bại
  static Future<String?> registerUser(String username, String password) async {
    try {
      final conn = await getConnection();
      // Thêm dữ liệu tài khoản mới vào bảng users
      var result = await conn.query(
          'INSERT INTO users (username, password) VALUES (?, ?)',
          [username, password]);
      await conn.close();
      
      // Kiểm tra số dòng bị ảnh hưởng
      if (result.affectedRows! > 0) {
        return null; // Thành công
      }
      return 'Không có dữ liệu nào được ghi.';
    } catch (e) {
      print('Lỗi đăng ký: $e');
      return e.toString(); // Trả về chi tiết lỗi
    }
  }
}
