/// Lớp lưu trữ cài đặt cấu hình của ứng dụng
class AppSettings {
  final bool isDarkMode;
  final String languageCode; // 'vi' hoặc 'en'
  final bool isSoundAlertEnabled;
  final bool isAutoCallEnabled;
  final int autoCallTimeoutSeconds;
  final bool notifySos;
  final bool notifySafeZone;
  final bool notifyHealth;
  final bool notifyFirmware;

  AppSettings({
    required this.isDarkMode,
    required this.languageCode,
    required this.isSoundAlertEnabled,
    required this.isAutoCallEnabled,
    required this.autoCallTimeoutSeconds,
    required this.notifySos,
    required this.notifySafeZone,
    required this.notifyHealth,
    required this.notifyFirmware,
  });

  /// Tạo bản sao
  AppSettings copyWith({
    bool? isDarkMode,
    String? languageCode,
    bool? isSoundAlertEnabled,
    bool? isAutoCallEnabled,
    int? autoCallTimeoutSeconds,
    bool? notifySos,
    bool? notifySafeZone,
    bool? notifyHealth,
    bool? notifyFirmware,
  }) {
    return AppSettings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      languageCode: languageCode ?? this.languageCode,
      isSoundAlertEnabled: isSoundAlertEnabled ?? this.isSoundAlertEnabled,
      isAutoCallEnabled: isAutoCallEnabled ?? this.isAutoCallEnabled,
      autoCallTimeoutSeconds: autoCallTimeoutSeconds ?? this.autoCallTimeoutSeconds,
      notifySos: notifySos ?? this.notifySos,
      notifySafeZone: notifySafeZone ?? this.notifySafeZone,
      notifyHealth: notifyHealth ?? this.notifyHealth,
      notifyFirmware: notifyFirmware ?? this.notifyFirmware,
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
      notifySos: true,
      notifySafeZone: true,
      notifyHealth: true,
      notifyFirmware: true,
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
      notifySos: map['notifySos'] as bool? ?? true,
      notifySafeZone: map['notifySafeZone'] as bool? ?? true,
      notifyHealth: map['notifyHealth'] as bool? ?? true,
      notifyFirmware: map['notifyFirmware'] as bool? ?? true,
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
      'notifySos': notifySos,
      'notifySafeZone': notifySafeZone,
      'notifyHealth': notifyHealth,
      'notifyFirmware': notifyFirmware,
    };
  }
}
