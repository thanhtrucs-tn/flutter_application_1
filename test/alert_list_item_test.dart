import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/alert_model.dart';
import 'package:flutter_application_1/widgets/alert_list_item.dart';

AlertModel _makeAlert({
  required DateTime time,
  bool acknowledged = false,
  String urgency = 'critical',
}) {
  return AlertModel(
    id: 'a1',
    elderlyId: 1,
    elderlyName: 'Bà A',
    time: time,
    locationName: 'Nhà',
    urgency: urgency,
    message: 'Cảnh báo test',
    acknowledged: acknowledged,
    type: 'fall',
    latitude: 10.0,
    longitude: 106.0,
  );
}

void main() {
  testWidgets('hiển thị badge thời gian định dạng dd/mm/yyyy - hh:mm:ss', (tester) async {
    final time = DateTime(2026, 6, 17, 14, 5, 9);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AlertListItem(
          alert: _makeAlert(time: time),
          onTap: () {},
        ),
      ),
    ));

    expect(find.text('17/06/2026 - 14:05:09'), findsOneWidget);
  });

  testWidgets('hiển thị CHƯA XỬ LÝ hoặc ĐÃ XỬ LÝ theo acknowledged', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AlertListItem(
          alert: _makeAlert(time: DateTime.now(), acknowledged: false),
          onTap: () {},
        ),
      ),
    ));
    expect(find.text('CHƯA XỬ LÝ'), findsOneWidget);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AlertListItem(
          alert: _makeAlert(time: DateTime.now(), acknowledged: true),
          onTap: () {},
        ),
      ),
    ));
    expect(find.text('ĐÃ XỬ LÝ'), findsOneWidget);
  });

  testWidgets('isLatest=true bật highlight animation widget', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AlertListItem(
          alert: _makeAlert(time: DateTime.now()),
          onTap: () {},
          isLatest: true,
        ),
      ),
    ));

    // Highlight được render dưới dạng AnimatedBuilder / Container có boxShadow
    expect(find.byType(AnimatedBuilder), findsWidgets);
  });
}
