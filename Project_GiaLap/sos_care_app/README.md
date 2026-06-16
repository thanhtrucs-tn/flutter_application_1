> **SOS Care App** — Ứng dụng Flutter dành cho người thân, nhận cảnh báo và trạng thái realtime từ thiết bị SOS thông qua backend Node.js + Socket.IO.

## Tính năng chính

- Kết nối Socket.IO với backend SOS Care để nhận dữ liệu realtime.
- Nhận cảnh báo `SOS`, `FALL_DETECTED`, `HEART_RATE_ALERT` và hiển thị thông báo đẩy local.
- Cập nhật vị trí GPS (`device:location`) và trạng thái thiết bị (`device:status`) theo thời gian thực.
- Dashboard hiển thị danh sách thiết bị, trạng thái Online/Offline, pin, nhịp tim, GPS.
- Lịch sử cảnh báo với đánh dấu đã đọc.
- State management bằng Riverpod.

## Kiến trúc

```
lib/
├── core/                         # Config, constants, errors, Dio client
└── features/sos_care/
    ├── data/
    │   ├── models/               # CareAlert, CareDevice, CareLocation, CareDeviceStatus models
    │   └── repositories/         # Remote repository
    ├── domain/
    │   ├── entities/             # Domain entities
    │   └── repositories/           # Repository interface
    ├── application/
    │   └── services/             # SocketIOService, NotificationService
    └── presentation/
        ├── providers/            # Riverpod notifiers
        ├── screens/              # Dashboard, Alerts
        └── widgets/              # DeviceCard, AlertCard, ConnectionStatusBar
```

## Các package cần cài đặt

| Package | Mục đích |
|---------|----------|
| `flutter_riverpod` | State management |
| `dio` | HTTP client |
| `socket_io_client` | Socket.IO client |
| `flutter_local_notifications` | Thông báo đẩy foreground |
| `intl` | Định dạng ngày giờ |
| `dartz` | Kiểu `Either` |

## Hướng dẫn chạy

### 1. Chuẩn bị

- Cài đặt Flutter SDK.
- Khởi động backend `sos_care_backend` (`npm run dev`).
- Đảm bảo MySQL đã chạy và migrations đã được áp dụng.

### 2. Cài dependencies

```bash
cd "D:\App Mobile\SOS Device Simulator\sos_care_app"
flutter pub get
```

### 3. Cấu hình backend URL

Mở `lib/core/config/api_config.dart` và sửa `baseUrl` / `socketUrl`:

- Windows / macOS / iOS simulator: `http://localhost:8080`
- Android emulator: `http://10.0.2.2:8080`
- Production: URL backend thật

### 4. Chạy ứng dụng

```bash
flutter run
```

hoặc chọn thiết bị:

```bash
flutter devices
flutter run -d <device_id>
```

### 5. Kiểm tra realtime

1. Khởi động `sos_device_simulator` và chuyển `useMock = false`.
2. Trên SOS Device Simulator, bấm nút SOS hoặc "Giả lập té ngã".
3. SOS Care app sẽ nhận cảnh báo trong vài giây và hiển thị notification + card trên dashboard.

## Phân quyền

`AndroidManifest.xml` đã khai báo:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

Trên Android 13+ cần cấp quyền thông báo khi ứng dụng chạy.

## Ghi chú

- Ứng dụng tự động reconnect Socket.IO khi mất kết nối.
- Các endpoint REST (`/api/history`, `/api/device/:id`) hiện tại yêu cầu JWT; để load dữ liệu lịch sử cần đăng nhập. Trong flow demo, dữ liệu realtime từ Socket.IO đủ để hiển thị thiết bị mà không cần đăng nhập.
- `usesCleartextTraffic="true"` được bật cho backend local HTTP; tắt trước khi release production HTTPS.
