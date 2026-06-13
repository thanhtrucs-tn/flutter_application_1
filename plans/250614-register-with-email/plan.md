# Plan: Cập nhật chức năng Đăng ký tài khoản

## Tóm tắt
Thay form đăng ký hiện tại (Tài khoản, Họ và tên, Mật khẩu, Nhập lại mật khẩu) thành **Tên tài khoản (Username), Email, Mật khẩu, Xác nhận mật khẩu**. Bắt buộc validate, lưu username/email/password vào DB, cho phép đăng nhập bằng Email hoặc Username. Loại bỏ trường "Họ và tên" khỏi màn hình đăng ký.

## Quyết định thiết kế
- **Email cũng unique**: mặc dù yêu cầu chỉ nói username unique, nhưng vì login sẽ dùng email nên email phải unique để tránh ambiguity. Giữ email nullable trong DB để tương thích dữ liệu cũ, nhưng app luôn bắt buộc nhập.
- **Password vẫn lưu plaintext**: giữ nguyên như hiện tại để không phá vỡ tài khoản cũ; không nằm trong phạm vi yêu cầu này.
- **Họ tên không còn trong đăng ký**: profile mặc định lấy username làm tên hiển thị; người dùng có thể sửa tên/email/SĐT trong màn hình Profile sau này.

## Các file thay đổi

### Backend / Database
1. `db_script.sql` — thêm `UNIQUE(email)` khi tạo bảng users.
2. `backend/server.js` — validate email, lưu email khi đăng ký, đăng nhập bằng username hoặc email.

### Flutter
3. `lib/services/auth_api_service.dart` — `register` nhận thêm `email`, `login` giữ nguyên.
4. `lib/database/db_helper.dart` — `registerUser` nhận `email`, cập nhật offline storage, login bằng username hoặc email.
5. `lib/utils/localization.dart` — cập nhật nhãn đăng ký/đăng nhập, thêm key email và thông báo lỗi email.
6. `lib/screens/register_screen.dart` — bỏ Họ và tên, thêm Email, đổi nhãn, validate đầy đủ.
7. `lib/screens/login_screen.dart` — nhãn gợi ý đăng nhập bằng email/username.

### Tests
8. `test/account_db_test.dart` — cập nhật test đăng ký/login dùng email.

### Docs
9. `docs/project-changelog.md` — ghi nhận thay đổi.

## Các bước thực hiện
1. Cập nhật schema DB & backend.
2. Cập nhật service và helper Flutter.
3. Cập nhật UI đăng ký/đăng nhập và localization.
4. Chạy `flutter analyze` / `flutter test`.
5. Review code.
6. Cập nhật changelog.

## Tiêu chí hoàn thành
- [ ] Form đăng ký chỉ còn 4 trường: Username, Email, Password, Confirm Password.
- [ ] Validate: không rỗng, email đúng format, password khớp, username unique.
- [ ] Dữ liệu đăng ký lưu vào DB (MySQL và offline mock).
- [ ] Đăng nhập chấp nhận cả email và username.
- [ ] Tests pass.
- [ ] Changelog được cập nhật.
