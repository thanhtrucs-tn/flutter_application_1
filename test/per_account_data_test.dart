// Unit test cho cô lập dữ liệu theo tài khoản.
// Đảm bảo relatives và alerts của tài khoản này không lộ sang tài khoản khác,
// và setCurrentAccount tải đúng dữ liệu riêng.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/models/elderly_model.dart';
import 'package:flutter_application_1/models/alert_model.dart';
import 'package:flutter_application_1/utils/app_state.dart';

ElderlyModel _buildElderly(int id, String name) => ElderlyModel(
      id: id,
      name: name,
      avatar: '',
      battery: 80,
      lastUpdated: DateTime.now(),
      status: 'safe',
      latitude: 10,
      longitude: 106,
      heartRate: 75,
      spo2: 98,
      isOffline: false,
      wearableDevice: 'ESP32',
      isFallen: false,
      safeZoneRadius: 300,
      safeZoneLat: 10,
      safeZoneLng: 106,
      emergencyContacts: const [],
      address: '',
      age: 70,
    );

void main() {
  group('Per-account data isolation', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('Tài khoản mới bắt đầu với danh sách người thân rỗng', () async {
      final state = AppState();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      state.stopSimulation();

      await state.setCurrentAccount('new_user');
      expect(state.relatives, isEmpty);
    });

    test('Dữ liệu người thân được lưu riêng theo tài khoản', () async {
      final state = AppState();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      state.stopSimulation();

      await state.setCurrentAccount('alice');
      state.addElderly(_buildElderly(1, 'Alice Elderly'));

      await state.setCurrentAccount('bob');
      expect(state.relatives, isEmpty);

      await state.setCurrentAccount('alice');
      expect(state.relatives.length, 1);
      expect(state.relatives.first.name, 'Alice Elderly');
    });

    test('Cảnh báo được lưu riêng theo tài khoản', () async {
      final state = AppState();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      state.stopSimulation();

      await state.setCurrentAccount('alice');
      state.addAlert(AlertModel(
        id: 'alert_alice_1',
        elderlyId: 1,
        elderlyName: 'Alice Elderly',
        time: DateTime.now(),
        locationName: 'Test',
        urgency: 'critical',
        message: 'Alice alert',
        acknowledged: false,
        latitude: 10,
        longitude: 106,
      ));

      await state.setCurrentAccount('bob');
      expect(state.alerts, isEmpty);

      await state.setCurrentAccount('alice');
      expect(state.alerts.length, 1);
      expect(state.alerts.first.message, 'Alice alert');
    });

    test('Xóa người thân chỉ ảnh hưởng tài khoản hiện tại', () async {
      final state = AppState();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      state.stopSimulation();

      await state.setCurrentAccount('alice');
      state.addElderly(_buildElderly(1, 'Alice Elderly'));

      await state.setCurrentAccount('bob');
      state.addElderly(_buildElderly(2, 'Bob Elderly'));

      await state.deleteElderly(2);
      expect(state.relatives, isEmpty);

      await state.setCurrentAccount('alice');
      expect(state.relatives.length, 1);
      expect(state.relatives.first.name, 'Alice Elderly');
    });
  });
}
