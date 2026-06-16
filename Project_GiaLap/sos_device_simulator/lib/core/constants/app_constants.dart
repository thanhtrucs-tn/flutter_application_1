/// Application-wide constants that do not depend on external services.
class AppConstants {
  const AppConstants._();

  /// Display name of the application.
  static const String appName = 'SOS Device Simulator';

  /// Default simulated device identifier.
  static const String defaultDeviceId = 'SOS-DEVICE-001';

  /// Default elderly identifier associated with the simulated device.
  static const String defaultElderlyId = 'ELDERLY-001';

  /// Minimum heart rate value shown on the slider (BPM).
  static const int minHeartRate = 50;

  /// Maximum heart rate value shown on the slider (BPM).
  static const int maxHeartRate = 180;

  /// Heart rate threshold above which an automatic alert is triggered.
  static const int heartRateAlertThreshold = 110;

  /// Default GPS coordinates used when the location service is unavailable.
  static const double defaultLatitude = 10.762622;
  static const double defaultLongitude = 106.660172;

  /// Debounce delay for battery slider API calls.
  static const Duration batteryDebounceDelay = Duration(milliseconds: 500);

  /// Throttle interval for automatic heart rate alerts.
  static const Duration heartRateAlertThrottle = Duration(seconds: 5);
}
