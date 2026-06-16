import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/models/alert_model.dart';
import 'package:flutter_application_1/utils/app_state.dart';

AlertModel _buildAlert({
  required String id,
  required DateTime time,
  bool acknowledged = false,
  bool read = false,
}) {
  return AlertModel(
    id: id,
    elderlyId: 1,
    elderlyName: 'Elderly 1',
    time: time,
    locationName: 'Test',
    urgency: 'critical',
    message: 'Test alert',
    acknowledged: acknowledged,
    read: read,
    type: 'manual',
    latitude: 10.762622,
    longitude: 106.660172,
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('alertBadgeCount', () {
    test('đếm cảnh báo chưa đọc hoặc chưa xử lý', () async {
      final state = AppState();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      state.stopSimulation();
      state.clearAlertHistory();

      final now = DateTime.now();
      state.addAlert(_buildAlert(
        id: 'ack_read',
        time: now.subtract(const Duration(hours: 1)),
        acknowledged: true,
        read: true,
      ));
      state.addAlert(_buildAlert(
        id: 'unack_read',
        time: now.subtract(const Duration(minutes: 30)),
        acknowledged: false,
        read: true,
      ));
      state.addAlert(_buildAlert(
        id: 'ack_unread',
        time: now.subtract(const Duration(minutes: 20)),
        acknowledged: true,
        read: false,
      ));
      state.addAlert(_buildAlert(
        id: 'unack_unread',
        time: now,
        acknowledged: false,
        read: false,
      ));

      expect(state.alertBadgeCount, 3);
    });
  });

  group('markAllAlertsRead', () {
    test('xóa cờ read nhưng giữ nguyên acknowledged', () async {
      final state = AppState();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      state.stopSimulation();
      state.clearAlertHistory();

      final now = DateTime.now();
      state.addAlert(_buildAlert(
        id: 'unack_unread',
        time: now,
        acknowledged: false,
        read: false,
      ));
      state.addAlert(_buildAlert(
        id: 'ack_unread',
        time: now.subtract(const Duration(minutes: 5)),
        acknowledged: true,
        read: false,
      ));

      expect(state.alertBadgeCount, 2);
      state.markAllAlertsRead();
      expect(state.alertBadgeCount, 1);
      expect(
        state.alerts.firstWhere((a) => a.id == 'unack_unread').read,
        isTrue,
      );
      expect(
        state.alerts.firstWhere((a) => a.id == 'ack_unread').read,
        isTrue,
      );
      expect(
        state.alerts.firstWhere((a) => a.id == 'unack_unread').acknowledged,
        isFalse,
      );
    });
  });

  group('acknowledgeAlert', () {
    test('đồng thời đánh dấu read', () async {
      final state = AppState();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      state.stopSimulation();
      state.clearAlertHistory();

      state.addAlert(_buildAlert(
        id: 'unack_unread',
        time: DateTime.now(),
        acknowledged: false,
        read: false,
      ));

      state.acknowledgeAlert('unack_unread');
      final alert = state.alerts.firstWhere((a) => a.id == 'unack_unread');
      expect(alert.acknowledged, isTrue);
      expect(alert.read, isTrue);
      expect(state.alertBadgeCount, 0);
    });
  });
}
