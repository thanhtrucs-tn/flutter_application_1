import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/models/alert_model.dart';
import 'package:flutter_application_1/services/api_client.dart';
import 'package:flutter_application_1/utils/app_state.dart';

/// Mock HTTP luôn trả 200 success — đủ cho acknowledge/markAllRead (PATCH/POST
/// /api/alerts) không chạm network thật.
http.Client _okClient() =>
    MockClient((_) async => http.Response('{"success":true}', 200));

AlertModel _alert({
  required String id,
  required DateTime time,
  bool acknowledged = false,
  bool read = false,
  String urgency = 'warning',
  String type = 'vital',
}) =>
    AlertModel(
      id: id,
      elderlyId: 1,
      elderlyName: 'Elderly 1',
      time: time,
      locationName: 'Test',
      urgency: urgency,
      message: 'Alert $id',
      acknowledged: acknowledged,
      read: read,
      type: type,
      latitude: 10.0,
      longitude: 106.0,
    );

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    ApiClient.instance.setHttpClientForTesting(_okClient());
    await AppState().logout(); // reset singleton về rỗng (không mock default)
  });

  group('alertBadgeCount', () {
    test('đếm cảnh báo chưa đọc hoặc chưa xử lý', () {
      final state = AppState();
      final now = DateTime.now();
      state.upsertAlert(_alert(
        id: 'ack_read',
        time: now.subtract(const Duration(hours: 1)),
        acknowledged: true,
        read: true,
      ));
      state.upsertAlert(_alert(
        id: 'unack_read',
        time: now.subtract(const Duration(minutes: 30)),
        acknowledged: false,
        read: true,
      ));
      state.upsertAlert(_alert(
        id: 'ack_unread',
        time: now.subtract(const Duration(minutes: 20)),
        acknowledged: true,
        read: false,
      ));
      state.upsertAlert(_alert(
        id: 'unack_unread',
        time: now,
        acknowledged: false,
        read: false,
      ));
      expect(state.alertBadgeCount, 3);
    });

    test('rỗng khi chưa có alert', () {
      expect(AppState().alertBadgeCount, 0);
    });
  });

  group('markAllAlertsRead', () {
    test('xóa cờ read nhưng giữ nguyên acknowledged (qua API)', () async {
      final state = AppState();
      final now = DateTime.now();
      state.upsertAlert(_alert(
        id: 'unack_unread',
        time: now,
        acknowledged: false,
        read: false,
      ));
      state.upsertAlert(_alert(
        id: 'ack_unread',
        time: now.subtract(const Duration(minutes: 5)),
        acknowledged: true,
        read: false,
      ));
      expect(state.alertBadgeCount, 2);

      await state.markAllAlertsRead();

      // unack_unread vẫn đếm vì !acknowledged (read=true nhưng ack=false).
      expect(state.alertBadgeCount, 1);
      expect(state.alerts.firstWhere((a) => a.id == 'unack_unread').read, isTrue);
      expect(state.alerts.firstWhere((a) => a.id == 'ack_unread').read, isTrue);
      expect(
        state.alerts.firstWhere((a) => a.id == 'unack_unread').acknowledged,
        isFalse,
      );
    });
  });

  group('acknowledgeAlert', () {
    test('đánh dấu acknowledged + read qua API', () async {
      final state = AppState();
      state.upsertAlert(_alert(
        id: 'unack_unread',
        time: DateTime.now(),
        acknowledged: false,
        read: false,
      ));

      await state.acknowledgeAlert('unack_unread');

      final alert = state.alerts.firstWhere((a) => a.id == 'unack_unread');
      expect(alert.acknowledged, isTrue);
      expect(alert.read, isTrue);
      expect(state.alertBadgeCount, 0);
    });
  });
}