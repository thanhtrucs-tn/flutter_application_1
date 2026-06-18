import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/models/user_profile.dart';
import 'package:flutter_application_1/services/api_client.dart';
import 'package:flutter_application_1/utils/app_state.dart';

Map<String, dynamic> _relativeDto(
  int id, {
  bool online = true,
  int hr = 0,
  int spo2 = 0,
}) =>
    {
      'id': id,
      'name': 'Elderly $id',
      'avatar': '',
      'safeZoneRadius': 500.0,
      'safeZoneLat': 10.762622,
      'safeZoneLng': 106.660172,
      'contacts': [],
      'latestStatus': {
        'isOnline': online,
        'batteryPercent': 80,
        'heartRateBpm': hr,
        'spo2Percent': spo2,
        'timestamp': '2026-06-18T10:00:00.000Z',
      },
      'latestLocation': {
        'latitude': 10.762622,
        'longitude': 106.660172,
        'timestamp': '2026-06-18T10:00:00.000Z',
      },
    };

Map<String, dynamic> _alertDto({
  required int id,
  required int relativeId,
  required String type,
  required String urgency,
  bool ack = false,
  bool read = false,
  String timestamp = '2026-06-18T10:00:00.000Z',
  String message = 'Alert',
}) =>
    {
      'id': id,
      'relativeId': relativeId,
      'timestamp': timestamp,
      'locationName': '',
      'urgency': urgency,
      'message': message,
      'acknowledged': ack,
      'read': read,
      'type': type,
      'latitude': 10.762622,
      'longitude': 106.660172,
    };

/// Mock routing theo path + method. Trả 200 cho acknowledge/mark-all-read.
http.Client _client({
  List<Map<String, dynamic>> relatives = const [],
  List<Map<String, dynamic>> alerts = const [],
}) =>
    MockClient((req) async {
      final path = req.url.path;
      if (path == '/api/relatives' && req.method == 'GET') {
        return http.Response(
          jsonEncode({'success': true, 'data': relatives}),
          200,
        );
      }
      if (path == '/api/alerts' && req.method == 'GET') {
        return http.Response(
          jsonEncode({'success': true, 'data': alerts}),
          200,
        );
      }
      // acknowledge / mark-all-read / tạo manual → 200 success.
      return http.Response('{"success":true}', 200);
    });

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppState().logout();
  });

  group('reloadRelatives', () {
    test('load từ API → danh sách + status recompute safe', () async {
      ApiClient.instance.setHttpClientForTesting(_client(relatives: [
        _relativeDto(1, online: true, hr: 80, spo2: 98),
        _relativeDto(2, online: false, hr: 0, spo2: 0),
      ]));
      await AppState().reloadRelatives();

      final rels = AppState().relatives;
      expect(rels.length, 2);
      expect(rels[0].id, 1);
      expect(rels[0].isOffline, isFalse);
      expect(rels[1].isOffline, isTrue);
      // hr 80 (<100), spo2 98 (>93), không có alert critical → safe.
      expect(rels[0].status, 'safe');
      expect(rels[0].isFallen, isFalse);
    });

    test('API trả mảng rỗng → empty state', () async {
      ApiClient.instance.setHttpClientForTesting(_client(relatives: []));
      await AppState().reloadRelatives();
      expect(AppState().relatives, isEmpty);
    });

    test('API lỗi → fallback danh sách rỗng (không crash)', () async {
      ApiClient.instance.setHttpClientForTesting(MockClient(
          (_) async => http.Response('{"success":false,"message":"boom"}', 500)));
      await AppState().reloadRelatives();
      expect(AppState().relatives, isEmpty);
    });
  });

  group('reloadAlerts', () {
    test('load + sắp xếp giảm dần theo time', () async {
      final aOld = _alertDto(
        id: 1,
        relativeId: 1,
        type: 'sos',
        urgency: 'critical',
        timestamp: '2026-06-18T10:00:00.000Z',
      );
      final aNew = _alertDto(
        id: 2,
        relativeId: 1,
        type: 'vital',
        urgency: 'warning',
        timestamp: '2026-06-18T12:00:00.000Z', // mới hơn
      );
      ApiClient.instance.setHttpClientForTesting(_client(alerts: [aOld, aNew]));
      await AppState().reloadAlerts();

      final alerts = AppState().alerts;
      expect(alerts.length, 2);
      expect(alerts.first.id, '2'); // mới nhất trước
      expect(alerts.last.id, '1');
    });

    test('API lỗi → fallback rỗng', () async {
      ApiClient.instance.setHttpClientForTesting(MockClient(
          (_) async => http.Response('{"success":false,"message":"boom"}', 500)));
      await AppState().reloadAlerts();
      expect(AppState().alerts, isEmpty);
    });
  });

  group('status recompute từ alert thật', () {
    test('fall unacked → critical + isFallen; acknowledge → safe', () async {
      ApiClient.instance.setHttpClientForTesting(_client(
        relatives: [_relativeDto(1, online: true, hr: 0, spo2: 0)],
        alerts: [
          _alertDto(id: 5, relativeId: 1, type: 'fall', urgency: 'critical'),
        ],
      ));
      await AppState().reloadRelatives();
      await AppState().reloadAlerts();

      final rel = AppState().relatives.firstWhere((e) => e.id == 1);
      expect(rel.status, 'critical');
      expect(rel.isFallen, isTrue);

      await AppState().acknowledgeAlert('5');

      final rel2 = AppState().relatives.firstWhere((e) => e.id == 1);
      expect(rel2.status, 'safe');
      expect(rel2.isFallen, isFalse);
      final alert = AppState().alerts.firstWhere((a) => a.id == '5');
      expect(alert.acknowledged, isTrue);
      expect(alert.read, isTrue);
    });

    test('vital warning khi hr>100 hoặc spo2<93 (không cần alert)', () async {
      ApiClient.instance.setHttpClientForTesting(_client(relatives: [
        _relativeDto(1, online: true, hr: 115, spo2: 98),
        _relativeDto(2, online: true, hr: 70, spo2: 90),
      ]));
      await AppState().reloadRelatives();
      expect(AppState().relatives[0].status, 'warning'); // hr 115 > 100
      expect(AppState().relatives[1].status, 'warning'); // spo2 90 < 93
    });
  });

  group('logout', () {
    test('reset danh sách về rỗng + mất xác thực', () async {
      ApiClient.instance.setHttpClientForTesting(_client(relatives: [
        _relativeDto(1, online: true),
      ]));
      await AppState().setCurrentAccount(
        _profile(),
        'jwt',
      );
      expect(AppState().isAuthenticated, isTrue);
      expect(AppState().relatives.length, 1);

      await AppState().logout();
      expect(AppState().isAuthenticated, isFalse);
      expect(AppState().relatives, isEmpty);
      expect(AppState().alerts, isEmpty);
    });
  });
}

UserProfile _profile() => const UserProfile(
      id: 'u1',
      name: 'Người Thân',
      email: 't@e.com',
      phone: '',
      avatarUrl: '',
      avatarLocalPath: '',
    );