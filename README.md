# SOS Care - Hệ thống chăm sóc người cao tuổi

Hệ thống gồm ba dự án phân tán cùng hỗ trợ nhau: một ứng dụng Flutter cho người chăm sóc (con cái/bảo mẫu), một backend Node.js, và một trình giả lập thiết bị đeo SOS dành cho người cao tuổi. Mục tiêu: giám sát sức khỏe và vị trí của người cao tuổi theo thời gian thực, cảnh báo SOS/té ngã/nhịp tim bất thường, và cho phép người thân tương tác kịp thời.

---

## 1. Tổng quan hệ thống

| Thành phần | Công nghệ | Vai trò |
|-----------|----------|---------|
| `flutter_application_1` (gốc repo) | Flutter >= 3.41, Dart >= 3.12 | Ứng dụng chính cho người chăm sóc: giám sát người thân, nhận cảnh báo realtime, bản đồ, chỉ số sức khỏe, quản lý người thân/liên hệ khẩn cấp |
| `Project_GiaLap/sos_care_backend` | Node.js + Express + MySQL + Sequelize + Socket.IO | Backend REST API + realtime, nhận dữ liệu từ thiết bị/trình giả lập, phát cảnh báo, xác thực JWT |
| `Project_GiaLap/sos_device_simulator` | Flutter + Riverpod + Dio | Trình giả lập thiết bị đeo SOS (wearable) để kiểm thử: gửi SOS, sự kiện té ngã, vị trí, trạng thái thiết bị |

Luồng dữ liệu chính:

```
[sos_device_simulator] --HTTP/REST--> [sos_care_backend] --Socket.IO realtime--> [flutter_application_1]
                \                          ^                                      |
                 +--- Socket.IO ack -------+                                      |
                 (phản hồi giao thành công)                                       |
                                                                                  |
            [flutter_application_1] --REST (JWT)--> [sos_care_backend] (quản lý người thân, lịch sử, cấu hình)
```

Người chăm sóc đăng nhập vào ứng dụng Flutter, thêm người thân và gán thiết bị. Khi người cao tuổi đeo thiết bị (ở đây là trình giả lập) nhấn nút SOS hoặc bị phát hiện té ngã/nhịp tim bất thường, dữ liệu gửi lên backend, backend phát sự kiện Socket.IO theo room `user:<id>`, ứng dụng Flutter nhận và hiển thị cảnh báo ngay lập tức.

---

## 2. Ứng dụng chính (flutter_application_1)

### 2.1 Chức năng

- Đăng ký / đăng nhập với JWT, tự động đăng xuất khi token hết hạn (401).
- Tổng quan an toàn: danh sách người thân, trạng thái thiết bị (pin, online), cảnh báo SOS gần nhất.
- Nhận cảnh báo realtime qua Socket.IO: SOS, té ngã (FALL_DETECTED), cảnh báo nhịp tim, vị trí, trạng thái thiết bị.
- Lịch sử sự cố SOS với bộ lọc và chi tiết từng cảnh báo.
- Bản đồ (flutter_map + OpenStreetMap, miễn phí, không cần API key): xem vị trí hiện tại, vùng an toàn (geofence), modal bản đồ đầy màn hình.
- Chỉ số sức khỏe: nhịp tim, SpO2, mức pin, biểu đồ theo thời gian.
- Hành động từ xa: gọi điện, nghe xung quanh, bật chuông thiết bị, nhắn tin khẩn cấp, kích hoạt SOS từ xa.
- Quản lý người thân (thêm/sửa/xóa, sắp xếp lại) và liên hệ khẩn cấp.
- Cấu hình: chế độ Sáng/Tối, ngôn ngữ (Tiếng Việt / English), thông báo, vùng an toàn.
- Hỗ trợ đa ngôn ngữ vi/en và chế độ Sáng/Tối toàn hệ thống.

### 2.2 Cấu trúc thư mục lib

