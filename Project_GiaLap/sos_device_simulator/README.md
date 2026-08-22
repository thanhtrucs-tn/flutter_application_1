> **SOS Device Simulator** — Ứng dụng Flutter giả lập thiết bị đeo SOS dành cho người cao tuổi, phục vụ kiểm thử hệ thống SOS Care.

## Tính năng chính

- Màn hình chính hiển thị thẻ thông tin thiết bị: Device ID, trạng thái Online/Offline, mức pin, nhịp tim, GPS, thời gian cập nhật.
- Nút SOS màu đỏ lớn ở giữa màn hình, có hộp thoại xác nhận trước khi gọi API.
- Các nút chức năng: giả lập té ngã, giả lập nhịp tim bất thường, giả lập mất kết nối, gửi vị trí hiện tại.
- Slider điều chỉnh pin 0–100%, slider nhịp tim 50–180 BPM.
- Tự động gửi cảnh báo `HEART_RATE_ALERT` khi BPM > 110.
- Công tắc Online/Offline: khi Offline thì ngừng gửi mọi dữ liệu lên server.
- Mock API Service tích hợp sẵn để chạy thử ngay cả khi chưa có backend thật.
- Snackbar thông báo thành công / thất bại cho mỗi thao tác.

## Kiến trúc

Dự án áp dụng **Feature-First** + **Clean Architecture** + **Riverpod**.

```
lib/
├── core/                         # Config, constants, errors, services, utils
├── features/sos_simulator/
│   ├── data/
│   │   ├── models/               # Payload models
│   │   └── repositories/         # Remote, mock, repository impl
│   ├── domain/
│   │   ├── entities/             # DeviceStatus entity
│   │   └── repositories/         # Repository interface
│   ├── application/
│   │   └── services/             # LocationService (geolocator wrapper)
│   └── presentation/
│       ├── providers/            # Riverpod providers + DeviceStatusNotifier
│       ├── screens/              # HomeScreen
│       └── widgets/              # Reusable UI widgets
└── main.dart
```

## Các package cần cài đặt

Danh sách đã có trong `pubspec.yaml`:

| Package | Mục đích |
|---------|----------|
| `flutter_riverpod` | State management |
| `dio` | HTTP client |
| `geolocator` | Lấy GPS thật của điện thoại |
| `dartz` | Kiểu `Either` cho xử lý lỗi |
| `intl` | Định dạng ngày giờ |
| `cupertino_icons` | Icon bổ sung |
| `flutter_lints` | Lint cơ bản |

## API Endpoints

| Phương thức | Endpoint | Payload | Mô tả |
|-------------|----------|---------|-------|
| POST | `/api/sos` | `{deviceId, elderlyId, timestamp, latitude, longitude, type="SOS"}` | Gửi cảnh báo SOS |
| POST | `/api/events` | `{deviceId, elderlyId, timestamp, latitude, longitude, type}` | Gửi sự kiện (`FALL_DETECTED`, `HEART_RATE_ALERT`) |
| POST | `/api/location` | `{deviceId, elderlyId, timestamp, latitude, longitude}` | Gửi vị trí hiện tại |
| POST | `/api/device/battery` | `{deviceId, elderlyId, timestamp, batteryPercent}` | Cập nhật mức pin |

Base URL và chế độ mock được cấu hình trong `lib/core/config/api_config.dart`:

```dart
static const String baseUrl = 'http://localhost:8081';
static const bool useMock = true;   // đặt false để dùng backend thật
```

## Hướng dẫn chạy project

### 1. Chuẩn bị môi trường

- Cài đặt [Flutter SDK](https://docs.flutter.dev/get-started/install) (khuyến nghị bản ổn định mới nhất).
- Cài đặt Android Studio hoặc Visual Studio Code với Flutter extension.
- Cài đặt JDK 17 (cần thiết cho build Android).
- Chạy `flutter doctor` để kiểm tra môi trường:

```bash
flutter doctor
```

### 2. Clone / mở project

```bash
cd "D:\App Mobile\SOS Device Simulator\sos_device_simulator"
```

### 3. Cài đặt dependencies

```bash
flutter pub get
```

### 4. Chạy ứng dụng

#### Android

```bash
flutter run
```

hoặc chọn thiết bị:

```bash
flutter devices
flutter run -d <device_id>
```

#### Windows (smoke test)

```bash
flutter run -d windows
```

#### Build APK debug

```bash
flutter build apk --debug
```

### 5. Phân quyền

Ứng dụng đã khai báo quyền trong `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

Trên Android 10+ cần cấp quyền vị trí khi ứng dụng chạy. Nếu từ chối, ứng dụng sẽ dùng tọa độ mặc định.

### 6. Chạy test

```bash
flutter test
```

## Ghi chú

- Mặc định ứng dụng chạy ở chế độ **mock**. Muốn kết nối backend thật, sửa `ApiConfig.useMock = false` và cập nhật `ApiConfig.baseUrl`.
- `AndroidManifest.xml` đã bật `android:usesCleartextTraffic="true"` để test với backend local HTTP. Trước khi release production với HTTPS, hãy xóa/tắt thuộc tính này.
- Nếu build Android báo lỗi `javaHome invalid`, kiểm tra biến môi trường `JAVA_HOME` và đảm bảo JDK được cài đặt đúng đường dẫn.
- GPS trên máy ảo Android có thể yêu cầu bật location trong cài đặt máy ảo.
