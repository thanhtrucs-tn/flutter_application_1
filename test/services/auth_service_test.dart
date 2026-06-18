import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/services/api_client.dart';
import 'package:flutter_application_1/services/auth_service.dart';

http.Response _res(dynamic body, int status) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

Map<String, dynamic> _user({String id = '7', String email = 'a@b.com', String name = 'Anh A', String phone = '0900', String avatarUrl = 'u'}) =>
    {'id': id, 'email': email, 'name': name, 'phone': phone, 'avatarUrl': avatarUrl};

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('login', () {
    test('map {user, token} → UserProfile + token', () async {
      ApiClient.instance.setHttpClientForTesting(MockClient((req) async {
        expect(req.url.path, '/api/auth/login');
        expect(jsonDecode(req.body), {'email': 'a@b.com', 'password': 'pw'});
        return _res({'success': true, 'data': {'token': 'jwt-1', 'user': _user()}}, 200);
      }));
      final r = await AuthService.instance.login('a@b.com', 'pw');
      expect(r.token, 'jwt-1');
      expect(r.profile.id, '7');
      expect(r.profile.name, 'Anh A');
      expect(r.profile.email, 'a@b.com');
      expect(r.profile.phone, '0900');
      expect(r.profile.avatarUrl, 'u');
    });

    test('lỗi 401 → ApiException', () async {
      ApiClient.instance.setHttpClientForTesting(MockClient(
          (_) async => _res({'success': false, 'message': 'sai mật khẩu'}, 401)));
      await expectLater(
        AuthService.instance.login('a@b.com', 'wrong'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('register', () {
    test('gửi name/phone tùy chọn + map profile', () async {
      ApiClient.instance.setHttpClientForTesting(MockClient((req) async {
        expect(req.url.path, '/api/auth/register');
        expect(jsonDecode(req.body), {
          'email': 'x@y.com',
          'password': 'pw',
          'name': 'Name',
          'phone': '0901',
        });
        return _res({
          'success': true,
          'data': {'token': 'jwt-2', 'user': _user(id: '8', email: 'x@y.com', name: 'Name', phone: '0901')},
        }, 200);
      }));
      final r = await AuthService.instance.register(
        email: 'x@y.com',
        password: 'pw',
        name: 'Name',
        phone: '0901',
      );
      expect(r.profile.id, '8');
      expect(r.profile.name, 'Name');
      expect(r.token, 'jwt-2');
    });

    test('bỏ name/phone khi rỗng', () async {
      Map<String, dynamic>? body;
      ApiClient.instance.setHttpClientForTesting(MockClient((req) async {
        body = jsonDecode(req.body) as Map<String, dynamic>;
        return _res({
          'success': true,
          'data': {'token': 't', 'user': _user(id: '9', email: 'e@f.com', name: '', phone: '', avatarUrl: '')},
        }, 200);
      }));
      await AuthService.instance.register(email: 'e@f.com', password: 'pw');
      expect(body, {'email': 'e@f.com', 'password': 'pw'});
    });
  });

  group('getProfile', () {
    test('GET /api/auth/profile → UserProfile', () async {
      ApiClient.instance.setHttpClientForTesting(MockClient((req) async {
        expect(req.method, 'GET');
        expect(req.url.path, '/api/auth/profile');
        return _res({'success': true, 'data': _user()}, 200);
      }));
      final p = await AuthService.instance.getProfile();
      expect(p.id, '7');
      expect(p.name, 'Anh A');
      expect(p.avatarUrl, 'u');
    });
  });

  group('updateProfile', () {
    test('PUT /api/auth/profile với body name/phone/avatarUrl', () async {
      String? capturedBody;
      String? method;
      ApiClient.instance.setHttpClientForTesting(MockClient((req) async {
        method = req.method;
        capturedBody = req.body;
        return _res({
          'success': true,
          'data': _user(name: 'New', phone: '0901', avatarUrl: 'u2'),
        }, 200);
      }));
      final p = await AuthService.instance.updateProfile(
        name: 'New',
        phone: '0901',
        avatarUrl: 'u2',
      );
      expect(method, 'PUT');
      expect(jsonDecode(capturedBody!), {'name': 'New', 'phone': '0901', 'avatarUrl': 'u2'});
      expect(p.name, 'New');
      expect(p.phone, '0901');
      expect(p.avatarUrl, 'u2');
    });

    test('bỏ field null (chỉ cập nhật name)', () async {
      String? capturedBody;
      ApiClient.instance.setHttpClientForTesting(MockClient((req) async {
        capturedBody = req.body;
        return _res({'success': true, 'data': _user(name: 'OnlyName')}, 200);
      }));
      await AuthService.instance.updateProfile(name: 'OnlyName');
      expect(jsonDecode(capturedBody!), {'name': 'OnlyName'});
    });
  });
}