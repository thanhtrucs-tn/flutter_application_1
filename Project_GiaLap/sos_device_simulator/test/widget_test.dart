import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sos_device_simulator/features/sos_simulator/presentation/screens/home_screen.dart';
import 'package:sos_device_simulator/features/sos_simulator/presentation/widgets/device_info_card.dart';
import 'package:sos_device_simulator/features/sos_simulator/presentation/widgets/sos_button.dart';
import 'package:sos_device_simulator/main.dart';

void main() {
  testWidgets('App renders home screen with device info', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: SosDeviceSimulatorApp()));
    await tester.pumpAndSettle();

    expect(find.text('SOS Device Simulator'), findsOneWidget);
    expect(find.byType(DeviceInfoCard), findsOneWidget);
    expect(find.byType(SosButton), findsOneWidget);
  });

  testWidgets('SOS button opens confirmation dialog', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ProviderScope(child: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(SosButton));
    await tester.pumpAndSettle();

    expect(find.text('Xác nhận gửi SOS'), findsOneWidget);
    expect(find.text('Gửi SOS'), findsOneWidget);
  });
}
