import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/dio_client.dart';
import '../../application/services/notification_service.dart';
import '../../application/services/socket_io_service.dart';
import '../../data/repositories/sos_care_remote_repository.dart';
import '../../domain/entities/care_alert.dart';
import '../../domain/entities/care_device.dart';
import '../../domain/repositories/sos_care_repository.dart';
import 'care_alerts_notifier.dart';
import 'care_devices_notifier.dart';
import 'socket_state_notifier.dart';

/// Dio client provider.
final dioProvider = Provider((ref) => DioClient.create().dio);

/// REST repository provider.
final sosCareRepositoryProvider = Provider<SosCareRepository>((ref) {
  return SosCareRemoteRepository(ref.watch(dioProvider));
});

/// Notification service singleton.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService();
  service.initialize();
  return service;
});

/// Socket.IO service singleton.
final socketIOServiceProvider = Provider<SocketIOService>((ref) {
  return SocketIOService();
});

/// Provider for realtime alert list.
final careAlertsNotifierProvider =
    StateNotifierProvider<CareAlertsNotifier, List<CareAlert>>((ref) {
  return CareAlertsNotifier(
    notificationService: ref.watch(notificationServiceProvider),
  );
});

/// Provider for monitored devices with latest status/location.
final careDevicesNotifierProvider =
    StateNotifierProvider<CareDevicesNotifier, List<CareDevice>>((ref) {
  return CareDevicesNotifier();
});

/// Provider for Socket.IO connection state.
final socketStateNotifierProvider =
    StateNotifierProvider<SocketStateNotifier, SocketConnectionState>((ref) {
  return SocketStateNotifier();
});

/// Provider for currently selected device.
final selectedDeviceProvider = StateProvider<CareDevice?>((ref) => null);
