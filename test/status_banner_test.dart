// Unit test cho StatusBanner sau refactor - widget tóm tắt bất thường + điều hướng.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/models/alert_model.dart';
import 'package:flutter_application_1/utils/app_state.dart';
import 'package:flutter_application_1/widgets/status_banner.dart';

AlertModel _makeAlert({
  required String id,
  required int elderlyId,
  required String name,
  required String urgency,
  required String message,
  required DateTime time,
  bool acknowledged = false,
}) {
  return AlertModel(
    id: id,
    elderlyId: elderlyId,
    elderlyName: name,
    time: time,
    locationName: 'Test',
    urgency: urgency,
    message: message,
    acknowledged: acknowledged,
    latitude: 10.0,
    longitude: 106.0,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('StatusBanner.getUnackedAlerts', () {
    test('chỉ trả về alert chưa acknowledge, sắp xếp giảm dần', () async {
      final state = AppState();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      state.stopSimulation();

      state.addAlert(_makeAlert(
        id: 'a1',
        elderlyId: 1,
        name: 'A',
        urgency: 'warning',
        message: 'msg 1',
        time: DateTime.now(),
      ));
      state.addAlert(_makeAlert(
        id: 'a2',
        elderlyId: 1,
        name: 'A',
        urgency: 'critical',
        message: 'msg 2',
        time: DateTime.now().subtract(const Duration(hours: 1)),
        acknowledged: true,
      ));

      final unacked = StatusBanner.getUnackedAlerts(state);
      expect(unacked.every((a) => !a.acknowledged), isTrue);
      expect(unacked.first.id, 'a1');
    });

    test('trả về list rỗng khi không có alert unacked', () async {
      final state = AppState();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      state.stopSimulation();
      state.clearAlertHistory();

      // Clear alert history để chỉ còn lại alert acknowledged (nếu có)
      // hoặc empty → expect rỗng
      final unacked = StatusBanner.getUnackedAlerts(state);
      expect(unacked, isEmpty);
    });
  });

  group('StatusBanner widget', () {
    Future<AppState> freshState(WidgetTester tester) async {
      // Reset SharedPreferences để AppState load clean
      SharedPreferences.setMockInitialValues({});
      final state = AppState();
      // Dùng runAsync để await thật sự cho async load + timer của simulation
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      state.stopSimulation();
      // Clear alerts sau khi load xong để đảm bảo state sạch
      state.clearAlertHistory();
      await tester.pump();
      return state;
    }

    testWidgets('Khi status = safe → banner màu xanh, không bấm được', (tester) async {
      final state = await freshState(tester);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AnimatedBuilder(
            animation: state,
            builder: (context, _) => const StatusBanner(status: 'safe'),
          ),
        ),
      ));
      await tester.pump();

      expect(find.text('HỆ THỐNG AN TOÀN'), findsOneWidget);
      expect(find.text('Tất cả người thân đều đang an toàn.'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.text('BẤM ĐỂ XEM CHI TIẾT'), findsNothing);
    });

    testWidgets('Khi status = warning + 1 alert → banner vàng, tóm tắt 1 tên', (tester) async {
      final state = await freshState(tester);

      state.addAlert(_makeAlert(
        id: 'w1',
        elderlyId: 1,
        name: 'Bà A',
        urgency: 'warning',
        message: 'Nhịp tim 115 bpm',
        time: DateTime.now(),
      ));

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AnimatedBuilder(
            animation: state,
            builder: (context, _) => const StatusBanner(status: 'warning'),
          ),
        ),
      ));
      await tester.pump();

      expect(find.text('CẦN CHÚ Ý'), findsOneWidget);
      expect(find.text('Nhịp tim 115 bpm'), findsOneWidget);
      expect(find.byIcon(Icons.warning_rounded), findsOneWidget);
      expect(find.text('BẤM ĐỂ XEM CHI TIẾT'), findsOneWidget);
    });

    testWidgets('Khi status = warning + nhiều alert → banner vàng, liệt kê tên', (tester) async {
      final state = await freshState(tester);

      state.addAlert(_makeAlert(
        id: 'm1',
        elderlyId: 1,
        name: 'Bà A',
        urgency: 'warning',
        message: 'HR 115',
        time: DateTime.now(),
      ));
      state.addAlert(_makeAlert(
        id: 'm2',
        elderlyId: 2,
        name: 'Ông B',
        urgency: 'warning',
        message: 'SpO2 90%',
        time: DateTime.now(),
      ));

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AnimatedBuilder(
            animation: state,
            builder: (context, _) => const StatusBanner(status: 'warning'),
          ),
        ),
      ));
      await tester.pump();

      expect(find.text('CẦN CHÚ Ý'), findsOneWidget);
      expect(find.text('BẤM ĐỂ XEM CHI TIẾT'), findsOneWidget);
      expect(find.textContaining('Bà A'), findsWidgets);
      expect(find.textContaining('Ông B'), findsWidgets);
    });

    testWidgets('Khi status = critical + 1 alert → banner đỏ', (tester) async {
      final state = await freshState(tester);

      state.addAlert(_makeAlert(
        id: 'c1',
        elderlyId: 1,
        name: 'Bà A',
        urgency: 'critical',
        message: 'Té ngã',
        time: DateTime.now(),
      ));

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AnimatedBuilder(
            animation: state,
            builder: (context, _) => const StatusBanner(status: 'critical'),
          ),
        ),
      ));
      await tester.pump();

      expect(find.text('SOS KHẨN CẤP!'), findsOneWidget);
      expect(find.text('Té ngã'), findsOneWidget);
      expect(find.byIcon(Icons.error_rounded), findsOneWidget);
    });

    testWidgets('Banner safe hiển thị số lượng 0 (không có badge)', (tester) async {
      final state = await freshState(tester);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AnimatedBuilder(
            animation: state,
            builder: (context, _) => const StatusBanner(status: 'safe'),
          ),
        ),
      ));
      await tester.pump();

      expect(find.text('BẤM ĐỂ XEM CHI TIẾT'), findsNothing);
    });
  });
}
