/// Application-wide constants for SOS Care.
class AppConstants {
  const AppConstants._();

  static const String appName = 'SOS Care';

  /// Default notification channel ID for Android.
  static const String notificationChannelId = 'sos_care_alerts';

  /// Default notification channel name for Android.
  static const String notificationChannelName = 'SOS Care Alerts';

  /// Default notification channel description.
  static const String notificationChannelDescription =
      'Realtime alerts from SOS devices';

  /// Maximum number of realtime alerts kept in memory.
  static const int maxAlertsInMemory = 100;

  /// Auto-reconnect delay for Socket.IO.
  static const Duration socketReconnectDelay = Duration(seconds: 3);
}
