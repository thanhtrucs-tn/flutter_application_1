// Unit test cho việc lưu/tải thông tin tài khoản qua DbHelper ở chế độ offline.
// Ở chế độ offline, danh sách user được lưu trong SharedPreferences.
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/database/db_helper.dart';

void main() {
  group('DbHelper offline account info', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      DbHelper.backendAvailable = false;
      // Đặt platform Windows để kết nối MySQL thất bại nhanh (127.0.0.1)
      // thay vì chờ timeout 10.0.2.2 trên Android mô phỏng trong test.
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    test('Đăng ký lưu email và đăng nhập bằng username trả về đúng email', () async {
      final regError = await DbHelper.registerUser(
        'user_a',
        'pass123',
        email: 'user_a@example.com',
      );
      expect(regError, isNull);

      final user = await DbHelper.loginUser('user_a', 'pass123');
      expect(user, isNotNull);
      expect(user!['username'], 'user_a');
      expect(user['email'], 'user_a@example.com');
    });

    test('Đăng nhập bằng email hoạt động sau khi đăng ký', () async {
      await DbHelper.registerUser(
        'user_email_login',
        'pass123',
        email: 'email_login@example.com',
      );

      final user = await DbHelper.loginUser('email_login@example.com', 'pass123');
      expect(user, isNotNull);
      expect(user!['username'], 'user_email_login');
    });

    test('Cập nhật profile offline: đăng nhập lại thấy tên mới', () async {
      await DbHelper.registerUser(
        'user_b',
        'pass123',
        email: 'user_b@example.com',
      );

      final ok = await DbHelper.updateUserProfile(
        'user_b',
        'B New',
        'bnew@example.com',
        '0909999999',
      );
      expect(ok, isTrue);

      final user = await DbHelper.loginUser('user_b', 'pass123');
      expect(user, isNotNull);
      expect(user!['name'], 'B New');
      expect(user['email'], 'bnew@example.com');
      expect(user['phone'], '0909999999');
    });

    test('Tài khoản admin mặc định có họ tên "Quản trị viên"', () async {
      final user = await DbHelper.loginUser('admin', 'admin123');
      expect(user, isNotNull);
      expect(user!['name'], 'Quản trị viên');
    });

    test('Không cho phép đăng ký trùng email', () async {
      await DbHelper.registerUser(
        'user_c',
        'pass123',
        email: 'duplicate@example.com',
      );

      final regError = await DbHelper.registerUser(
        'user_d',
        'pass123',
        email: 'duplicate@example.com',
      );
      expect(regError, isNotNull);
      expect(regError, contains('Email'));
    });
  });
}
