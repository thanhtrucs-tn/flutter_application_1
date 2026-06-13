// Unit test cho UserProfile model và AppState.updateUserProfile.
// Đảm bảo logic chỉnh sửa thông tin cá nhân hoạt động đúng.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/models/user_profile.dart';
import 'package:flutter_application_1/utils/app_state.dart';

void main() {
  group('UserProfile model', () {
    test('defaultProfile cung cấp giá trị mặc định hợp lệ', () {
      final p = UserProfile.defaultProfile();
      expect(p.id, isNotEmpty);
      expect(p.name, isNotEmpty);
      expect(p.email, contains('@'));
      expect(p.phone, isNotEmpty);
      expect(p.avatarUrl, startsWith('http'));
    });

    test('copyWith chỉ thay đổi trường được chỉ định, giữ nguyên phần còn lại', () {
      final p = UserProfile.defaultProfile();
      final p2 = p.copyWith(
        name: 'cóc',
        phone: '+84 909 111 222',
        avatarLocalPath: '/data/user/0/avatar.jpg',
      );
      expect(p2.name, 'cóc');
      expect(p2.phone, '+84 909 111 222');
      expect(p2.avatarLocalPath, '/data/user/0/avatar.jpg');
      expect(p2.email, p.email); // giữ nguyên
      expect(p2.avatarUrl, p.avatarUrl); // giữ nguyên
      expect(p2.id, p.id); // giữ nguyên
    });

    test('avatarLocalPath mặc định là rỗng', () {
      final p = UserProfile.defaultProfile();
      expect(p.avatarLocalPath, isEmpty);
    });

    test('toMap → fromMap là phép biến đổi round-trip', () {
      final p = UserProfile.defaultProfile().copyWith(
        name: 'A',
        email: 'a@b.co',
        phone: '0123456789',
      );
      final restored = UserProfile.fromMap(p.toMap());
      expect(restored.name, 'A');
      expect(restored.email, 'a@b.co');
      expect(restored.phone, '0123456789');
    });
  });

  group('AppState.updateUserProfile', () {
    setUp(() async {
      // Reset SharedPreferences mỗi test để đảm bảo cô lập.
      SharedPreferences.setMockInitialValues({});
    });

    test('cập nhật thành công với dữ liệu hợp lệ và persist xuống bộ nhớ', () async {
      final state = AppState();
      // Đợi load xong dữ liệu mặc định
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final updated = state.userProfile.copyWith(
        name: 'Nguyễn Văn A',
        email: 'a@example.com',
        phone: '0901111222',
      );
      final ok = await state.updateUserProfile(updated);
      expect(ok, isTrue);
      expect(state.userProfile.name, 'Nguyễn Văn A');
      expect(state.userProfile.email, 'a@example.com');
      expect(state.userProfile.phone, '0901111222');

      // Tạo AppState mới mô phỏng khởi động lại app → dữ liệu phải persist
      final reloaded = AppState();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(reloaded.userProfile.name, 'Nguyễn Văn A');
      expect(reloaded.userProfile.email, 'a@example.com');
      expect(reloaded.userProfile.phone, '0901111222');
    });

    test('từ chối cập nhật khi name rỗng', () async {
      final state = AppState();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final originalName = state.userProfile.name;
      final updated = state.userProfile.copyWith(name: '   ');
      final ok = await state.updateUserProfile(updated);
      expect(ok, isFalse);
      expect(state.userProfile.name, originalName);
    });

    test('từ chối cập nhật khi email rỗng', () async {
      final state = AppState();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final originalEmail = state.userProfile.email;
      final updated = state.userProfile.copyWith(email: '');
      final ok = await state.updateUserProfile(updated);
      expect(ok, isFalse);
      expect(state.userProfile.email, originalEmail);
    });

    test('updateUserAvatarLocalPath cập nhật và persist', () async {
      final state = AppState();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      const testPath = '/storage/emulated/0/Pictures/avatar.jpg';
      final ok = await state.updateUserAvatarLocalPath(testPath);
      expect(ok, isTrue);
      expect(state.userProfile.avatarLocalPath, testPath);

      // Tạo AppState mới → path phải được persist
      final reloaded = AppState();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(reloaded.userProfile.avatarLocalPath, testPath);
    });

    test('updateUserAvatarLocalPath từ chối path rỗng', () async {
      final state = AppState();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final original = state.userProfile.avatarLocalPath;
      final ok = await state.updateUserAvatarLocalPath('');
      expect(ok, isFalse);
      expect(state.userProfile.avatarLocalPath, original);
    });

    test('từ chối cập nhật khi sđt không đúng 10 chữ số', () async {
      final state = AppState();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final originalPhone = state.userProfile.phone;
      // Quá ngắn
      var ok = await state.updateUserProfile(state.userProfile.copyWith(phone: '0901234'));
      expect(ok, isFalse);
      expect(state.userProfile.phone, originalPhone);

      // Quá dài
      ok = await state.updateUserProfile(state.userProfile.copyWith(phone: '09012345678901'));
      expect(ok, isFalse);
      expect(state.userProfile.phone, originalPhone);

      // Có chữ cái/ký tự đặc biệt
      ok = await state.updateUserProfile(state.userProfile.copyWith(phone: '09012abcde'));
      expect(ok, isFalse);
      expect(state.userProfile.phone, originalPhone);

      ok = await state.updateUserProfile(state.userProfile.copyWith(phone: '+84 901 234 567'));
      expect(ok, isFalse);
      expect(state.userProfile.phone, originalPhone);

      // Đúng 10 số
      ok = await state.updateUserProfile(state.userProfile.copyWith(phone: '0901234567'));
      expect(ok, isTrue);
      expect(state.userProfile.phone, '0901234567');
    });

    test('từ chối cập nhật khi email quá 48 kí tự', () async {
      final state = AppState();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final originalEmail = state.userProfile.email;
      // local 30 + "@" + domain 20 = 51 kí tự
      final tooLong = '${'a' * 30}@${'b' * 20}.com';
      expect(tooLong.length, greaterThan(48));
      final ok = await state.updateUserProfile(state.userProfile.copyWith(email: tooLong));
      expect(ok, isFalse);
      expect(state.userProfile.email, originalEmail);
    });
  });

  group('UserProfile UI rebuild qua AnimatedBuilder', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('updateUserProfile kích hoạt rebuild cho mọi widget lắng nghe AppState', () async {
      final state = AppState();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      int rebuildCount = 0;
      // Listener giả lập widget: được gọi mỗi khi notifyListeners()
      state.addListener(() {
        rebuildCount++;
      });

      // Thay đổi tên → AppState gọi notifyListeners() → listener được gọi
      final ok = await state.updateUserProfile(
        state.userProfile.copyWith(name: 'Trúc Thành'),
      );

      expect(ok, isTrue);
      // notifyListeners() phải được gọi ít nhất 1 lần sau update
      expect(rebuildCount, greaterThan(0));
      // Data mới phải có sẵn cho widget
      expect(state.userProfile.name, 'Trúc Thành');
    });

    test('updateUserAvatarLocalPath kích hoạt rebuild và cập nhật path mới', () async {
      final state = AppState();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      int rebuildCount = 0;
      state.addListener(() => rebuildCount++);

      const testPath = '/data/user/0/avatar_new.jpg';
      final ok = await state.updateUserAvatarLocalPath(testPath);

      expect(ok, isTrue);
      expect(rebuildCount, greaterThan(0));
      expect(state.userProfile.avatarLocalPath, testPath);

      // Persist qua reload
      final reloaded = AppState();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(reloaded.userProfile.avatarLocalPath, testPath);
    });

    test('nhiều lần update liên tiếp đều trigger rebuild (cộng dồn)', () async {
      final state = AppState();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      int rebuildCount = 0;
      state.addListener(() => rebuildCount++);

      await state.updateUserProfile(state.userProfile.copyWith(name: 'A'));
      await state.updateUserProfile(state.userProfile.copyWith(name: 'B'));
      await state.updateUserProfile(state.userProfile.copyWith(name: 'C'));

      // 3 update → 3 notifyListeners → rebuildCount >= 3
      expect(rebuildCount, greaterThanOrEqualTo(3));
      expect(state.userProfile.name, 'C');
    });

    test('update thất bại KHÔNG kích hoạt rebuild (giữ data cũ)', () async {
      final state = AppState();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      int rebuildCount = 0;
      state.addListener(() => rebuildCount++);

      final ok = await state.updateUserProfile(
        state.userProfile.copyWith(phone: 'abc'),
      );

      expect(ok, isFalse);
      // Không notify khi thất bại → rebuildCount giữ nguyên
      expect(rebuildCount, 0);
      expect(state.userProfile.phone, '0901234567');
    });
  });

  group('Per-account profile', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('mỗi tài khoản có profile riêng, độc lập và persist', () async {
      final state = AppState();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await state.setCurrentAccount(
        'alice',
        displayName: 'Alice A',
        email: 'alice@example.com',
        phone: '0901111111',
      );
      expect(state.userProfile.name, 'Alice A');

      await state.updateUserProfile(
        state.userProfile.copyWith(name: 'Alice B'),
      );
      expect(state.userProfile.name, 'Alice B');

      await state.setCurrentAccount(
        'bob',
        displayName: 'Bob A',
        email: 'bob@example.com',
        phone: '0902222222',
      );
      expect(state.userProfile.name, 'Bob A');

      // Quay lại alice → phải thấy tên đã lưu, không bị bob ghi đè.
      await state.setCurrentAccount('alice');
      expect(state.userProfile.name, 'Alice B');
    });

    test('setCurrentAccount dùng displayName từ DB khi chưa có profile cục bộ', () async {
      final state = AppState();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await state.setCurrentAccount(
        'carol',
        displayName: 'Carol Carol',
        email: 'carol@example.com',
        phone: '0903333333',
      );
      expect(state.userProfile.id, 'carol');
      expect(state.userProfile.name, 'Carol Carol');
      expect(state.userProfile.email, 'carol@example.com');
      expect(state.userProfile.phone, '0903333333');
    });
  });
}
