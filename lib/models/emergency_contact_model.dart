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
}
