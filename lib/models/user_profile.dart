/// Lớp lưu trữ thông tin tài khoản của chủ tài khoản (người giám sát).
class UserProfile {
  final String id;
  final String name;
  final String email;
  final String phone;

  /// URL ảnh đại diện từ internet (fallback khi không có ảnh local).
  final String avatarUrl;

  /// Đường dẫn tuyệt đối tới file ảnh local do người dùng tải lên.
  /// Nếu khác rỗng thì ưu tiên hiển thị ảnh local.
  final String avatarLocalPath;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.avatarUrl,
    required this.avatarLocalPath,
  });

  /// Tạo bản sao với một số trường được thay đổi
  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    String? avatarLocalPath,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarLocalPath: avatarLocalPath ?? this.avatarLocalPath,
    );
  }

  /// Khởi tạo mặc định (khi chưa có dữ liệu lưu)
  factory UserProfile.defaultProfile() {
    return const UserProfile(
      id: 'user_main',
      name: 'Người Thân',
      email: 'nguoithan@example.com',
      phone: '0901234567',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
      avatarLocalPath: '',
    );
  }

  /// Đọc từ Map
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String? ?? 'user_main',
      name: map['name'] as String? ?? 'Người Thân',
      email: map['email'] as String? ?? 'nguoithan@example.com',
      phone: map['phone'] as String? ?? '0901234567',
      avatarUrl: map['avatarUrl'] as String? ??
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
      avatarLocalPath: map['avatarLocalPath'] as String? ?? '',
    );
  }

  /// Ghi ra Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'avatarLocalPath': avatarLocalPath,
    };
  }
}
