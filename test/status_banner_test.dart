// Unit + widget test cho StatusBanner sau refactor (dữ liệu thật từ AppState,
// không còn simulation). Alert được seed qua upsertAlert (in-memory, sync).
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
  String type = 'vital',
  bool acknowledged = false,
}) =>
    AlertModel(
      id: id,
      elderlyId: elderlyId,
      elderlyName: name,
      time: time,
      locationName: 'Test',
      urgency: urgency,
      message: message,
      acknowledged: acknowledged,
      type: type,
      latitude: 10.0,
      longitude: 106.0,
    );

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppState().logout(); // reset singleton về rỗng
  });

  group('StatusBanner.getUnackedAlerts', () {
    test('chỉ trả về alert chưa acknowledge, sắp xếp giảm dần', () {
      final state = AppState();
      state.upsertAlert(_makeAlert(
        id: 'a1',
        elderlyId: 1,
        name: 'A',
        urgency: 'warning',
        message: 'msg 1',
        time: DateTime.now(),
      ));
      state.upsertAlert(_makeAlert(
        id: 'a2',
        elderlyId: 1,
        name: 'A',
        urgency: 'critical',
        message: 'msg 2',
        type: 'sos',
        time: DateTime.now().subtract(const Duration(hours: 1)),
        acknowledged: true,
      ));

      final unacked = StatusBanner.getUnackedAlerts(state);
      expect(unacked.every((a) => !a.acknowledged), isTrue);
      expect(unacked.first.id, 'a1'); // a1 mới hơn a2
    });

    test('trả về list rỗng khi không có alert unacked', () {
      expect(StatusBanner.getUnackedAlerts(AppState()), isEmpty);
    });
  });

  group('StatusBanner widget', () {
    testWidgets('Khi status = safe → banner xanh, không bấm được', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AnimatedBuilder(
            animation: AppState(),
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

    testWidgets('Khi status = warning + 1 alert → banner vàng, tóm tắt message',
        (tester) async {
      AppState().upsertAlert(_makeAlert(
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
            animation: AppState(),
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

    testWidgets('Khi status = warning + nhiều alert → liệt kê tên', (tester) async {
      AppState().upsertAlert(_makeAlert(
        id: 'm1',
        elderlyId: 1,
        name: 'Bà A',
        urgency: 'warning',
        message: 'HR 115',
        time: DateTime.now(),
      ));
      AppState().upsertAlert(_makeAlert(
        id: 'm2',
        elderlyId: 2,
        name: 'Ông B',
        urgency: 'warning',
        message: 'SpO2 90%',
        time: DateTime.now().subtract(const Duration(minutes: 1)),
      ));

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AnimatedBuilder(
            animation: AppState(),
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
      AppState().upsertAlert(_makeAlert(
        id: 'c1',
        elderlyId: 1,
        name: 'Bà A',
        urgency: 'critical',
        message: 'Té ngã',
        type: 'fall',
        time: DateTime.now(),
      ));

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AnimatedBuilder(
            animation: AppState(),
            builder: (context, _) => const StatusBanner(status: 'critical'),
          ),
        ),
      ));
      await tester.pump();

      expect(find.text('SOS KHẨN CẤP!'), findsOneWidget);
      expect(find.text('Té ngã'), findsOneWidget);
      expect(find.byIcon(Icons.error_rounded), findsOneWidget);
    });
  });
}