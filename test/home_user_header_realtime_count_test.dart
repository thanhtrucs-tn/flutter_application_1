import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/utils/app_state.dart';
import 'package:flutter_application_1/widgets/home_user_header.dart';

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
  }
}

void main() {
  HttpOverrides.global = _TestHttpOverrides();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    state.stopSimulation();
    state.clearAlertHistory();

    // Tránh load ảnh network trong test bằng cách xóa avatar default.
    state.updateUserProfile(
      state.userProfile.copyWith(avatarUrl: '', avatarLocalPath: ''),
    );
    for (int i = 0; i < state.relatives.length; i++) {
      final r = state.relatives[i];
      state.relatives[i] = r.copyWith(avatar: '', avatarLocalPath: '');
    }
    state.notifyListeners();
  });

  testWidgets('count online/offline cập nhật realtime khi thiết bị đổi trạng thái', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: HomeUserHeader())));
    await tester.pumpAndSettle();

    final state = AppState();
    final initialOnline = state.relatives.where((r) => !r.isOffline).length;
    final total = state.relatives.length;

    expect(find.text('$initialOnline/$total online'), findsOneWidget);

    // Offline một người thân đầu tiên
    final first = state.relatives.first;
    state.updateElderly(first.copyWith(isOffline: true));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final newOnline = state.relatives.where((r) => !r.isOffline).length;
    expect(find.text('$newOnline/$total online'), findsOneWidget);
    expect(newOnline, initialOnline - 1);
  });
}
