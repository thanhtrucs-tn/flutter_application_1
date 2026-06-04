# Hướng dẫn chạy Backend API cho SOS Care

## Vấn đề ban đầu

Khi đăng ký tài khoản trên **Chrome (web)**, tài khoản **KHÔNG** được lưu vào MySQL vì trình duyệt web không thể kết nối TCP trực tiếp tới MySQL server (giới hạn bảo mật của trình duyệt).

## Giải pháp

Đã tạo **Backend API trung gian** (Node.js + Express) để Chrome gọi HTTP, backend sẽ chèn dữ liệu vào MySQL.

```
Chrome (Flutter Web)  ──HTTP──►  Backend (Node.js)  ──TCP──►  MySQL
http://localhost:3000
```

## Các bước thực hiện

### 1. Cài đặt MySQL (nếu chưa có)

- Tải MySQL Server: <https://dev.mysql.com/downloads/mysql/>
- Tạo database `test_123` bằng cách chạy file `db_script.sql` ở thư mục gốc dự án:
  ```bash
  mysql -u root -p < db_script.sql
  ```

### 2. Khởi động Backend

```bash
cd backend
npm install          # Chỉ chạy lần đầu
npm start
```

Khi thấy:
```
🚀 SOS Care Backend đang chạy
🚀 http://localhost:3000
🚀 ===================================
✅ Kết nối MySQL thành công tới 127.0.0.1:3306
```

→ Backend đã sẵn sàng.

### 3. Chạy Flutter trên Chrome

```bash
flutter run -d chrome
```

Khi mở trang đăng nhập, badge sẽ hiển thị:
- 🟢 **"Chrome (Web): MySQL Synced via API"** — nếu backend chạy và MySQL OK
- 🔵 **"Chrome (Web): Local Account Ready"** — nếu backend không chạy (fallback localStorage)

### 4. Test đăng ký từ Chrome

1. Mở Chrome → `http://localhost:8080` (hoặc URL Flutter cung cấp)
2. Nhấn "Đăng ký ngay"
3. Nhập `testuser` / `testpass123`
4. Nhấn đăng ký → thành công
5. Mở `http://localhost:3000/api/users` trên trình duyệt → sẽ thấy tài khoản vừa đăng ký trong MySQL

## Cấu trúc thư mục backend

```
backend/
├── package.json           # Khai báo dependencies
├── server.js              # Code chính của API
├── .env.example           # Mẫu cấu hình (copy thành .env)
├── .gitignore             # Bỏ qua node_modules, .env
└── README.md              # Hướng dẫn chi tiết cho backend
```

## Luồng hoạt động

### Trên Chrome (Web):

1. Người dùng nhập username/password → bấm "Đăng ký"
2. Flutter gọi `DbHelper.registerUser()` 
3. Trên web, nếu backend sẵn sàng → gọi `AuthApiService.register()`
4. `AuthApiService` gửi HTTP POST `http://localhost:3000/api/register`
5. Backend nhận request → INSERT vào MySQL → trả về kết quả
6. Flutter thông báo thành công/thất bại cho người dùng

### Trên Windows:

1. Người dùng nhập username/password → bấm "Đăng ký"
2. Flutter gọi `DbHelper.registerUser()`
3. Trên Windows, dùng `package mysql1` kết nối trực tiếp MySQL
4. Nếu MySQL không chạy → fallback về SharedPreferences

## Test thử nhanh bằng cURL

```bash
# Kiểm tra backend có chạy không
curl http://localhost:3000/api/health

# Đăng ký tài khoản test
curl -X POST http://localhost:3000/api/register \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"testpass"}'

# Đăng nhập
curl -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"testpass"}'

# Xem danh sách tất cả users
curl http://localhost:3000/api/users
```

## Nếu bạn muốn deploy backend lên server thật

Sửa `baseUrl` trong `lib/services/auth_api_service.dart`:

```dart
static String get baseUrl {
  return 'https://your-domain.com';  // Thay bằng URL backend của bạn
}
```

Sau đó build lại:
```bash
flutter build web
```

## Khắc phục sự cố

| Vấn đề | Nguyên nhân | Cách sửa |
|--------|-------------|----------|
| Badge "Local Account Ready" thay vì "MySQL Synced via API" | Backend chưa chạy | `cd backend && npm start` |
| Lỗi "ECONNREFUSED 127.0.0.1:3306" | MySQL chưa chạy | Khởi động MySQL server |
| Lỗi "Access denied for user 'root'" | Sai password | Sửa `DB_PASSWORD` trong `backend/.env` |
| Đăng ký thành công nhưng không thấy trong MySQL | Backend chưa chạy → fallback localStorage | Khởi động backend, xóa localStorage và đăng ký lại |
