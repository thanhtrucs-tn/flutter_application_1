import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sos_care_app/features/sos_care/presentation/screens/dashboard_screen.dart';
import 'package:sos_care_app/features/sos_care/presentation/widgets/connection_status_bar.dart';
import 'package:sos_care_app/main.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('App renders SOS Care dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: testOverrides,
        child: const SosCareApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SOS Care'), findsOneWidget);
    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.byType(ConnectionStatusBar), findsOneWidget);
  });
}
