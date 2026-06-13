/// Tiện ích kiểm tra vai trò người dùng.
class RoleUtils {
  /// Trả về `true` nếu [role] là quản trị viên.
  ///
  /// Hỗ trợ cả tiếng Việt (`quản trị viên`) và tiếng Anh (`admin`).
  static bool isAdmin(String role) {
    final normalized = role.toLowerCase();
    return normalized.contains('admin') || normalized.contains('quản trị viên');
  }

  /// Trả về `true` nếu tài khoản có quyền xóa người thân.
  ///
  /// Cho phép cả quản trị viên và tài khoản giám sát.
  static bool canDeleteRelative(String role) {
    final normalized = role.toLowerCase();
    return normalized.contains('admin') ||
        normalized.contains('quản trị viên') ||
        normalized.contains('giám sát');
  }
}
