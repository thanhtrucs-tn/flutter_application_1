import 'api_client.dart';
import '../models/user_profile.dart';

/// Gọi các endpoint auth (register/login/profile) trên backend.
///
/// Backend trả về envelope `{success, data:{user, token}, message}`;
/// [ApiClient] đã unwrap về `data`, nên các hàm dưới nhận `{user, token}` hoặc
/// profile object trực tiếp.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  /// Đăng nhập bằng email + password. Trả về UserProfile + JWT.
  Future<({UserProfile profile, String token})> login(
    String email,
    String password,
  ) async {
    final data = await ApiClient.instance.post(
      '/api/auth/login',
      body: {'email': email, 'password': password},
    ) as Map<String, dynamic>;
    final user = (data['user'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final token = (data['token'] as String?) ?? '';
    return (profile: _toProfile(user), token: token);
  }

  /// Đăng ký tài khoản mới. Trả về UserProfile + JWT (đăng nhập ngay sau đăng ký).
  Future<({UserProfile profile, String token})> register({
  required String email,
  required String password,
  String? name,
  String? phone,
}) async {
    final body = <String, dynamic>{'email': email, 'password': password};
    if (name != null && name.isNotEmpty) body['name'] = name;
    if (phone != null && phone.isNotEmpty) body['phone'] = phone;
    final data = await ApiClient.instance.post(
      '/api/auth/register',
      body: body,
    ) as Map<String, dynamic>;
    final user = (data['user'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final token = (data['token'] as String?) ?? '';
    return (profile: _toProfile(user), token: token);
  }

  /// Lấy profile hiện tại từ server (theo JWT).
  Future<UserProfile> getProfile() async {
    final data = await ApiClient.instance.get('/api/auth/profile')
        as Map<String, dynamic>;
    return _toProfile(data);
  }

  /// Cập nhật profile (name/phone/avatarUrl). Email không chỉnh sửa được
  /// (email là khóa đăng nhập).
  Future<UserProfile> updateProfile({
  String? name,
  String? phone,
  String? avatarUrl,
}) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (phone != null) body['phone'] = phone;
    if (avatarUrl != null) body['avatarUrl'] = avatarUrl;
    final data = await ApiClient.instance.put('/api/auth/profile', body: body)
        as Map<String, dynamic>;
    return _toProfile(data);
  }

  UserProfile _toProfile(Map<String, dynamic> user) {
    return UserProfile(
      id: (user['id'] ?? '').toString(),
      name: (user['name'] ?? '').toString(),
      email: (user['email'] ?? '').toString(),
      phone: (user['phone'] ?? '').toString(),
      avatarUrl: (user['avatarUrl'] ?? '').toString(),
      avatarLocalPath: '',
    );
  }
}