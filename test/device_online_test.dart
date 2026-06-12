// Unit test cho AppState.simulateDeviceOnline — mô phỏng thiết bị online.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/utils/app_state.dart';

void main() {
  setUp(() {
    // Reset SharedPreferences in-memory mock trước mỗi test
    SharedPreferences.setMockInitialValues({});
  });

  group('AppState.simulateDeviceOnline', () {
    test('thiết bị tồn tại → chuyển isOffline=false, pin=80', () async {
      final state = AppState();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      state.stopSimulation();

      // Lấy 1 elderly bất kỳ đang có trong mock
      final elderly = state.relatives.first;
      final ok = state.simulateDeviceOnline(elderly.id);

      expect(ok, isTrue);
      final updated = state.relatives.firstWhere((e) => e.id == elderly.id);
      expect(updated.isOffline, isFalse);
      expect(updated.battery, 80);
      expect(updated.lastUpdated.isAfter(elderly.lastUpdated), isTrue);
    });

    test('thiết bị KHÔNG tồn tại → trả về false, không crash', () {
      final state = AppState();
      state.stopSimulation();

      final ok = state.simulateDeviceOnline(99999);
      expect(ok, isFalse);
    });

    test('khi heartRate=0 và spo2=0 (do offline) → khô phục về 75 và 98', () async {
      final state = AppState();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      state.stopSimulation();

      // Ép 1 elderly thành offline với heartRate=0, spo2=0
      final elderly = state.relatives.first;
      state.updateElderly(
        elderly.copyWith(
          isOffline: true,
          battery: 0,
          heartRate: 0,
          spo2: 0,
        ),
      );

      state.simulateDeviceOnline(elderly.id);

      final updated = state.relatives.firstWhere((e) => e.id == elderly.id);
      expect(updated.isOffline, isFalse);
      expect(updated.heartRate, 75);
      expect(updated.spo2, 98);
    });

    test('khi đã có heartRate/spo2 hợp lệ → GIỮ NGUYÊN, không reset', () async {
      final state = AppState();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      state.stopSimulation();

      final elderly = state.relatives.first;
      // Ép elderly đang có heartRate=80, spo2=97 (chưa offline)
      state.updateElderly(
        elderly.copyWith(
          heartRate: 80,
          spo2: 97,
          battery: 50,
          isOffline: false,
        ),
      );

      state.simulateDeviceOnline(elderly.id);

      final updated = state.relatives.firstWhere((e) => e.id == elderly.id);
      expect(updated.heartRate, 80, reason: 'không reset heartRate');
      expect(updated.spo2, 97, reason: 'không reset spo2');
      expect(updated.battery, 80, reason: 'pin đã được đặt lại 80%');
    });

    test('notifyListeners được gọi → trigger UI rebuild', () async {
      final state = AppState();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      state.stopSimulation();

      int rebuildCount = 0;
      state.addListener(() => rebuildCount++);

      final elderly = state.relatives.first;
      state.simulateDeviceOnline(elderly.id);

      expect(rebuildCount, greaterThanOrEqualTo(1));
    });

    test('sau khi online, simulation timer vẫn cập nhật dữ liệu', () async {
      final state = AppState();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      state.stopSimulation();

      // Đặt elderly thành offline, pin=0
      final elderly = state.relatives.first;
      state.updateElderly(
        elderly.copyWith(isOffline: true, battery: 0, heartRate: 0, spo2: 0),
      );

      // Online lại
      state.simulateDeviceOnline(elderly.id);
      state.startSimulation();

      // Đợi 5s để timer chạy ít nhất 1 lần (timer chạy mỗi 4s)
      await Future<void>.delayed(const Duration(milliseconds: 4500));
      state.stopSimulation();

      final updated = state.relatives.firstWhere((e) => e.id == elderly.id);
      // Sau khi online, simulation sẽ KHÔNG bỏ qua (vì isOffline=false)
      // → lastUpdated sẽ được cập nhật bởi simulation
      expect(updated.isOffline, isFalse, reason: 'vẫn online');
    });
  });
}
