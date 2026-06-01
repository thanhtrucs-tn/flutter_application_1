/// Lớp lưu trữ cài đặt cấu hình của ứng dụng
class AppSettings {
  final bool isDarkMode;
  final String languageCode; // 'vi' hoặc 'en'
  final bool isSoundAlertEnabled;
  final bool isAutoCallEnabled;
  final int autoCallTimeoutSeconds; // Số giây chờ phản hồi trước khi tự gọi

  AppSettings({
    required this.isDarkMode,
    required this.languageCode,
    required this.isSoundAlertEnabled,
    required this.isAutoCallEnabled,
    required this.autoCallTimeoutSeconds,
  });

  /// Tạo bản sao
  AppSettings copyWith({
    bool? isDarkMode,
    String? languageCode,
    bool? isSoundAlertEnabled,
    bool? isAutoCallEnabled,
    int? autoCallTimeoutSeconds,
  }) {
    return AppSettings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      languageCode: languageCode ?? this.languageCode,
      isSoundAlertEnabled: isSoundAlertEnabled ?? this.isSoundAlertEnabled,
      isAutoCallEnabled: isAutoCallEnabled ?? this.isAutoCallEnabled,
      autoCallTimeoutSeconds: autoCallTimeoutSeconds ?? this.autoCallTimeoutSeconds,
    );
  }

  /// Khởi tạo mặc định
  factory AppSettings.defaultSettings() {
    return AppSettings(
      isDarkMode: false,
      languageCode: 'vi',
      isSoundAlertEnabled: true,
      isAutoCallEnabled: true,
      autoCallTimeoutSeconds: 30,
    );
  }

  /// Đọc từ Map
  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      isDarkMode: map['isDarkMode'] as bool? ?? false,
      languageCode: map['languageCode'] as String? ?? 'vi',
      isSoundAlertEnabled: map['isSoundAlertEnabled'] as bool? ?? true,
      isAutoCallEnabled: map['isAutoCallEnabled'] as bool? ?? true,
      autoCallTimeoutSeconds: map['autoCallTimeoutSeconds'] as int? ?? 30,
    );
  }

  /// Ghi ra Map
  Map<String, dynamic> toMap() {
    return {
      'isDarkMode': isDarkMode,
      'languageCode': languageCode,
      'isSoundAlertEnabled': isSoundAlertEnabled,
      'isAutoCallEnabled': isAutoCallEnabled,
      'autoCallTimeoutSeconds': autoCallTimeoutSeconds,
    };
  }
}
