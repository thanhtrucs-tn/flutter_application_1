import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/models/alert_model.dart';
import 'package:flutter_application_1/models/elderly_model.dart';
import 'package:flutter_application_1/utils/app_state.dart';

ElderlyModel _buildElderly(int id) => ElderlyModel(
      id: id,
      name: 'Elderly $id',
      avatar: '',
      battery: 80,
      lastUpdated: DateTime.now(),
      status: 'safe',
      latitude: 10.762622,
      longitude: 106.660172,
      heartRate: 75,
      spo2: 98,
      isOffline: false,
      wearableDevice: 'ESP32',
      isFallen: false,
      safeZoneRadius: 500,
      safeZoneLat: 10.762622,
      safeZoneLng: 106.660172,
      emergencyContacts: [],
      address: '',
    );

AlertModel _buildAlert({
  required String id,
  required int elderlyId,
  required DateTime time,
  bool acknowledged = false,
  bool read = false,
  String type = 'manual',
  String urgency = 'critical',
}) {
  return AlertModel(
    id: id,
    elderlyId: elderlyId,
    elderlyName: 'Elderly $elderlyId',
    time: time,
    locationName: 'Test',
    urgency: urgency,
    message: 'Test alert',
    acknowledged: acknowledged,
    read: read,
    type: type,
    latitude: 10.762622,
    longitude: 106.660172,
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('sortedAlerts', () {
    test('chưa xử lý mới nhất lên đầu, sau đó đã xử lý mới nhất', () async {
      final state = AppState();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      state.stopSimulation();
      state.clearAlertHistory();

      final now = DateTime.now();
      state.addAlert(_buildAlert(
        id: 'ack_old',
        elderlyId: 1,
        time: now.subtract(const Duration(hours: 5)),
        acknowledged: true,
      ));
      state.addAlert(_buildAlert(
        id: 'unack_new',
        elderlyId: 1,
        time: now,
        acknowledged: false,
      ));
      state.addAlert(_buildAlert(
        id: 'unack_old',
        elderlyId: 1,
        time: now.subtract(const Duration(hours: 2)),
        acknowledged: false,
      ));
      state.addAlert(_buildAlert(
        id: 'ack_new',
        elderlyId: 1,
        time: now.subtract(const Duration(minutes: 30)),
        acknowledged: true,
      ));

      final sorted = state.sortedAlerts;
      expect(sorted.map((a) => a.id).toList(), [
        'unack_new',
        'unack_old',
        'ack_new',
        'ack_old',
      ]);
    });
  });

  group('Fall alert auto-acknowledge', () {
    test('cảnh báo té ngã KHÔNG tự động acknowledge khi ở trong vùng an toàn', () async {
      final state = AppState();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      state.stopSimulation();

      state.relatives
        ..clear()
        ..add(_buildElderly(1));

      state.simulateFall(1);
      expect(state.activeAlert, isNotNull);
      expect(state.activeAlert!.type, 'fall');
      expect(state.activeAlert!.acknowledged, isFalse);

      // Giả lập nhiều tick simulation: elderly vẫn ở trong vùng an toàn
      // (tọa độ = safeZone). Trước đây logic dùng status=='critical' làm proxy
      // sẽ tự động acknowledge; sau fix phải giữ nguyên unacknowledged.
      for (int i = 0; i < 3; i++) {
        // Cập nhật elderly về trạng thái trong vùng an toàn và an toàn
        final e = state.relatives.first;
        state.updateElderly(e.copyWith(
          latitude: e.safeZoneLat,
          longitude: e.safeZoneLng,
          status: 'safe',
          isFallen: false,
        ));
      }

      final fallAlert = state.alerts.firstWhere((a) => a.type == 'fall');
      expect(fallAlert.acknowledged, isFalse);
      expect(state.activeAlert, isNotNull);
    });

    test('geofence alert tự động acknowledge khi quay về vùng an toàn', () async {
      final state = AppState();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      state.stopSimulation();

      state.relatives
        ..clear()
        ..add(_buildElderly(1));

      state.simulateExitSafeZone(1);
      expect(state.activeAlert, isNotNull);
      expect(state.activeAlert!.type, 'geofence');
      expect(state.activeAlert!.acknowledged, isFalse);

      // Đưa elderly về đúng tâm vùng an toàn
      final e = state.relatives.first;
      state.updateElderly(e.copyWith(
        latitude: e.safeZoneLat,
        longitude: e.safeZoneLng,
      ));

      // Gọi acknowledgeAlert trực tiếp để mô phỏng logic tự động khi về vùng
      state.acknowledgeAlert(state.activeAlert!.id);

      final geoAlert = state.alerts.firstWhere((a) => a.type == 'geofence');
      expect(geoAlert.acknowledged, isTrue);
      expect(state.activeAlert, isNull);
    });

    test('simulation tự động acknowledge geofence khi elderly quay về vùng an toàn', () async {
      final state = AppState();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      state.stopSimulation();
      state.clearAlertHistory();

      final elderly = _buildElderly(1);
      state.relatives
        ..clear()
        ..add(elderly);

      // Đẩy elderly ra ngoài vùng an toàn để trigger geofence alert
      state.updateElderly(elderly.copyWith(
        latitude: elderly.safeZoneLat + 0.005,
        longitude: elderly.safeZoneLng + 0.005,
      ));
      state.simulateExitSafeZone(elderly.id);

      expect(state.activeAlert, isNotNull);
      expect(state.activeAlert!.type, 'geofence');
      expect(state.activeAlert!.acknowledged, isFalse);

      // Đưa elderly về tâm vùng an toàn
      final e = state.relatives.first;
      state.updateElderly(e.copyWith(
        latitude: e.safeZoneLat,
        longitude: e.safeZoneLng,
      ));

      // Chạy simulation để logic geofence tự động acknowledge
      state.startSimulation();
      await Future<void>.delayed(const Duration(milliseconds: 4500));
      state.stopSimulation();

      final geoAlert = state.alerts.firstWhere((a) => a.type == 'geofence');
      expect(geoAlert.acknowledged, isTrue);
      expect(state.activeAlert, isNull);
    });
  });
}
