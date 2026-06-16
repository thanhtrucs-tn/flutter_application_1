import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sos_care_app/features/sos_care/application/services/notification_service.dart';
import 'package:sos_care_app/features/sos_care/application/services/socket_io_service.dart';
import 'package:sos_care_app/features/sos_care/presentation/providers/providers.dart';

/// Stub notification service that does nothing, used in widget tests where
/// the real local notifications plugin is unavailable.
class StubNotificationService extends NotificationService {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> showAlertNotification({
    required String title,
    required String body,
    String? payload,
  }) async {}
}

/// Stub Socket.IO service that never connects, avoiding timer leaks in
/// widget tests.
class StubSocketIOService extends SocketIOService {
  @override
  void connect() {}

  @override
  void disconnect() {}

  @override
  bool get isConnected => false;
}

/// Common provider overrides for widget tests.
List<Override> get testOverrides => [
  notificationServiceProvider.overrideWithValue(StubNotificationService()),
  socketIOServiceProvider.overrideWithValue(StubSocketIOService()),
];
