# Plan: Cho phép thay đổi avatar người thân trong Quản lý người thân

## Tóm tắt
Thêm khả năng đổi ảnh đại diện cho từng người thân trong section "Quản lý người thân" của Settings. Thiết kế tối giản, gọn gàng, dễ dùng: tap vào avatar → chọn ảnh từ thư viện → lưu ngay.

## Quyết định thiết kế
- Reuse `AvatarPicker` đã có để chọn ảnh từ gallery; gói trong dialog nhỏ để không làm rối UI.
- Thêm `avatarLocalPath` vào `ElderlyModel` (tương tự `UserProfile`), ưu tiên hiển thị ảnh local nếu có, fallback về URL cũ.
- Tạo widget nhỏ `ElderlyAvatar` để hiển thị avatar ở mọi nơi theo cùng một logic: local trước, URL sau.
- Chỉ hiển thị nút đổi avatar trong `ManageRelativesSection`; các card khác (Home) chỉ hiển thị avatar đã chọn.

## Các file thay đổi
1. `lib/models/elderly_model.dart`
   - Thêm `avatarLocalPath` field, copyWith, fromMap, toMap.
2. `lib/widgets/elderly_avatar.dart` (mới)
   - Widget hiển thị avatar: ưu tiên local file, fallback URL, placeholder icon.
3. `lib/widgets/elderly_card_content.dart`
   - Thay `CircleAvatar` bằng `ElderlyAvatar`.
4. `lib/widgets/manage_relatives_section.dart`
   - Thay `CircleAvatar` bằng `ElderlyAvatar` tappable; tap mở dialog `AvatarPicker`.
   - Sau khi chọn ảnh, gọi `AppState().updateElderly(...copyWith(avatarLocalPath: path))`.
5. `test/elderly_add_test.dart` hoặc test mới `test/elderly_avatar_test.dart`
   - Kiểm tra `avatarLocalPath` round-trip qua toMap/fromMap và copyWith.
6. `docs/project-changelog.md` — ghi nhận.

## Tiêu chí hoàn thành
- [ ] Tap avatar người thân trong Settings → mở gallery → chọn ảnh.
- [ ] Ảnh local được hiển thị ở cả Settings và Home.
- [ ] Dữ liệu lưu persist qua AppState.updateElderly.
- [ ] Model có `avatarLocalPath` và backward-compatible với dữ liệu cũ.
- [ ] Tests pass.