```
lib/
  main.dart                      # Khởi động app: notification, ApiClient, Socket.IO, AppState
  models/                        # Model dữ liệu
    user_profile.dart            #   Profile người dùng (lưu theo account, đồng bộ DB)
    elderly_model.dart           #   Người thân (elderly)
    alert_model.dart             #   Cảnh báo SOS
    emergency_contact_model.dart #   Liên hệ khẩn cấp
    address_model.dart           #   Địa chỉ
    app_settings.dart            #   Cấu hình ứng dụng
  services/                      # Tầng service (gọi backend)
    api_client.dart             #   Singleton HTTP, base URL, JWT, unwrap envelope, 401
    auth_service.dart           #   Đăng ký/đăng nhập
    token_storage.dart          #   Lưu JWT (shared_preferences)
    alerts_api_service.dart     #   Lịch sử / chi tiết cảnh báo
    relatives_api_service.dart  #   Quản lý người thân + liên hệ khẩn cấp
    address_service.dart        #   Geocoding / địa chỉ
    device_event_service.dart   #   Realtime Socket.IO: lắng nghe + phát event
    device_event_mapper.dart    #   Map payload thiết bị -> model; resolve base URL (Android emulator)
    socket_io_service.dart      #   Wrapper socket_io_client, JWT handshake auth, auto reconnect
    notification_service.dart   #   Thông báo nội bộ (flutter_local_notifications)
  utils/
    app_state.dart              #   AppState singleton (ChangeNotifier): người thân, cảnh báo, cài đặt
    localization.dart           #   Đa ngôn ngữ vi/en
    theme.dart                  #   Theme Sáng/Tối
  screens/                      # 18 màn hình (login, register, home, alerts, detail, map, profile, settings, ...)
  widgets/                      # ~35 widget tái sử dụng (card, badge, dialog, nav, chart, map overlay, ...)
```

### 2.3 Luồng thời gian thực

`SocketIoService` kết nối backend với JWT (gửi qua cả `auth` object và query param `?token=` để backend join room `user:<id>`), transport websocket, tự động kết nối lại (60 lần, delay 1s). `forceNew` đảm bảo socket tạo sau re-auth kết nối lại thật, không mất realtime khi re-login. `DeviceEventService` lắng nghe các event realtime và cập nhật `AppState`; `AppState` (ChangeNotifier) thông báo cho UI qua `AnimatedBuilder`.

### 2.4 Xử lý URL backend

Trên Android emulator, `localhost` tự động đổi thành `10.0.2.2` (xử lý trong `DeviceEventMapper.resolveBackendUrl`) để app trong emulator gọi được backend chạy trên máy host. Base URL mặc định: `http://localhost:8080`.

### 2.5 Lưu ý Decimal từ backend

Backend dùng DECIMAL trong MySQL, qua Sequelize trả về kiểu String. Ứng dụng Flutter phải parse kiểu nhường (tolerant) chứ không dùng `as num?` để tránh lỗi.

---

## 3. Backend (Project_GiaLap/sos_care_backend)

### 3.1 Công nghệ

Node.js (>= 18) + Express + MySQL 8 + Sequelize 6 ORM + Socket.IO 4 + JWT (jsonwebtoken + bcryptjs) + Joi validation + Winston/Morgan logging + Helmet/CORS. Kiểm thử với Jest + Supertest.

### 3.2 Cấu trúc thư mục

```
sos_care_backend/
  src/
    config/          # database.js, env.config.js, sequelize-cli.config.js
    controllers/     # auth, alert, device, deviceStatus, event, health, history, location, relative, sos, battery
    services/        # business logic + Socket.IO emit (alert, auth, device, deviceStatus, event, geofence, history, location, relative, socket, sos)
    repositories/    # truy xuất dữ liệu Sequelize
    models/          # user, device, location, sosAlert, event, deviceStatus, relative, emergencyContact, alert
    routes/          # Express routers (auth, sos, events, location, device, deviceStatus, battery, history, health, relative, alert)
    middleware/      # auth, validation, logging, error handler
    validations/     # Joi schemas
    utils/           # response, logger, AppError
    socket/          # socket.handler.js (join room user:<id>, phát event realtime)
    app.js           # Express app factory
    server.js        # HTTP server + Socket.IO bootstrap
  migrations/        # 12 migration Sequelize (users, devices, locations, sos_alerts, events, device_statuses, relatives, emergency_contacts, alerts, profile cols, SpO2, device-relative)
  tests/             # Unit/integration
  logs/              # Winston daily rotate
  package.json
  .env.example
  .sequelizerc
```

### 3.3 API endpoints

| Method | Endpoint | Xác thực | Mô tả |
|--------|----------|----------|-------|
| POST | /api/auth/register | Public | Đăng ký admin/caregiver |
| POST | /api/auth/login | Public | Đăng nhập, nhận JWT |
| POST | /api/sos | Device token (dev: public) | Nhận cảnh báo SOS từ thiết bị |
| POST | /api/events | Device token | Nhận sự kiện thiết bị (FALL_DETECTED, HEART_RATE_ALERT, ...) |
| POST | /api/location | Device token | Nhận vị trí GPS |
| POST | /api/device/status | Device token | Cập nhật pin/nhịp tim/online |
| POST | /api/device/battery | Device token | Cập nhật mức pin (payload tối thiểu) |
| GET | /api/history | JWT | Lịch sử SOS/events/locations |
| GET | /api/device/:id | JWT | Chi tiết thiết bị |
| GET | /health | Public | Health check |

