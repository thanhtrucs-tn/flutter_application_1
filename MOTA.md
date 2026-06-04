# MÔ TẢ DỰ ÁN - SOS CARE

## Tổng quan

**SOS Care** là ứng dụng di động cross-platform được xây dựng bằng **Flutter**, nhằm giám sát sức khỏe và an toàn của **người cao tuổi** thông qua thiết bị đeo thông minh (ESP32 Smart Band). Ứng dụng cung cấp khả năng theo dõi real-time các chỉ số sinh tồn quan trọng, phát hiện sự cố khẩn cấp (té ngã, nhịp tim bất thường, ra khỏi vùng an toàn), và gửi cảnh báo SOS ngay lập tức đến người thân giám sát.

---

## Công nghệ sử dụng

| Thành phần | Công nghệ |
|---|---|
| Framework | Flutter (Dart) - SDK ^3.12.0 |
| Database | MySQL (qua package `mysql1`) |
| Local Storage | Shared Preferences (fallback offline) |
| UI Design | Material Design 3 + hỗ trợ Dark/Light Mode |
| Nền tảng | Android, iOS, Web, Windows, macOS, Linux |

---

## Kiến trúc hệ thống

```
lib/
├── main.dart                    # Entry point, khởi tạo AppState & Theme
├── database/
│   ├── db_helper.dart           # Kết nối MySQL + fallback SharedPreferences
│   └── mock_data.dart           # Dữ liệu giả lập mặc định
├── models/
│   ├── elderly_model.dart       # Model thông tin người cao tuổi
│   ├── alert_model.dart         # Model cảnh báo SOS
│   └── app_settings.dart        # Model cài đặt ứng dụng
├── screens/
│   ├── login_screen.dart        # Đăng nhập / Đăng ký
│   ├── home_screen.dart         # Dashboard tổng quan (bản đồ, danh sách)
│   ├── detail_screen.dart       # Chi tiết sức khỏe người cao tuổi
│   ├── alert_detail_screen.dart # Màn hình cảnh báo khẩn cấp (fullscreen)
│   └── settings_screen.dart     # Cài đặt ngôn ngữ, dark mode, thông báo
├── utils/
│   ├── app_state.dart           # Singleton quản lý state toàn cục + simulation
│   ├── localization.dart        # Hệ thống đa ngôn ngữ (VI/EN)
│   └── theme.dart               # Light/Dark theme configuration
└── widgets/
    ├── big_button.dart          # Custom button component
    ├── custom_map.dart          # Widget bản đồ tùy chỉnh
    └── health_chart.dart        # Biểu đồ sức khỏe
```

---

## Tính năng chính

### 1. Giám sát Real-time
- Theo dõi **nhịp tim**, **SpO2**, **mức pin** thiết bị
- Cập nhật vị trí GPS liên tục
- Trạng thái kết nối thiết bị (Online/Offline)

### 2. Cảnh báo SOS thông minh
- **Té ngã (Fall Detection)**: Tự động phát hiện và báo động
- **Vùng an toàn (Geofence)**: Cảnh báo khi người cao tuổi đi ra khỏi bán kính an toàn
- **Chỉ số sinh tồn bất thường**: Nhịp tim > 100 bpm hoặc SpO2 < 93%
- Màn hình cảnh báo fullscreen với âm thanh/vibration

### 3. Quản lý người cao tuổi
- Thêm/xóa/sửa thông tin người được giám sát
- Cấu hình vùng an toàn tùy chỉnh (tâm + bán kính)
- Danh sách số điện thoại khẩn cấp (JSON)

### 4. Đa ngôn ngữ & Giao diện
- Hỗ trợ **Tiếng Việt** và **Tiếng Anh**
- Chế độ **Sáng/Tối** (Dark Mode)
- Responsive cho nhiều kích thước màn hình

### 5. Chế độ Offline
- Khi không kết nối MySQL, tự động chuyển sang **SharedPreferences**
- Dữ liệu đăng nhập và cài đặt được lưu cục bộ
- Demo mode với dữ liệu mô phỏng

---

## Cơ sở dữ liệu (MySQL)

**Database**: `test_123`

| Bảng | Mô tả |
|---|---|
| `users` | Tài khoản người thân giám sát (username, password) |
| `elderly` | Thông tin người cao tuổi, chỉ số sức khỏe, vùng an toàn |
| `alerts` | Lịch sử cảnh báo SOS (thời gian, vị trí, mức độ, trạng thái xử lý) |

### Trạng thái hệ thống
- `safe`: Bình thường
- `warning`: Cần lưu ý (nhịp tim cao, SpO2 thấp)
- `critical`: Khẩn cấp (té ngã, ra khỏi vùng an toàn)

---

## Mô phỏng dữ liệu (Simulation)

Ứng dụng tích hợp **Timer mô phỏng** (4 giây/lần) để demo:
- Dao động nhịp tim (60-105 bpm)
- Dao động SpO2 (92-100%)
- Giảm pin dần theo thời gian
- Di chuyển GPS ngẫu nhiên
- Mô phỏng mất kết nối WebSocket (5%)

### Kịch bản kiểm thử thủ công
- `simulateFall()`: Giả lập té ngã
- `simulateExitSafeZone()`: Giả lập ra khỏi vùng an toàn
- `simulateHeartRateSpike()`: Giả lập nhịp tim & SpO2 bất thường

---

## Cấu hình kết nối

```dart
// db_helper.dart
host: '127.0.0.1' (Desktop) / '10.0.2.2' (Android Emulator)
port: 3306
user: 'root'
database: 'test_123'
timeout: 2 giây
```

---

## Dependencies

```yaml
dependencies:
  flutter: sdk
  mysql1: ^0.20.0          # Kết nối MySQL
  shared_preferences: ^2.3.2  # Lưu trữ local
  cupertino_icons: ^1.0.8     # iOS style icons
```

---

## Cách chạy dự án

1. **Khởi tạo database**:
   ```bash
   # Chạy file db_script.sql trong MySQL/phpMyAdmin
   ```

2. **Cài đặt dependencies**:
   ```bash
   flutter pub get
   ```

3. **Chạy ứng dụng**:
   ```bash
   flutter run
   ```

---

## Thông tin đăng nhập mặc định

| Username | Password |
|---|---|
| admin | admin123 |

---

## Tác giả & Lịch sử

- **Phiên bản**: 1.0.0+1
- **Ngày cập nhật**: 2026-06-03
- **Git commits**:
  - `0f83778`: Update lần 1 - Tối ưu và sửa lỗi
  - `6e1f224`: first commit

---

## Ghi chú phát triển

- Ứng dụng hiện đang ở giai đoạn **MVP/Prototype**
- Cần thay thế mô phỏng bằng kết nối **WebSocket/REST API** thực tế với ESP32
- Cần bổ sung **Push Notification** (Firebase Cloud Messaging) cho cảnh báo
- Cần mã hóa password (hiện tại lưu plaintext)
- Cần xử lý security cho kết nối MySQL (hiện tại dùng root không password)
