# Plan: Cô lập dữ liệu ứng dụng theo tài khoản

## Tóm tắt
Hiện tại người thân, cảnh báo SOS, lịch sử cảnh báo, thiết bị đeo được lưu chung trong một key SharedPreferences duy nhất. Cần chuyển sang lưu trữ theo tài khoản để mỗi tài khoản chỉ thấy dữ liệu của mình, và khi đăng nhập tài khoản khác thì tải dữ liệu riêng.

## Quyết định thiết kế
- Dùng **account-scoped SharedPreferences keys** thay vì thêm cột `owner` vào model. Lý do: hệ thống hiện chưa đồng bộ elderly/alerts lên MySQL; dữ liệu hoàn toàn local. Key theo account đơn giản, không phá vỡ model hiện tại, và tránh phải lọc danh sách ở mọi nơi.
- Key mặc định (khi chưa đăng nhập / `currentAccountId == null`) giữ nguyên tên cũ `offline_elderly_v2` để tương thích với test hiện có.
- Key theo tài khoản: `offline_elderly_<username>_v2`, `offline_alerts_<username>_v2`.
- Khi `setCurrentAccount(username)` được gọi sau đăng nhập, ngoài tải profile còn phải tải lại elderly + alerts của tài khoản đó và xóa active alert.
- Tài khoản `admin` mặc định sẽ được seed dữ liệu mẫu (MockData) nếu chưa có dữ liệu riêng; các tài khoản khác bắt đầu với danh sách rỗng.
- Lịch sử cảnh báo hiện chưa được persist; trong phạm vi này sẽ thêm persist cho alerts để đảm bảo dữ liệu riêng tài khoản không bị mất khi khởi động lại.

## Các file thay đổi
1. `lib/utils/app_state.dart`
   - `_offlineElderlyKey` và `_offlineAlertKey` thành account-scoped.
   - `_loadElderlyData`, `_loadAlertHistory` tải theo tài khoản hiện tại; seed MockData chỉ cho account `admin` hoặc chưa đăng nhập.
   - Thêm `_saveAlertHistory` và gọi ở các mutation (`addAlert`, `triggerSOS`, `acknowledgeAlert`, `clearAlertHistory`, `deleteElderly`).
   - `setCurrentAccount` tải lại elderly + alerts sau khi đổi account.
   - Thêm `logout()` để xóa current account, tải lại trạng thái mặc định.
   - `_saveElderlyData` / `_saveAlertHistory` chụp snapshot accountId + danh sách trước await để tránh race khi đổi account.
2. `lib/screens/profile_screen.dart` và `lib/screens/settings_screen.dart` — gọi `AppState().logout()` trước khi navigate về login.
3. `test/per_account_data_test.dart` (file mới) — kiểm tra chuyển đổi account tải dữ liệu khác.
4. `docs/project-changelog.md` — ghi nhận thay đổi.

## Tiêu chí hoàn thành
- [x] Mỗi tài khoản có key lưu elderly/alerts riêng.
- [x] `setCurrentAccount` tải lại elderly/alerts theo account.
- [x] Đăng nhập tài khoản mới → dữ liệu riêng (rỗng hoặc seed admin).
- [x] Alerts được persist theo account.
- [x] Logout xóa current account và tải trạng thái mặc định.
- [x] Tests pass, bao gồm test cô lập dữ liệu mới.
