import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/models/user_profile.dart';
import 'package:flutter_application_1/services/api_client.dart';
import 'package:flutter_application_1/utils/app_state.dart';
import 'package:flutter_application_1/widgets/home_user_header.dart';

/// 2 relatives: rel1 online, rel2 offline → count ban đầu "1/2 online".
List<Map<String, dynamic>> _relativesDto() => [
      {
        'id': 1,
        'name': 'Bà A',
        'avatar': '',
        'safeZoneRadius': 500.0,
        'safeZoneLat': 10.762622,
        'safeZoneLng': 106.660172,
        'contacts': [],
        'latestStatus': {
          'isOnline': true,
          'batteryPercent': 80,
          'heartRateBpm': 75,
          'spo2Percent': 97,
          'timestamp': '2026-06-18T10:00:00.000Z',
        },
        'latestLocation': {
          'latitude': 10.762622,
          'longitude': 106.660172,
          'timestamp': '2026-06-18T10:00:00.000Z',
        },
      },
      {
        'id': 2,
        'name': 'Ông B',
        'avatar': '',
        'safeZoneRadius': 500.0,
        'safeZoneLat': 10.762622,
        'safeZoneLng': 106.660172,
        'contacts': [],
        'latestStatus': {
          'isOnline': false,
          'batteryPercent': 0,
          'heartRateBpm': 0,
          'spo2Percent': 0,
          'timestamp': '2026-06-18T10:00:00.000Z',
        },
        'latestLocation': {
          'latitude': 10.762622,
          'longitude': 106.660172,
          'timestamp': '2026-06-18T10:00:00.000Z',
        },
      },
    ];

http.Client _client() => MockClient((req) async {
      final path = req.url.path;
      if (path == '/api/relatives') {
        return http.Response(
          jsonEncode({'success': true, 'data': _relativesDto()}),
          200,
        );
      }
      if (path == '/api/alerts') {
        return http.Response(jsonEncode({'success': true, 'data': []}), 200);
      }
      return http.Response('{"success":true}', 200);
    });

void main() {
  testWidgets('count online/offline cập nhật realtime khi thiết bị đổi trạng thái',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    ApiClient.instance.setHttpClientForTesting(_client());
    await AppState().logout();
    // Profile có avatarUrl rỗng → ProfileAvatar hiển thị placeholder (không load ảnh network).
    await AppState().setCurrentAccount(
      const UserProfile(
        id: 'u1',
        name: 'Người Thân',
        email: 't@e.com',
        phone: '',
        avatarUrl: '',
        avatarLocalPath: '',
      ),
      'jwt-token',
    );

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HomeUserHeader())),
    );
    await tester.pumpAndSettle();

    // rel1 online, rel2 offline → 1/2 online
    expect(find.text('1/2 online'), findsOneWidget);

    // Đảo rel1 (online) → offline qua patch vitals realtime (in-memory, không API).
    final first = AppState().relatives.first;
    AppState().patchElderlyVitals(first.copyWith(isOffline: true));
    await tester.pump();

    expect(find.text('0/2 online'), findsOneWidget);
  });
}