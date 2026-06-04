# SOS Care Backend API

Backend Node.js + Express trung gian giúp Flutter Web (Chrome) kết nối với MySQL.

## Tại sao cần backend?

Trình duyệt web **KHÔNG THỂ** kết nối TCP trực tiếp tới MySQL (giới hạn bảo mật).
Cần có backend API làm "cầu nối" để:
- Chrome gửi HTTP POST `/api/register` → Backend nhận → Insert vào MySQL
- Chrome gửi HTTP POST `/api/login` → Backend nhận → Query MySQL trả về

## Cài đặt

```bash
cd backend
npm install
```

## Cấu hình

Sao chép `.env.example` thành `.env` và điền thông tin MySQL của bạn:

```bash
cp .env.example .env
```

Sửa các biến:
- `DB_HOST` — IP MySQL server (mặc định `127.0.0.1`)
- `DB_PORT` — Cổng MySQL (mặc định `3306`)
- `DB_USER` — User MySQL
- `DB_PASSWORD` — Mật khẩu MySQL
- `DB_NAME` — Tên database (mặc định `test_123`)

## Chạy

```bash
# Cách 1: Production
npm start

# Cách 2: Development (auto-reload khi sửa code)
npm run dev
```

Server sẽ chạy ở `http://localhost:3000`.

## Endpoints

| Method | Endpoint          | Mô tả                                     |
|--------|-------------------|-------------------------------------------|
| GET    | `/`               | Thông tin API                              |
| GET    | `/api/health`     | Kiểm tra server + kết nối MySQL            |
| POST   | `/api/register`   | Đăng ký tài khoản mới vào MySQL            |
| POST   | `/api/login`      | Đăng nhập bằng username/password           |
| GET    | `/api/users`      | Liệt kê tất cả users (dùng để debug)       |

## Test thử bằng trình duyệt

Mở `http://localhost:3000` → thấy thông tin API.

Mở `http://localhost:3000/api/users` → thấy danh sách tài khoản hiện có.

## Test thử bằng cURL

```bash
# Health check
curl http://localhost:3000/api/health

# Đăng ký
curl -X POST http://localhost:3000/api/register \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"testpass"}'

# Đăng nhập
curl -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"testpass"}'

# Xem danh sách
curl http://localhost:3000/api/users
```

## Yêu cầu hệ thống

- Node.js >= 16
- MySQL Server đang chạy
- Database `test_123` đã được tạo (chạy file `../db_script.sql` để tạo)
