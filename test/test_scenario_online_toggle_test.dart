import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/models/elderly_model.dart';
import 'package:flutter_application_1/screens/test_scenario_screen.dart';
import 'package:flutter_application_1/utils/app_state.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppState.simulateDeviceOffline', () {
    test(
      'thiết bị tồn tại → chuyển isOffline=true, pin/heartRate/spo2=0',
      () async {
        final state = AppState();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        state.stopSimulation();

        final elderly = state.relatives.first;
        state.simulateDeviceOnline(elderly.id);

        final ok = state.simulateDeviceOffline(elderly.id);

        expect(ok, isTrue);
        final updated = state.relatives.firstWhere((e) => e.id == elderly.id);
        expect(updated.isOffline, isTrue);
        expect(updated.battery, 0);
        expect(updated.heartRate, 0);
        expect(updated.spo2, 0);
        expect(updated.lastUpdated.isAfter(elderly.lastUpdated), isTrue);
      },
    );

    test('thiết bị KHÔNG tồn tại → trả về false, không crash', () {
      final state = AppState();
      state.stopSimulation();

      final ok = state.simulateDeviceOffline(99999);
      expect(ok, isFalse);
    });

    test('notifyListeners được gọi → trigger UI rebuild', () async {
      final state = AppState();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      state.stopSimulation();

      int rebuildCount = 0;
      state.addListener(() => rebuildCount++);

      final elderly = state.relatives.first;
      state.simulateDeviceOffline(elderly.id);

      expect(rebuildCount, greaterThanOrEqualTo(1));
    });
  });

  group('TestScenarioScreen device toggle', () {
    testWidgets('offline → tap card → online', (tester) async {
      final state = AppState();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      state.stopSimulation();

      final elderly = state.relatives.first;
      state.updateElderly(
        elderly.copyWith(isOffline: true, battery: 0, heartRate: 0, spo2: 0),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TestScenarioScreen(
            elderly: state.relatives.firstWhere((e) => e.id == elderly.id),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('THIẾT BỊ ONLINE'), findsOneWidget);

      await tester.tap(find.text('THIẾT BỊ ONLINE'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final updated = state.relatives.firstWhere((e) => e.id == elderly.id);
      expect(updated.isOffline, isFalse);
      expect(updated.battery, 80);
    });

    testWidgets('online → tap card → offline', (tester) async {
      final state = AppState();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      state.stopSimulation();

      final elderly = state.relatives.first;
      state.updateElderly(
        elderly.copyWith(
          isOffline: false,
          battery: 80,
          heartRate: 75,
          spo2: 98,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TestScenarioScreen(
            elderly: state.relatives.firstWhere((e) => e.id == elderly.id),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('THIẾT BỊ OFFLINE'), findsOneWidget);

      await tester.tap(find.text('THIẾT BỊ OFFLINE'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final updated = state.relatives.firstWhere((e) => e.id == elderly.id);
      expect(updated.isOffline, isTrue);
      expect(updated.battery, 0);
      expect(updated.heartRate, 0);
      expect(updated.spo2, 0);
    });
  });
}
