import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/services/api_client.dart';
import 'package:flutter_application_1/services/token_storage.dart';

http.Response _res(dynamic body, int status) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Mặc định 200 rỗng; mỗi test có thể thay bằng mock riêng.
    ApiClient.instance.setHttpClientForTesting(
      MockClient((_) async => http.Response('{}', 200)),
    );
    ApiClient.instance.onUnauthorized = null;
  });

  group('envelope unwrap', () {
    test('GET trả về `data` (Map)', () async {
      ApiClient.instance.setHttpClientForTesting(MockClient((_) async =>
          _res({'success': true, 'data': {'foo': 'bar'}}, 200)));
      final data = await ApiClient.instance.get('/api/x');
      expect(data, isA<Map>());
      expect((data as Map)['foo'], 'bar');
    });

    test('GET trả về `data` (List)', () async {
      ApiClient.instance.setHttpClientForTesting(MockClient((_) async =>
          _res({'success': true, 'data': [1, 2, 3]}, 200)));
      final data = await ApiClient.instance.get('/api/x');
      expect(data, isA<List>());
      expect(data as List, [1, 2, 3]);
    });

    test('POST/PUT/PATCH/DELETE đều trả `data`', () async {
      ApiClient.instance.setHttpClientForTesting(MockClient((_) async =>
          _res({'success': true, 'data': {'ok': 1}}, 200)));
      expect(await ApiClient.instance.post('/api/x', body: {}), {'ok': 1});
      expect(await ApiClient.instance.put('/api/x', body: {}), {'ok': 1});
      expect(await ApiClient.instance.patch('/api/x', body: {}), {'ok': 1});
      expect(await ApiClient.instance.delete('/api/x'), {'ok': 1});
    });
  });

  group('body & headers', () {
    test('POST body được mã hóa JSON', () async {
      String? captured;
      ApiClient.instance.setHttpClientForTesting(MockClient((req) async {
        captured = req.body;
        return _res({'success': true, 'data': null}, 200);
      }));
      await ApiClient.instance.post('/api/x', body: {'a': 1, 'b': 'x'});
      expect(jsonDecode(captured!), {'a': 1, 'b': 'x'});
    });

    test('Bearer header được gắn khi có token', () async {
      await TokenStorage.saveToken('jwt-xyz');
      String? auth;
      ApiClient.instance.setHttpClientForTesting(MockClient((req) async {
        auth = req.headers['authorization'];
        return _res({'success': true, 'data': null}, 200);
      }));
      await ApiClient.instance.get('/api/x');
      expect(auth, 'Bearer jwt-xyz');
    });

    test('Không gắn Authorization khi chưa có token', () async {
      String? auth;
      ApiClient.instance.setHttpClientForTesting(MockClient((req) async {
        auth = req.headers['authorization'];
        return _res({'success': true, 'data': null}, 200);
      }));
      await ApiClient.instance.get('/api/x');
      expect(auth, isNull);
    });
  });

  group('error handling', () {
    test('401 → xóa token + gọi onUnauthorized + ném ApiException', () async {
      await TokenStorage.saveToken('jwt-will-clear');
      var called = false;
      ApiClient.instance.onUnauthorized = () => called = true;
      ApiClient.instance.setHttpClientForTesting(MockClient(
          (_) async => _res({'success': false, 'message': 'hết hạn'}, 401)));

      await expectLater(
        ApiClient.instance.get('/api/x'),
        throwsA(isA<ApiException>()),
      );
      expect(called, isTrue);

      // TokenStorage.clearToken() chạy fire-and-forget trong _parse → đợi hoàn tất.
      for (int i = 0; i < 20 && await TokenStorage.getToken() != null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      expect(await TokenStorage.getToken(), isNull);
      ApiClient.instance.onUnauthorized = null;
    });

    test('4xx khác → ApiException kèm message + statusCode', () async {
      ApiClient.instance.setHttpClientForTesting(MockClient(
          (_) async => _res({'success': false, 'message': 'Sai tham số'}, 400)));
      try {
        await ApiClient.instance.get('/api/x');
        fail('phải ném ApiException');
      } on ApiException catch (e) {
        expect(e.message, 'Sai tham số');
        expect(e.statusCode, 400);
      }
    });

    test('body không phải JSON → không crash, data rỗng', () async {
      ApiClient.instance.setHttpClientForTesting(
          MockClient((_) async => http.Response('not-json', 200)));
      final data = await ApiClient.instance.get('/api/x');
      expect(data, isNull); // data['data'] của {} → null
    });
  });
}