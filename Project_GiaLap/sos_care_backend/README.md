> **SOS Care Backend** — Node.js + Express + MySQL + Sequelize backend cho hệ thống SOS Care, nhận dữ liệu từ SOS Device Simulator và phát realtime cảnh báo qua Socket.IO.

## Tính năng chính

- REST API: `POST /api/sos`, `POST /api/events`, `POST /api/location`, `POST /api/device/status`, `GET /api/history`, `GET /api/device/:id`.
- Alias `POST /api/device/battery` tương thích với Flutter app hiện tại.
- Sequelize ORM với migration đầy đủ.
- JWT Authentication cho các route xem lịch sử / chi tiết thiết bị.
- Socket.IO realtime: phát `sos:alert` khi nhận SOS, `event:fall` khi nhận FALL_DETECTED.
- Validation Joi, error handling tập trung, response format thống nhất, logging Winston + Morgan.
- Cấu trúc thư mục chuyên nghiệp: controllers, services, repositories, models, routes, middleware, config, socket.

## Kiến trúc thư mục

```
sos_care_backend/
├── src/
│   ├── config/             # Database, env, sequelize-cli config
│   ├── controllers/        # HTTP request handlers
│   ├── services/           # Business logic + Socket.IO emit
│   ├── repositories/       # Sequelize data access
│   ├── models/             # Sequelize models
│   ├── routes/             # Express routers
│   ├── middleware/         # Auth, validation, logging, error handler
│   ├── validations/        # Joi schemas
│   ├── utils/              # Response, logger, AppError
│   ├── socket/             # Socket.IO handlers
│   ├── app.js              # Express app factory
│   └── server.js           # HTTP server + Socket.IO bootstrap
├── migrations/             # Sequelize migrations
├── tests/                  # Unit/integration tests
├── logs/                   # Winston daily rotate logs
├── package.json
├── .env.example
└── .sequelizerc
```

## Các package cần cài đặt

| Package | Mục đích |
|---------|----------|
| `express` | Web framework |
| `sequelize` + `mysql2` | ORM và driver MySQL |
| `socket.io` | Realtime WebSocket |
| `jsonwebtoken` + `bcryptjs` | JWT auth |
| `joi` | Validation |
| `winston` + `winston-daily-rotate-file` + `morgan` | Logging |
| `cors` + `helmet` | Security |
| `dotenv` | Environment config |
| `jest` + `supertest` + `nodemon` + `sequelize-cli` | Dev/Test |

## API Endpoints

| Method | Endpoint | Auth | Mô tả |
|---|---|---|---|
| POST | `/api/auth/register` | Public | Đăng ký admin/caregiver |
| POST | `/api/auth/login` | Public | Đăng nhập, nhận JWT |
| POST | `/api/sos` | Public (dev) / Device token | Nhận cảnh báo SOS |
| POST | `/api/events` | Public (dev) / Device token | Nhận sự kiện thiết bị |
| POST | `/api/location` | Public (dev) / Device token | Nhận vị trí GPS |
| POST | `/api/device/status` | Public (dev) / Device token | Cập nhật pin/nhịp tim/online |
| POST | `/api/device/battery` | Public (dev) / Device token | Cập nhật mức pin (payload tối thiểu) |
| GET | `/api/history` | JWT | Lịch sử SOS/events/locations |
| GET | `/api/device/:id` | JWT | Chi tiết thiết bị |
| GET | `/health` | Public | Health check |

## Socket.IO Events

| Event | Khi nào phát | Payload |
|---|---|---|
| `sos:alert` | Khi nhận `POST /api/sos` | `{ id, deviceId, elderlyId, type, latitude, longitude, timestamp, status }` |
| `event:fall` | Khi nhận `POST /api/events` với `type=FALL_DETECTED` | `{ id, deviceId, elderlyId, type, latitude, longitude, timestamp }` |
| `event:heart_rate` | Khi nhận `type=HEART_RATE_ALERT` | tương tự |
| `device:location` | Khi nhận `POST /api/location` | `{ id, deviceId, elderlyId, latitude, longitude, timestamp }` |
| `device:status` | Khi nhận `POST /api/device/status` hoặc `/api/device/battery` | `{ id, deviceId, elderlyId, batteryPercent, heartRateBpm, isOnline, timestamp }` |

## Hướng dẫn chạy

### 1. Chuẩn bị

- Cài đặt Node.js LTS (>=18).
- Cài đặt MySQL 8+ và tạo database `sos_care_db` (hoặc để `db:create` tạo).

### 2. Cài đặt dependencies

```bash
cd "D:\App Mobile\SOS Device Simulator\sos_care_backend"
npm install
```

### 3. Cấu hình môi trường

```bash
cp .env.example .env
```

Sửa `.env` với thông tin MySQL và JWT secret của bạn.

### 4. Tạo database và chạy migration

```bash
npx sequelize-cli db:create
npm run migrate
```

### 5. Chạy server

```bash
# Development
npm run dev

# Production
npm start
```

Server sẽ chạy tại `http://localhost:8081`.

### 6. Chạy test

```bash
npm test
```

## Tích hợp với Flutter app

Trong `sos_device_simulator/lib/core/config/api_config.dart`:

```dart
static const String baseUrl = 'http://localhost:8081';
static const bool useMock = false;
```

Lưu ý: nếu chạy Android emulator, dùng `http://10.0.2.2:8081` thay vì `localhost`.

## Ghi chú bảo mật

- `JWT_SECRET` phải được thay đổi trong production.
- Trong production, tắt `cors({ origin: '*' })` và chỉ cho phép origin tin cậy.
- Sử dụng HTTPS trong production.
- Hiện tại các endpoint POST thiết bị đang public trong môi trường dev (`DEVICE_AUTH_MODE=none`). Có thể bật xác thực device token bằng cách đổi `DEVICE_AUTH_MODE=token` và gửi header `X-Device-Token` khớp `DEVICE_TOKEN`.
- `CORS_ORIGIN` hỗ trợ `*` hoặc danh sách origin phân tách bằng dấu phẩy.