Response envelope thống nhất: `{ success, data, message, errors }`. `ApiClient` Flutter tự lấy `data`.

### 3.4 Socket.IO events

| Event | Khi phát | Payload chính |
|-------|----------|---------------|
| sos:alert | POST /api/sos | id, deviceId, elderlyId, type, latitude, longitude, timestamp, status |
| event:fall | POST /api/events type=FALL_DETECTED | id, deviceId, elderlyId, type, latitude, longitude, timestamp |
| event:heart_rate | type=HEART_RATE_ALERT | tương tự event:fall |
| device:location | POST /api/location | id, deviceId, elderlyId, latitude, longitude, timestamp |
| device:status | POST /api/device/status hoặc /battery | id, deviceId, elderlyId, batteryPercent, heartRateBpm, isOnline, timestamp |

Backend đọc JWT từ cả `handshake.auth.token` lẫn `handshake.query.token` để join room `user:<id>`, đảm bảo event được scope theo người dùng khi thiết bị đã pair.

### 3.5 Bảo mật

- Đổi `JWT_SECRET` trong production.
- Tắt `cors({ origin: '*' })` trong production, chỉ cho phép origin tin cậy (qua `CORS_ORIGIN`, hoặc `*` hoặc danh sách phân tách dấu phẩy).
- Dùng HTTPS trong production.
- Endpoint POST thiết bị đang public trong dev (`DEVICE_AUTH_MODE=none`). Bật xác thực device token: đổi thành `DEVICE_AUTH_MODE=token` và gửi header `X-Device-Token` khớp `DEVICE_TOKEN`.

---

## 4. Trình giả lập thiết bị (Project_GiaLap/sos_device_simulator)

Flutter app giả lập thiết bị đeo SOS của người cao tuổi, dành cho kiểm thử. Sử dụng Clean Architecture (domain/data/presentation) + Riverpod + Dio + geolocator + socket_io_client + dartz (Result type).

### 4.1 Cấu trúc thư mục

```
sos_device_simulator/
  lib/
    main.dart
    core/
      config/api_config.dart         # baseUrl, useMock
      constants/app_constants.dart
      errors/failure.dart
      services/dio_client.dart        # Dio HTTP client
      services/socket_io_service.dart # Nhận ack từ backend
      utils/debouncer.dart
      utils/throttle_helper.dart
    features/sos_simulator/
      application/services/location_service.dart
      data/models/                    # api_response, battery, device_status, event, location, sos payload
      data/repositories/              # mock_data_source, remote_data_source, repository_impl
      domain/entities/                # device_status, operation_result
      domain/repositories/sos_simulator_repository.dart
      presentation/
        providers/                    # device_status_notifier, providers
        screens/home_screen.dart
        widgets/                       # sos_button, function_button_grid, device_info_card, battery_slider_card, heart_rate_slider_card, online_switch_tile, device_identity_editor
```

### 4.2 Chức năng

- Nút SOS gửi cảnh báo `POST /api/sos`.
- Vuốt chỉnh mức pin, nhịp tim, trạng thái online; gửi `POST /api/device/status`.
- Gửi vị trí GPS thực (geolocator) qua `POST /api/location`.
- Gửi sự kiện té ngã / nhịp tim qua `POST /api/events`.
- Nhận Socket.IO ack từ backend để biết giao thành công.
- Cơ chế mock (api_config `useMock`) để chạy không cần backend.

### 4.3 Cấu hình backend

Trong `lib/core/config/api_config.dart`:

```dart
static const String baseUrl = 'http://localhost:8080';
static const bool useMock = false;
```

Trên Android emulator dùng `http://10.0.2.2:8080` thay vì `localhost`.

---

## 5. Yêu cầu môi trường

- Node.js LTS >= 18 (backend).
- MySQL 8+.
- Flutter >= 3.41, Dart >= 3.12 (cả hai app Flutter).
- Android Studio / Flutter SDK hoạt động. Trên Windows chạy qua `start.bat`.

---

## 6. Hướng dẫn cài đặt và chạy

### 6.1 Backend

```bash
cd "Project_GiaLap/sos_care_backend"
npm install
cp .env.example .env        # sửa thông tin MySQL + JWT secret
npx sequelize-cli db:create
npm run migrate
npm run dev                 # hoặc npm start (production)
```

Backend chạy tại `http://localhost:8080`. Chạy test: `npm test`.

Biến môi trường `.env` chính (xem `.env.example`): `PORT`, `NODE_ENV`, `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASS`, `JWT_SECRET`, `JWT_EXPIRES_IN`, `LOG_LEVEL`, `LOG_TO_FILE`, `DB_SYNC`, `CORS_ORIGIN`, `DEVICE_AUTH_MODE`, `DEVICE_TOKEN`.

