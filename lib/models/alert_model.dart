/// Lớp mô tả sự cố khẩn cấp (Cảnh báo SOS)
class AlertModel {
  final String id;
  final int elderlyId;
  final String elderlyName;
  final DateTime time;
  final String locationName;
  final String urgency; // 'critical' (Đỏ), 'warning' (Vàng)
  final String message; // Ví dụ: "Bà Nguyễn Thị A cần hỗ trợ"
  final bool acknowledged; // Xác nhận đã xử lý
  final double latitude;
  final double longitude;

  AlertModel({
    required this.id,
    required this.elderlyId,
    required this.elderlyName,
    required this.time,
    required this.locationName,
    required this.urgency,
    required this.message,
    required this.acknowledged,
    required this.latitude,
    required this.longitude,
  });

  /// Tạo bản sao
  AlertModel copyWith({
    String? id,
    int? elderlyId,
    String? elderlyName,
    DateTime? time,
    String? locationName,
    String? urgency,
    String? message,
    bool? acknowledged,
    double? latitude,
    double? longitude,
  }) {
    return AlertModel(
      id: id ?? this.id,
      elderlyId: elderlyId ?? this.elderlyId,
      elderlyName: elderlyName ?? this.elderlyName,
      time: time ?? this.time,
      locationName: locationName ?? this.locationName,
      urgency: urgency ?? this.urgency,
      message: message ?? this.message,
      acknowledged: acknowledged ?? this.acknowledged,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  /// Khởi tạo từ Map
  factory AlertModel.fromMap(Map<String, dynamic> map) {
    return AlertModel(
      id: map['id'] as String,
      elderlyId: map['elderlyId'] as int,
      elderlyName: map['elderlyName'] as String,
      time: DateTime.parse(map['time'] as String),
      locationName: map['locationName'] as String,
      urgency: map['urgency'] as String,
      message: map['message'] as String,
      acknowledged: (map['acknowledged'] as int? ?? 0) == 1,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
    );
  }

  /// Chuyển sang Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'elderlyId': elderlyId,
      'elderlyName': elderlyName,
      'time': time.toIso8601String(),
      'locationName': locationName,
      'urgency': urgency,
      'message': message,
      'acknowledged': acknowledged ? 1 : 0,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
