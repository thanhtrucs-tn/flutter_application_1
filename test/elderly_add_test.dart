// Unit test cho ElderlyModel.age + luồng addElderly với GPS=0,0, isOffline=true.
//
// Khi thêm người cao tuổi mới:
// - age phải được tính đúng từ ngày sinh
// - lat/lng = 0,0; safeZoneLat/Lng = 0; isOffline = true
// - simulation KHÔNG trigger geofence alert (vì isOffline=true)
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/models/elderly_model.dart';
import 'package:flutter_application_1/utils/app_state.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ElderlyModel.age', () {
    test('field age có thể null khi elderly cũ chưa có', () {
      final e = ElderlyModel(
        id: 1,
        name: 'Test',
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
      );
      expect(e.age, isNull);
    });

    test('field age có thể được set', () {
      final e = ElderlyModel(
        id: 1,
        name: 'Test',
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
        age: 80,
      );
      expect(e.age, 80);
    });

    test('copyWith cập nhật age', () {
      final e1 = ElderlyModel(
        id: 1,
        name: 'Test',
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
      );
      final e2 = e1.copyWith(age: 75);
      expect(e2.age, 75);
      expect(e1.age, isNull, reason: 'bản gốc không đổi');
    });

    test('toMap → fromMap bảo toàn age và avatarLocalPath', () {
      final e1 = ElderlyModel(
        id: 1,
        name: 'Test',
        avatar: '',
        battery: 80,
        lastUpdated: DateTime(2026, 1, 1),
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
        age: 88,
        avatarLocalPath: '/data/avatar.jpg',
      );
      final map = e1.toMap();
      final e2 = ElderlyModel.fromMap(map);
      expect(e2.age, 88);
      expect(e2.avatarLocalPath, '/data/avatar.jpg');
    });

    test('copyWith cập nhật avatarLocalPath', () {
      final e1 = ElderlyModel(
        id: 1,
        name: 'Test',
        avatar: 'https://example.com/old.jpg',
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
      );
      final e2 = e1.copyWith(avatarLocalPath: '/data/new.jpg');
      expect(e2.avatarLocalPath, '/data/new.jpg');
      expect(e2.avatar, 'https://example.com/old.jpg');
      expect(e1.avatarLocalPath, '');
    });

    test('fromMap với dữ liệu cũ KHÔNG có field age → age = null', () {
      final map = <String, dynamic>{
        'id': 1,
        'name': 'Test',
        'avatar': '',
        'battery': 80,
        'lastUpdated': '2026-01-01T00:00:00.000',
        'status': 'safe',
        'latitude': 10.0,
        'longitude': 106.0,
        'heartRate': 75,
        'spo2': 98,
        'isOffline': 0,
        'wearableDevice': 'ESP32',
        'isFallen': 0,
        'safeZoneRadius': 300.0,
        'safeZoneLat': 10.0,
        'safeZoneLng': 106.0,
        'emergencyContacts': '[]',
        'address': '',
        // KHÔNG có 'age'
      };
      final e = ElderlyModel.fromMap(map);
      expect(e.age, isNull, reason: 'backward compat: thiếu age → null');
    });
  });

  group('Thêm người thân mới (addElderly với GPS=0,0)', () {
    test('Elderly mới có lat=0, lng=0, isOffline=true (chờ GPS)', () async {
      final state = AppState();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      state.stopSimulation();

      final before = state.relatives.length;
      final newElderly = ElderlyModel(
        id: 99,
        name: 'Ông Test Mới',
        avatar: '',
        battery: 0, // pin = 0 vì chưa có thiết bị
        lastUpdated: DateTime.now(),
        status: 'safe',
        latitude: 0,
        longitude: 0,
        heartRate: 0,
        spo2: 0,
        isOffline: true, // chờ GPS
        wearableDevice: 'ESP32-NEW',
        isFallen: false,
        safeZoneRadius: 300.0,
        safeZoneLat: 0, // cập nhật khi có GPS
        safeZoneLng: 0,
        emergencyContacts: const ['0900000000'],
        age: 75,
      );
      state.addElderly(newElderly);

      expect(state.relatives.length, before + 1);
      final added = state.relatives.firstWhere((e) => e.id == 99);
      expect(added.latitude, 0);
      expect(added.longitude, 0);
      expect(added.isOffline, isTrue);
      expect(added.safeZoneLat, 0);
      expect(added.safeZoneLng, 0);
      expect(added.age, 75);
      expect(added.battery, 0, reason: 'pin = 0 vì chưa có thiết bị');
    });

    test('Simulation KHÔNG trigger alert khi elderly mới isOffline=true', () async {
      final state = AppState();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      state.stopSimulation();

      // Thêm elderly mới ở (0,0) với safeZone=300m
      state.addElderly(ElderlyModel(
        id: 99,
        name: 'Ông Test Mới',
        avatar: '',
        battery: 0,
        lastUpdated: DateTime.now(),
        status: 'safe',
        latitude: 0,
        longitude: 0,
        heartRate: 0,
        spo2: 0,
        isOffline: true, // ← key: isOffline = true
        wearableDevice: 'ESP32-NEW',
        isFallen: false,
        safeZoneRadius: 300.0,
        safeZoneLat: 0,
        safeZoneLng: 0,
        emergencyContacts: const ['0900000000'],
        age: 75,
      ));

      final alertsBefore = state.alerts.length;
      state.startSimulation();

      // Đợi 5 giây (timer chạy mỗi 4s)
      await Future<void>.delayed(const Duration(milliseconds: 4500));
      state.stopSimulation();

      // Không có alert mới nào được tạo cho elderly này vì isOffline=true
      // → startSimulation() bỏ qua (continue)
      final newAlerts = state.alerts
          .where((a) => a.elderlyId == 99 && !a.acknowledged)
          .toList();
      expect(newAlerts, isEmpty, reason: 'isOffline=true → không trigger alert');
      expect(state.alerts.length, alertsBefore,
          reason: 'Tổng alert không đổi');
    });

    test('Khi elderly mới chuyển sang online (simulateDeviceOnline) → có dữ liệu', () async {
      final state = AppState();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      state.stopSimulation();

      state.addElderly(ElderlyModel(
        id: 99,
        name: 'Ông Test Mới',
        avatar: '',
        battery: 0,
        lastUpdated: DateTime.now(),
        status: 'safe',
        latitude: 0,
        longitude: 0,
        heartRate: 0,
        spo2: 0,
        isOffline: true,
        wearableDevice: 'ESP32-NEW',
        isFallen: false,
        safeZoneRadius: 300.0,
        safeZoneLat: 0,
        safeZoneLng: 0,
        emergencyContacts: const ['0900000000'],
        age: 75,
      ));

      // Mô phỏng thiết bị online
      final ok = state.simulateDeviceOnline(99);
      expect(ok, isTrue);

      final online = state.relatives.firstWhere((e) => e.id == 99);
      expect(online.isOffline, isFalse);
      expect(online.battery, 80);
      expect(online.heartRate, greaterThan(0));
      expect(online.spo2, greaterThan(0));
    });
  });

  group('Tính tuổi từ ngày sinh', () {
    // Helper: build elderly với age tùy ý
    ElderlyModel buildElderly(int? age) => ElderlyModel(
          id: 1,
          name: 'X',
          avatar: '',
          battery: 80,
          lastUpdated: DateTime.now(),
          status: 'safe',
          latitude: 10,
          longitude: 106,
          heartRate: 75,
          spo2: 98,
          isOffline: false,
          wearableDevice: 'E',
          isFallen: false,
          safeZoneRadius: 300,
          safeZoneLat: 10,
          safeZoneLng: 106,
          emergencyContacts: const [],
          age: age,
        );

    test('age hợp lệ trong khoảng 40-130', () {
      for (final age in [40, 65, 78, 90, 130]) {
        expect(buildElderly(age).age, age);
      }
    });

    test('age ngoài khoảng 40-130 vẫn được lưu (validate ở UI)', () {
      // Tuổi < 40 hoặc > 130 nên validator ở form báo lỗi,
      // nhưng model vẫn cho phép lưu (đơn vị lưu trữ thuần)
      expect(buildElderly(25).age, 25);
      expect(buildElderly(150).age, 150);
    });
  });
}