### 6.2 Ứng dụng chính (flutter_application_1)

```bash
flutter pub get
flutter run
```

Trên Android emulator, app tự động gọi backend qua `10.0.2.2:8080`. Trên thiết bị thật / Windows, chạy backend và app cùng máy thì dùng `localhost:8080` (đã được resolve tự động).

### 6.3 Trình giả lập

```bash
cd "Project_GiaLap/sos_device_simulator"
flutter pub get
flutter run
```

### 6.4 Khởi động tất cả cùng lúc (Windows)

Chạy file `start.bat` ở gốc repo. Script sẽ:

1. Hỏi có tạo lại database không (Y = db:drop + db:create + migrate; N = giữ nguyên).
2. Mở cửa sổ cmd riêng chạy `npm run dev` cho backend.
3. Mở cửa sổ cmd riêng chạy `flutter run` cho ứng dụng chính.
4. Mở cửa sổ cmd riêng chạy `flutter run` cho trình giả lập.

Lưu ý: `start.bat` còn tham chiếu đường dẫn cũ; nếu đổi vị trí repo, chỉnh lại biến `BACKEND`/`SIMULATOR`/`ROOT` trong file.

---

## 7. Thư viện chính

Ứng dụng chính (pubspec.yaml):

| Gói | Mục đích |
|-----|----------|
| http | HTTP client gọi REST API |
| shared_preferences | Lưu JWT + cấu hình |
| socket_io_client | Realtime Socket.IO |
| flutter_map + latlong2 | Bản đồ miễn phí (OpenStreetMap) |
| geocoding | Reverse geocoding (Nominatim) + cache |
| image_picker | Chọn ảnh từ thư viện/camera |
| flutter_local_notifications | Thông báo nội bộ (SOS/té ngã/nhịp tim) |
| cupertino_icons | Icon iOS style |

Backend: express, sequelize, mysql2, socket.io, jsonwebtoken, bcryptjs, joi, winston, winston-daily-rotate-file, morgan, helmet, cors, dotenv, uuid. Dev: jest, supertest, nodemon, sequelize-cli.

Trình giả lập: flutter_riverpod, dio, socket_io_client, geolocator, dartz, intl, cupertino_icons.

---

## 8. Kiến trúc và quy ước mã

- Ứng dụng chính: tầng `services` gọi backend, `AppState` giữ trạng thái toàn cục (ChangeNotifier), UI lắng nghe qua AnimatedBuilder. Không còn mock/dữ liệu giả; khi chưa kết nối thiết bị, UI hiển thị trạng thái rỗng/0.
- Singleton: `ApiClient`, `AppState`, `DeviceEventService`, `SocketIoService`, `NotificationService`.
- Backend: controllers (HTTP) -> services (business + Socket.IO emit) -> repositories (Sequelize). Response envelope thống nhất, error handling tập trung, validation Joi.
- Trình giả lập: Clean Architecture tách domain/data/presentation, Riverpod quản lý state, Dio gọi HTTP, Result/Failure xử lý lỗi.
- Quy ước code của dự án: file dưới 200 dòng (cần thì phân module), tên file kebab-case mô tả rõ nghĩa, code comment tiếng Việt ngắn gọn.

---

## 9. Các lưu ý quan trọng

- Backend chạy port 8080; cả hai app Flutter đều kết nối đến đây.
- Trên Android emulator bắt buộc dùng `10.0.2.2` thay `localhost` (đã tự resolve).
- Sau login, JWT được gửi qua hai kênh Socket.IO (`auth` + `?token=`) để đảm bảo join room `user:<id>` và nhận event scoped; tránh tình trạng mất realtime phải re-login mới thấy.
- DECIMAL từ backend trả về String -> parse kiểu nhường ở Flutter.
- Trong dev, endpoint POST thiết bị là public; production nên bật `DEVICE_AUTH_MODE=token`.
- Đổi `JWT_SECRET` và khóa CORS, bật HTTPS trong production.

---

## 10. Cấu trúc thư mục gốc

```
flutter_application_1/
  README.md                      (file này)
  pubspec.yaml / pubspec.lock
  analysis_options.yaml
  start.bat                       (khởi động 3 project)
  android/  windows/  lib/  build/  .dart_tool/  .git/
  lib/                            (ứng dụng chính - xem mục 2.2)
  Project_GiaLap/
    sos_care_backend/             (backend - xem mục 3.2)
    sos_device_simulator/         (trình giả lập - xem mục 4.1)
```

---
