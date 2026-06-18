import 'package:shared_preferences/shared_preferences.dart';

/// Lưu trữ JWT + remember-me trong SharedPreferences.
///
/// Chỉ lưu JWT (KHÔNG lưu mật khẩu — thay cho plaintext password cũ).
/// Remember-me chỉ ghi nhớ username/email để autofill, không bao gồm mật khẩu.
class TokenStorage {
  TokenStorage._();
  static const _tokenKey = 'jwt_token';
  static const _usernameKey = 'saved_username';
  static const _rememberKey = 'remember_me';

  static Future<void> saveToken(String token) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_tokenKey);
  }

  static Future<void> clearToken() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_tokenKey);
  }

  /// Lưu remember-me: chỉ lưu username/email (không lưu password).
  static Future<void> saveRememberMe(String username, bool remember) async {
    final p = await SharedPreferences.getInstance();
    if (remember) {
      await p.setString(_usernameKey, username);
      await p.setBool(_rememberKey, true);
    } else {
      await p.remove(_usernameKey);
      await p.setBool(_rememberKey, false);
    }
  }

  /// Đọc remember-me: trả về username đã lưu + trạng thái remember.
  static Future<({String username, bool remember})> loadRememberMe() async {
    final p = await SharedPreferences.getInstance();
    return (
      username: p.getString(_usernameKey) ?? '',
      remember: p.getBool(_rememberKey) ?? false,
    );
  }
}