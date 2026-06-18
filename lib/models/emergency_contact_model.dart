/// Mô tả 1 người liên hệ khẩn cấp của người cao tuổi.
///
/// Dùng model riêng thay vì `List<String>` để vừa hiển thị được tên + quan hệ,
/// vừa serialize/deserialize an toàn với JSON (giữ tương thích với dữ liệu
/// cũ dạng chuỗi "Tên: SĐT" đã có sẵn trong `ElderlyModel.emergencyContacts`).
class EmergencyContactModel {
  final String name;
  final String phone;
  final String relationship; // VD: Con trai, Con gái, Con rể, Bạn bè, Hàng xóm...

  const EmergencyContactModel({
    required this.name,
    required this.phone,
    this.relationship = '',
  });

  /// Trả về chuỗi định dạng "Tên (Quan hệ): SĐT" để lưu ngược vào
  /// `ElderlyModel.emergencyContacts` (giữ tương thích).
  String toStorageString() {
    if (relationship.isEmpty) return '$name: $phone';
    return '$name ($relationship): $phone';
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'relationship': relationship,
      };

  factory EmergencyContactModel.fromMap(Map<String, dynamic> map) {
    return EmergencyContactModel(
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      relationship: map['relationship'] as String? ?? '',
    );
  }

  /// Parse ngược chuỗi lưu trữ "Tên (Quan hệ): SĐT" (hoặc "Tên: SĐT") thành
  /// structured contact. Dùng khi gửi contacts lên server.
  factory EmergencyContactModel.fromStorageString(String raw) {
    final idx = raw.indexOf(':');
    if (idx < 0) {
      return EmergencyContactModel(name: raw.trim(), phone: '');
    }
    var name = raw.substring(0, idx).trim();
    final phone = raw.substring(idx + 1).trim();
    String relationship = '';
    // Tách "(Quan hệ)" ở cuối phần tên nếu có.
    if (name.endsWith(')')) {
      final open = name.lastIndexOf('(');
      if (open > 0) {
        relationship = name.substring(open + 1, name.length - 1).trim();
        name = name.substring(0, open).trim();
      }
    }
    return EmergencyContactModel(
      name: name,
      phone: phone,
      relationship: relationship,
    );
  }
}
