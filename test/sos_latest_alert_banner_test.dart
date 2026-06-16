import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/alert_model.dart';
import 'package:flutter_application_1/widgets/alert_list_item.dart';
import 'package:flutter_application_1/widgets/sos_latest_alert_banner.dart';

AlertModel _makeAlert({
  required String id,
  required DateTime time,
  bool acknowledged = false,
}) {
  return AlertModel(
    id: id,
    elderlyId: 1,
    elderlyName: 'Bà A',
    time: time,
    locationName: 'Nhà',
    urgency: 'critical',
    message: 'Cảnh báo $id',
    acknowledged: acknowledged,
    type: 'fall',
    latitude: 10.0,
    longitude: 106.0,
  );
}

void main() {
  testWidgets('ẩn banner khi không có cảnh báo chưa xử lý', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SosLatestAlertBanner(
          alert: null,
          onTap: (_) {},
        ),
      ),
    ));

    expect(find.byType(AlertListItem), findsNothing);
  });

  testWidgets('hiển thị và nhấn mở chi tiết cảnh báo mới nhất', (tester) async {
    AlertModel? tapped;
    final alert = _makeAlert(id: 'a1', time: DateTime.now());

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SosLatestAlertBanner(
          alert: alert,
          onTap: (a) => tapped = a,
        ),
      ),
    ));

    expect(find.text('Cảnh báo a1'), findsOneWidget);
    expect(find.byType(AlertListItem), findsOneWidget);

    await tester.tap(find.byType(AlertListItem));
    expect(tapped, isNotNull);
    expect(tapped!.id, 'a1');
  });

  testWidgets('thay đổi alert kích hoạt AnimatedSwitcher', (tester) async {
    AlertModel? current = _makeAlert(id: 'a1', time: DateTime.now());
    final second = _makeAlert(
      id: 'a2',
      time: DateTime.now().add(const Duration(seconds: 1)),
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              children: [
                SosLatestAlertBanner(
                  alert: current,
                  onTap: (_) {},
                ),
                ElevatedButton(
                  onPressed: () => setState(() => current = second),
                  child: const Text('swap'),
                ),
              ],
            );
          },
        ),
      ),
    ));

    expect(find.text('Cảnh báo a1'), findsOneWidget);

    await tester.tap(find.text('swap'));
    await tester.pump();

    // Pump frames cho animation của AnimatedSwitcher hoàn tất.
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();

    expect(find.text('Cảnh báo a2'), findsOneWidget);
    expect(find.text('Cảnh báo a1'), findsNothing);
  });
}
