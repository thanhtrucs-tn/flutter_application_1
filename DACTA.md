# DACTA — Đặc tả chi tiết hệ thống thông tin SOS Care

> Tài liệu Phân tích & Thiết kế hệ thống thông tin (Analysis & Design) theo chuẩn hướng đối tượng (UML) cho dự án **SOS Care — Hệ thống chăm sóc người cao tuổi**.
> Toàn bộ nội dung bằng tiếng Việt có dấu. Mọi sơ đồ được viết bằng cú pháp **PlantUML**, có thể render trực tiếp (PlantUML server / plugin VS Code / IntelliJ).

---

## Mục lục

1. [Mô tả hệ thống](#1-mô-tả-hệ-thống)
2. [Phân tích yêu cầu](#2-phân-tích-yêu-cầu)
3. [Sơ đồ Use Case (Use Case Diagram)](#3-sơ-đồ-use-case)
4. [Đặc tả Use Case (Use Case Specification)](#4-đặc-tả-use-case)
5. [Sơ đồ Hoạt động (Activity Diagram)](#5-sơ-đồ-hoạt-động)
6. [Sơ đồ Trình tự (Sequence Diagram)](#6-sơ-đồ-trình-tự)
7. [Sơ đồ Lớp (Class Diagram)](#7-sơ-đồ-lớp)
8. [Sơ đồ ERD (Entity Relationship Diagram)](#8-sơ-đồ-erd)
9. [Sơ đồ Trạng thái (State Diagram)](#9-sơ-đồ-trạng-thái)
10. [Sơ đồ Thành phần (Component Diagram)](#10-sơ-đồ-thành-phần)

---

## 1. Mô tả hệ thống

### 1.1 Mục tiêu hệ thống

Hệ thống **SOS Care** hỗ trợ giám sát sức khỏe, vị trí và an toàn của người cao tuổi theo thời gian thực, giúp người chăm sóc (con cái / bảo mẫu / quản trị viên) phản ứng kịp thời khi có sự cố khẩn cấp (SOS, té ngã, nhịp tim bất thường, vượt vùng an toàn).

### 1.2 Bố cục ba thành phần phân tán

| Thành phần | Công nghệ | Vai trò |
|-----------|-----------|---------|
| Ứng dụng chăm sóc (`flutter_application_1`) | Flutter >= 3.41, Dart >= 3.12 | App chính cho người chăm sóc: đăng nhập, quản lý người thân, nhận cảnh báo realtime, bản đồ, chỉ số sức khỏe, hành động từ xa |
| Backend (`sos_care_backend`) | Node.js + Express + MySQL + Sequelize + Socket.IO | REST API + realtime: tiếp nhận dữ liệu thiết bị, phát cảnh báo, xác thực JWT |
| Trình giả lập thiết bị (`sos_device_simulator`) | Flutter + Riverpod + Dio | Giả lập wearable SOS: gửi SOS, té ngã, vị trí, trạng thái thiết bị |

### 1.3 Tác nhân (Actor)

| Actor | Mô tả |
|-------|-------|
| **Người chăm sóc (Caregiver)** | Người dùng chính của app Flutter: quản lý người thân, theo dõi realtime, xử lý cảnh báo |
| **Quản trị viên (Admin)** | Tác nhân đặc biệt của Caregiver, có quyền quản trị hệ thống |
| **Người cao tuổi (Elderly)** | Đối tượng được chăm sóc, đeo thiết bị wearable (đại diện bởi trình giả lập) |
| **Thiết bị đeo (Wearable/Simulator)** | Hệ thống ngoài phát dữ liệu telemetries (SOS, vị trí, sự kiện, trạng thái) lên backend |
| **Hệ thống Backend** | Hệ thống phụ trợ xử lý nghiệp vụ, lưu DB, phát realtime |

---

## 2. Phân tích yêu cầu

### 2.1 Yêu cầu chức năng (Functional Requirements)

- **REQ-01 — Quản lý tài khoản**: đăng ký, đăng nhập (JWT), tự đăng xuất khi token hết hạn (401), lưu profile theo tài khoản, đồng bộ DB.
- **REQ-02 — Quản lý người thân**: thêm / sửa / xóa / sắp xếp lại người cao tuổi, gán thiết bị wearable, cấu hình vùng an toàn (geofence).
- **REQ-03 — Quản lý liên hệ khẩn cấp**: thêm / sửa / xóa liên hệ khẩn cấp cho từng người thân.
- **REQ-04 — Giám sát realtime**: nhận cảnh báo SOS, té ngã (FALL_DETECTED), nhịp tim/SpO2 bất thường, vị trí, trạng thái thiết bị qua Socket.IO.
- **REQ-05 — Lịch sử sự cố**: xem, lọc, xem chi tiết cảnh báo.
- **REQ-06 — Bản đồ**: xem vị trí hiện tại, vùng an toàn, bản đồ toàn màn hình (OpenStreetMap).
- **REQ-07 — Chỉ số sức khỏe**: nhịp tim, SpO2, mức pin, biểu đồ theo thời gian.
- **REQ-08 — Hành động từ xa**: gọi điện, nghe xung quanh, bật chuông, nhắn tin khẩn cấp, kích hoạt SOS từ xa.
- **REQ-09 — Cấu hình**: chế độ Sáng/Tối, ngôn ngữ vi/en, thông báo, vùng an toàn.

### 2.2 Yêu cầu phi chức năng (Non-functional Requirements)

- **NFR-01 Hiệu năng**: cảnh báo realtime truyền trong < 2 giây từ thiết bị đến app.
- **NFR-02 Khả dụng**: tự kết nối lại Socket.IO (60 lần, delay 1s).
- **NFR-03 Bảo mật**: JWT, bcryptjs hash mật khẩu, CORS giới hạn origin, HTTPS trong production, xác thực device token khi cần.
- **NFR-04 Khả năng mở rộng**: kiến trúc controller → service → repository, envelope response thống nhất.
- **NFR-05 Đa nền tảng**: Flutter chạy Android / Windows; backend Node.js độc lập nền.
- **NFR-06 Quốc tế hóa**: đa ngôn ngữ vi/en, theme Sáng/Tối.

---

## 3. Sơ đồ Use Case

> Phạm vi: ứng dụng chăm sóc + backend + trình giả lập thiết bị.

```plantuml
@startuml use-case
left to right direction
skinparam packageStyle rectangle
skinparam actorStyle awesome
skinparam usecaseBackgroundColor #EAF6FF

actor "Người chăm sóc" as Caregiver
actor "Quản trị viên" as Admin
actor "Thiết bị đeo\n(Simulator)" as Device
actor "Hệ thống Backend" as Backend

rectangle "Hệ thống SOS Care" {

  package "Xác thực & Tài khoản" {
    usecase "Đăng ký tài khoản" as UC_Reg
    usecase "Đăng nhập (JWT)" as UC_Login
    usecase "Đăng xuất" as UC_Logout
    usecase "Xem & sửa hồ sơ cá nhân" as UC_Profile
  }

  package "Quản lý người thân & Liên hệ" {
    usecase "Quản lý người thân\n(thêm/sửa/xóa/sắp xếp)" as UC_Relative
    usecase "Gán thiết bị wearable" as UC_Pair
    usecase "Cấu hình vùng an toàn" as UC_SafeZone
    usecase "Quản lý liên hệ khẩn cấp" as UC_Contact
  }

  package "Giám sát & Cảnh báo" {
    usecase "Xem tổng quan an toàn" as UC_Home
    usecase "Nhận cảnh báo realtime" as UC_Realtime
    usecase "Xem lịch sử sự cố" as UC_History
    usecase "Lọc & xem chi tiết cảnh báo" as UC_Detail
  }

  package "Bản đồ & Sức khỏe" {
    usecase "Xem vị trí trên bản đồ" as UC_Map
    usecase "Xem chỉ số sức khỏe\n(nhịp tim/SpO2/pin)" as UC_Health
  }

  package "Hành động từ xa" {
    usecase "Kích hoạt SOS từ xa" as UC_RemoteSOS
    usecase "Gọi điện / Nhắn tin khẩn cấp" as UC_Call
    usecase "Nghe xung quanh" as UC_Ambient
    usecase "Bật chuông thiết bị" as UC_Ring
  }

  package "Cấu hình hệ thống" {
    usecase "Cấu hình ứng dụng\n(ngôn ngữ/giao diện/thông báo)" as UC_Settings
  }

  package "Tiếp nhận dữ liệu thiết bị" {
    usecase "Gửi SOS" as UC_SendSOS
    usecase "Gửi sự kiện\n(té ngã/nhịp tim)" as UC_SendEvent
    usecase "Gửi vị trí GPS" as UC_SendLocation
    usecase "Gửi trạng thái thiết bị\n(pin/nhịp tim/online)" as UC_SendStatus
  }
}

' --- Quan hệ tác nhân ---
Caregiver --> UC_Reg
Caregiver --> UC_Login
Caregiver --> UC_Logout
Caregiver --> UC_Profile
Caregiver --> UC_Home
Caregiver --> UC_Realtime
Caregiver --> UC_History
Caregiver --> UC_Detail
Caregiver --> UC_Map
Caregiver --> UC_Health
Caregiver --> UC_Relative
Caregiver --> UC_Contact
Caregiver --> UC_RemoteSOS
Caregiver --> UC_Call
Caregiver --> UC_Ambient
Caregiver --> UC_Ring
Caregiver --> UC_Settings

Admin --|> Caregiver

Device --> UC_SendSOS
Device --> UC_SendEvent
Device --> UC_SendLocation
Device --> UC_SendStatus

' --- Include / Extend ---
UC_Home ..> UC_Realtime : <<include>>
UC_Relative ..> UC_Pair : <<include>>
UC_Relative ..> UC_SafeZone : <<include>>
UC_History ..> UC_Detail : <<include>>
UC_SendSOS ..> UC_Realtime : <<extend>>
UC_SendEvent ..> UC_Realtime : <<extend>>

Backend --> UC_Realtime : phát Socket.IO
Backend --> UC_History : truy vấn DB

@enduml
```

---

## 4. Đặc tả Use Case

### 4.1 Đặc tả UC-01 — Đăng nhập

| Hạng mục | Nội dung |
|----------|----------|
| **Tên Use Case** | Đăng nhập (Login) |
| **Mã** | UC-01 |
| **Tác nhân** | Người chăm sóc / Quản trị viên |
| **Mô tả** | Người dùng nhập email + mật khẩu để xác thực và nhận JWT, sau đó truy cập các chức năng của hệ thống |
| **Điều kiện trước** | Đã có tài khoản đăng ký; thiết bị có kết nối mạng |
| **Luồng sự kiện chính** | 1. Người dùng mở app → màn hình đăng nhập. 2. Nhập email, mật khẩu. 3. App gửi `POST /api/auth/login`. 4. Backend kiểm tra tài khoản + bcrypt hash. 5. Backend phát JWT. 6. App lưu JWT (shared_preferences), khởi tạo `SocketIoService` với JWT. 7. Chuyển vào màn hình chính. |
| **Luồng rẽ nhánh** | a. Sai mật khẩu → thông báo lỗi, ở lại màn đăng nhập. b. Token hết hạn (401) khi dùng app → tự đăng xuất về màn đăng nhập. c. Mất mạng → hiển thị lỗi kết nối. |
| **Điều kiện sau** | Người dùng được xác thực, realtime Socket.IO được thiết lập (join room `user:<id>`) |

### 4.2 Đặc tả UC-02 — Quản lý người thân

| Hạng mục | Nội dung |
|----------|----------|
| **Mã** | UC-02 |
| **Tác nhân** | Người chăm sóc |
| **Mô tả** | Thêm / sửa / xóa / sắp xếp lại danh sách người cao tuổi, gán thiết bị wearable, cấu hình vùng an toàn |
| **Điều kiện trước** | Đã đăng nhập |
| **Luồng chính** | 1. Vào phần quản lý người thân. 2. Chọn Thêm / Sửa / Xóa / Kéo sắp xếp. 3. Nhập thông tin (tên, tuổi, địa chỉ, thiết bị, vùng an toàn). 4. App gọi REST `relatives` API. 5. Backend lưu/đổi DB (bảng `relatives`). 6. Cập nhật `AppState`, làm mới UI. |
| **Luồng rẽ nhánh** | a. `deviceElderlyId` trùng → lỗi unique. b. Xóa người thân có cảnh báo đang hoạt động → xác nhận cascade. c. Lỗi mạng → giữ thao tác cục bộ, thử lại. |
| **Điều kiện sau** | DB và UI đồng bộ danh sách người thân |

### 4.3 Đặc tả UC-03 — Nhận cảnh báo realtime

| Hạng mục | Nội dung |
|----------|----------|
| **Mã** | UC-03 |
| **Tác nhân** | Người chăm sóc (chủ động), Thiết bị đeo (kích hoạt gián tiếp) |
| **Mô tả** | Khi thiết bị gửi SOS/sự kiện/vị trí/trạng thái, backend phát Socket.IO event, app nhận và hiển thị cảnh báo + thông báo nội bộ |
| **Điều kiện trước** | Đã đăng nhập, Socket.IO đã join room `user:<id>` |
| **Luồng chính** | 1. Thiết bị gửi `POST /api/sos` (hoặc `/api/events`, `/api/location`, `/api/device/status`). 2. Backend lưu telemetries, tạo `Alert` (denormalize `userId`). 3. Backend phát `sos:alert` / `event:fall` / `event:heart_rate` / `device:location` / `device:status` tới room `user:<id>`. 4. `DeviceEventService` nhận event → map payload (`DeviceEventMapper`) → cập nhật `AppState`. 5. `AppState` (ChangeNotifier) thông báo UI qua `AnimatedBuilder`. 6. `NotificationService` đẩy thông báo nội bộ. 7. UI hiển thị banner cảnh báo + cập nhật card người thân. |
| **Luồng rẽ nhánh** | a. Socket rớt → tự kết nối lại (forceNew + re-auth). b. Payload DECIMAL → parse kiểu nhường (không `as num?`). |
| **Điều kiện sau** | Người chăm sóc nhìn thấy cảnh báo gần như tức thời |

### 4.4 Đặc tả UC-04 — Xem lịch sử sự cố

| Hạng mục | Nội dung |
|----------|----------|
| **Mã** | UC-04 |
| **Tác nhân** | Người chăm sóc |
| **Mô tả** | Xem danh sách cảnh báo, lọc theo loại/người thân/thời gian, xem chi tiết từng cảnh báo |
| **Điều kiện trước** | Đã đăng nhập |
| **Luồng chính** | 1. Vào tab cảnh báo. 2. App gọi `GET /api/history` (JWT). 3. Backend truy vấn `alerts` + telemetries theo `userId`. 4. Hiển thị danh sách + bộ lọc. 5. Người dùng chọn mục → `GET` chi tiết. 6. Hiển thị chi tiết (loại, thời gian, vị trí, mức ưu tiên, trạng thái xác nhận). |
| **Điều kiện sau** | Người dùng nắm được diễn biến sự cố |

### 4.5 Đặc tả UC-05 — Kích hoạt SOS từ xa

| Hạng mục | Nội dung |
|----------|----------|
| **Mã** | UC-05 |
| **Tác nhân** | Người chăm sóc |
| **Mô tả** | Người chăm sóc chủ động kích hoạt cảnh báo SOS cho người thân đang đeo thiết bị |
| **Điều kiện trước** | Đã đăng nhập, có người thân đã pair thiết bị online |
| **Luồng chính** | 1. Chọn người thân → nút "Kích hoạt SOS từ xa". 2. Xác nhận dialog. 3. App gửi REST tới backend. 4. Backend tạo `Alert` urgency=critical + phát event realtime. 5. Thiết bị (simulator) nhận ack và phát chuông/hồi đáp. |
| **Điều kiện sau** | Cảnh báo SOS được ghi nhận và thiết bị phản hồi |

### 4.6 Đặc tả UC-06 — Thiết bị gửi dữ liệu telemetries

| Hạng mục | Nội dung |
|----------|----------|
| **Mã** | UC-06 |
| **Tác nhân** | Thiết bị đeo (Simulator) |
| **Mô tả** | Thiết bị gửi SOS / sự kiện / vị trí / trạng thái lên backend |
| **Điều kiện trước** | Thiết bị đã cấu hình `deviceElderlyId`, backend online |
| **Luồng chính** | 1. Người cao tuổi nhấn nút SOS hoặc sensor phát hiện té ngã/nhịp tim. 2. Simulator gửi REST tới `/api/sos`, `/api/events`, `/api/location`, `/api/device/status`. 3. Backend lưu + phát realtime. 4. Simulator nhận Socket.IO ack báo giao thành công. |
| **Luồng rẽ nhánh** | a. `useMock=true` → dùng mock data source, không cần backend. b. `DEVICE_AUTH_MODE=token` → phải gửi header `X-Device-Token`. |
| **Điều kiện sau** | Dữ liệu telemetries được lưu và lan truyền realtime |

---

## 5. Sơ đồ Hoạt động

### 5.1 Hoạt động đăng nhập & thiết lập realtime

```plantuml
@startuml activity-login
skinparam activityBackgroundColor #EAF6FF
title Sơ đồ hoạt động — Đăng nhập và thiết lập realtime

start
:Người dùng mở ứng dụng;
:Hiển thị màn hình đăng nhập;
:Nhập email + mật khẩu;
:Gửi POST /api/auth/login tới Backend;
:Backend kiểm tra tài khoản + bcrypt hash;
if (Hợp lệ?) then (có)
  :Backend phát JWT (userId, role, hết hạn);
  :App lưu JWT vào shared_preferences;
  :Khởi tạo ApiClient + AuthService;
  :Khởi tạo SocketIoService (JWT handshake + ?token=);
  :Backend join room user:<id>;
  :Nạp AppState (người thân, cảnh báo, cài đặt);
  :Chuyển tới MainShell (HomeScreen);
else (không)
  :Hiển thị lỗi đăng nhập;
endif
stop

@enduml
```

### 5.2 Hoạt động xử lý cảnh báo realtime (end-to-end)

```plantuml
@startuml activity-alert
skinparam activityBackgroundColor #EAF6FF
title Sơ đồ hoạt động — Xử lý cảnh báo realtime toàn tuyến

start
:Thiết bị: phát hiện sự kiện\n(SOS / té ngã / nhịp tim / vị trí);
:Thiết bị: gửi REST (POST /api/sos | events | location | device/status);
:Backend: nhận payload + validate (Joi);
if (Auth device OK?) then (có)
  :Backend: lưu telemetries\n(sos_alerts / events / locations / device_statuses);
  :Backend: khớp deviceId -> relative -> userId;
  :Backend: tạo Alert (denormalize userId, urgency, type);
  if (Vượt vùng an toàn?) then (có)
    :Backend: tạo Alert loại geofence;
  else (không)
  endif
  :Backend: phát Socket.IO event tới room user:<id>;
  :Thiết bị: nhận ack giao thành công;
  :App: DeviceEventService lắng nghe event;
  :App: DeviceEventMapper ánh xạ payload -> model\n(resolve baseUrl Android emulator);
  if (DECIMAL trả String?) then (có)
    :App: parse kiểu nhường (tolerant);
  else (không)
  endif
  :App: cập nhật AppState (ChangeNotifier);
  :App: NotificationService đẩy thông báo nội bộ;
  :App: UI AnimatedBuilder làm mới\n(banner cảnh báo + card người thân);
  if (Cảnh báo critical?) then (có)
    :App: hiển thị modal ưu tiên cao;
  else (không)
    :App: hiển thị banner nhẹ;
  endif
else (không)
  :Backend: từ chối 401/403;
endif
stop

@enduml
```

### 5.3 Hoạt động quản lý người thân

```plantuml
@startuml activity-relative
skinparam activityBackgroundColor #EAF6FF
title Sơ đồ hoạt động — Quản lý người thân

start
:Người dùng vào phần quản lý người thân;
:Chọn thao tác (Thêm/Sửa/Xóa/Sắp xếp);
switch (Thao tác)
case (Thêm / Sửa)
  :Mở dialog nhập liệu\n(tên, tuổi, địa chỉ, thiết bị, vùng an toàn);
  :Gửi REST relatives API (JWT);
  :Backend validate + kiểm tra deviceElderlyId unique;
  if (Hợp lệ?) then (có)
    :Lưu/đổi bảng relatives;
    :Cập nhật AppState + làm mới danh sách;
  else (không)
    :Hiển thị lỗi validation;
  endif
case (Xóa)
  :Hiển thị dialog xác nhận;
  if (Xác nhận?) then (có)
    :Gửi DELETE relatives API;
    :Backend xóa cascade emergency_contacts;
    :Cập nhật AppState;
  else (không)
    :Hủy thao tác;
  endif
case (Sắp xếp)
  :Kéo thay thứ tự;
  :Cập nhật thứ tự AppState + backend;
endswitch
stop

@enduml
```

---

## 6. Sơ đồ Trình tự

### 6.1 Trình tự — Đăng nhập & thiết lập realtime

```plantuml
@startuml seq-login
title Sơ đồ trình tự — Đăng nhập & thiết lập realtime

actor "Người chăm sóc" as U
participant "LoginScreen" as LS
participant "AuthService" as Auth
participant "ApiClient" as API
participant "TokenStorage" as TS
participant "SocketIoService" as Sock
participant "Backend" as BE
participant "SocketHandler" as SH

U -> LS: Nhập email, mật khẩu
LS -> Auth: login(email, password)
Auth -> API: POST /api/auth/login
API -> BE: HTTP request
BE -> BE: bcrypt.compare + generate JWT
BE --> API: { success, data: { token, user } }
API --> Auth: token
Auth -> TS: saveToken(token)
Auth -> Sock: connect(token)
Sock -> BE: socket handshake (auth.token + ?token=)
BE -> SH: verify JWT, join room user:<id>
SH --> Sock: connected
Sock --> Auth: connected
Auth --> LS: success
LS -> U: Chuyển MainShell (HomeScreen)

@enduml
```

### 6.2 Trình tự — Cảnh báo SOS từ thiết bị đến app

```plantuml
@startuml seq-sos
title Sơ đồ trình tự — Cảnh báo SOS realtime

actor "Người cao tuổi" as E
participant "Simulator" as Sim
participant "Backend" as BE
participant "SosService" as SosSvc
participant "SocketHandler" as SH
participant "SocketIoService\n(Flutter)" as Sock
participant "DeviceEventService" as DES
participant "DeviceEventMapper" as Map
participant "AppState" as AS
participant "NotificationService" as Notif
participant "UI (AnimatedBuilder)" as UI

E -> Sim: Nhấn nút SOS
Sim -> BE: POST /api/sos { deviceId, type, lat, lng, ts }
BE -> SosSvc: createAlert(payload)
SosSvc -> BE: Lưu SosAlert + tạo Alert (userId denormalize)
SosSvc -> SH: emit sos:alert room user:<id>
SH -> Sock: socket event sos:alert
Sock -> DES: onSosAlert(payload)
DES -> Map: mapSos(payload)
Map -> Map: resolveBaseUrl (10.0.2.2 nếu emulator)
Map --> DES: ElderlyModel cập nhật
DES -> AS: updateAlert / updateElderly
AS -> UI: notifyListeners()
UI -> UI: Vẽ lại banner + card người thân
DES -> Notif: showSosNotification()
Notif --> E: (thông báo tới người chăm sóc)
SH -> Sim: socket ack (giao thành công)

@enduml
```

### 6.3 Trình tự — Quản lý người thân (thêm)

```plantuml
@startuml seq-relative
title Sơ đồ trình tự — Thêm người thân

actor "Người chăm sóc" as U
participant "RelativesScreen" as RS
participant "RelativesApiService" as RAS
participant "ApiClient" as API
participant "Backend" as BE
participant "AppState" as AS

U -> RS: Bấm Thêm người thân
RS -> RS: Mở AddRelativeDialog
U -> RS: Nhập thông tin + bấm Lưu
RS -> RAS: createRelative(data)
RAS -> API: POST /api/relatives (JWT)
API -> BE: HTTP request
BE -> BE: Validate Joi + kiểm unique deviceElderlyId
BE -> BE: Lưu bảng relatives
BE --> API: { success, data: relative }
API --> RAS: relative
RAS -> AS: addRelative(relative)
AS --> RS: notifyListeners()
RS -> U: Hiển thị người thân mới trong danh sách

@enduml
```

### 6.4 Trình tự — Xem lịch sử sự cố

```plantuml
@startuml seq-history
title Sơ đồ trình tự — Xem lịch sử sự cố

actor "Người chăm sóc" as U
participant "AlertsScreen" as AS
participant "AlertsApiService" as AAS
participant "ApiClient" as API
participant "Backend" as BE

U -> AS: Vào tab cảnh báo
AS -> AAS: fetchHistory(filters)
AAS -> API: GET /api/history?... (JWT)
API -> BE: HTTP request
BE -> BE: Truy vấn alerts theo userId + filter
BE --> API: { success, data: [alerts] }
API --> AAS: alerts
AAS --> AS: danh sách cảnh báo
AS -> U: Hiển thị + bộ lọc
U -> AS: Chọn một cảnh báo
AS -> AAS: fetchDetail(id)
AAS -> API: GET /api/history/:id
API -> BE: HTTP request
BE --> API: chi tiết
API --> AAS: chi tiết
AAS --> AS: chi tiết
AS -> U: Hiển thị AlertDetailScreen

@enduml
```

---

## 7. Sơ đồ Lớp

> Sơ đồ lớp tập trung vào lớp nghiệp vụ chính của ứng dụng Flutter và backend (chỉ lớp chính, không liệt kê toàn bộ getter/setter).

```plantuml
@startuml class-diagram
skinparam classAttributeIconSize 0
skinparam packageStyle frame
skinparam classBackgroundColor #F4FBFF

package "Ứng dụng Flutter" {

  class UserProfile {
    +int id
    +String email
    +String name
    +String phone
    +String avatarUrl
    +String role
    +fromJson(Map)
    +toJson(): Map
  }

  class ElderlyModel {
    +int id
    +String name
    +String avatar
    +int battery
    +DateTime lastUpdated
    +String status
    +double latitude
    +double longitude
    +int heartRate
    +int spo2
    +bool isOffline
    +String wearableDevice
    +bool isFallen
    +double safeZoneRadius
    +double safeZoneLat
    +double safeZoneLng
    +List<String> emergencyContacts
    +String address
    +int age
    +String avatarLocalPath
    +copyWith(...): ElderlyModel
  }

  class AlertModel {
    +int id
    +String type
    +String urgency
    +String message
    +double latitude
    +double longitude
    +String locationName
    +DateTime timestamp
    +bool acknowledged
    +bool read
    +fromJson(Map)
  }

  class EmergencyContactModel {
    +int id
    +int relativeId
    +String name
    +String phone
    +String relationship
  }

  class AddressModel {
    +String formatted
    +double latitude
    +double longitude
  }

  class AppSettings {
    +bool isDarkMode
    +String locale
    +bool notificationsEnabled
    +double safeZoneRadius
  }

  abstract class BaseService {
    +ApiClient client
  }

  class ApiClient {
    -String baseUrl
    -String token
    +get(path): Future<dynamic>
    +post(path, body): Future<dynamic>
    -unwrapEnvelope(json): dynamic
    +handle401(): void
  }

  class AuthService {
    +register(email, pwd): Future<UserProfile>
    +login(email, pwd): Future<String>
    +logout(): Future<void>
  }

  class TokenStorage {
    +saveToken(String)
    +getToken(): String?
    +clear()
  }

  class RelativesApiService {
    +list(): Future<List<ElderlyModel>>
    +create(data): Future<ElderlyModel>
    +update(id, data): Future<ElderlyModel>
    +delete(id): Future<void>
  }

  class AlertsApiService {
    +fetchHistory(filters): Future<List<AlertModel>>
    +fetchDetail(id): Future<AlertModel>
  }

  class DeviceEventService {
    +start()
    +stop()
    +onSosAlert(cb)
    +onFallEvent(cb)
  }

  class DeviceEventMapper {
    +mapSos(payload): ElderlyModel
    +mapEvent(payload): ElderlyModel
    +resolveBaseUrl(url): String
  }

  class SocketIoService {
    -IO.Socket socket
    +connect(token)
    +disconnect()
    +on(event, cb)
  }

  class NotificationService {
    +init()
    +showSosNotification(payload)
    +showFallNotification(payload)
  }

  class AppState {
    -List<ElderlyModel> relatives
    -List<AlertModel> alerts
    -AppSettings settings
    +notifyListeners()
    +addRelative(e)
    +updateAlert(a)
  }
}

package "Backend Node.js" {

  class UserController {
    +register(req, res)
    +login(req, res)
  }
  class RelativeController {
    +list(req, res)
    +create(req, res)
    +update(req, res)
    +remove(req, res)
  }
  class SosController {
    +createSos(req, res)
  }
  class HistoryController {
    +getHistory(req, res)
    +getDetail(req, res)
  }

  class AuthServiceBE {
    +hashPassword(pwd)
    +comparePassword(pwd, hash)
    +signJwt(user)
    +verifyJwt(token)
  }

  class SosServiceBE {
    +ingestSos(payload)
    +createAlert(...)
  }
  class SocketServiceBE {
    +emitSosAlert(userId, payload)
    +emitEvent(...)
  }
}

' --- Quan hệ ---
ApiClient <-- BaseService
AuthService --> ApiClient
AuthService --> TokenStorage
RelativesApiService --|> BaseService
AlertsApiService --|> BaseService
DeviceEventService --> SocketIoService
DeviceEventService --> DeviceEventMapper
DeviceEventService --> AppState
SocketIoService --> AppState
AppState o-- ElderlyModel
AppState o-- AlertModel
AppState o-- AppSettings
ElderlyModel o-- EmergencyContactModel

UserController --> AuthServiceBE
SosController --> SosServiceBE
SosServiceBE --> SocketServiceBE
HistoryController --> RelativeController

@enduml
```

---

## 8. Sơ đồ ERD

> Sơ đồ quan hệ thực thể (Entity-Relationship) phản ánh cơ sở dữ liệu MySQL/Sequelize của backend. Ký hiệu: `PK` khóa chính, `FK` khóa ngoài, `UQ` duy nhất, `NN` không null.

```plantuml
@startuml erd
hide methods
skinparam linetype ortho
skinparam classBackgroundColor #F4FBFF

entity "users" as users {
  * id : INT  (PK)
  --
   email : VARCHAR(255)  (UQ, NN)
   password_hash : VARCHAR(255)  (NN)
   role : ENUM(admin, caregiver)  (NN)
   name : VARCHAR(100)
   phone : VARCHAR(20)
   avatar_url : VARCHAR(255)
   created_at / updated_at / deleted_at : DATETIME
}

entity "relatives" as relatives {
  * id : INT  (PK)
  --
   user_id : INT  (FK, NN)
   name : VARCHAR(255)  (NN)
   avatar : VARCHAR(255)
   age : INT
   address : VARCHAR(255)
   wearable_device : VARCHAR(100)
   device_elderly_id : VARCHAR(100)  (UQ)
   safe_zone_radius : DECIMAL(8,2)
   safe_zone_lat : DECIMAL(10,8)
   safe_zone_lng : DECIMAL(11,8)
   created_at / updated_at / deleted_at : DATETIME
}

entity "devices" as devices {
  * id : UUID  (PK)
  --
   elderly_id : VARCHAR(100)  (NN)
   elderly_name : VARCHAR(255)
   serial_number : VARCHAR(100)  (UQ)
   status : ENUM(active, inactive, lost)  (NN)
   last_seen_at : DATETIME
   user_id : INT  (FK)
   relative_id : INT  (FK)
   created_at / updated_at / deleted_at : DATETIME
}

entity "sos_alerts" as sos_alerts {
  * id : UUID  (PK)
  --
   device_id : UUID  (FK, NN)
   type : VARCHAR(20)  (NN)
   latitude : DECIMAL(10,8)  (NN)
   longitude : DECIMAL(11,8)  (NN)
   timestamp : DATETIME  (NN)
   status : ENUM(pending, resolved, false_alarm)  (NN)
   payload_json : JSON
   created_at / updated_at : DATETIME
}

entity "events" as events {
  * id : UUID  (PK)
  --
   device_id : UUID  (FK, NN)
   type : ENUM(FALL_DETECTED, HEART_RATE_ALERT, SPO2_ALERT)  (NN)
   latitude : DECIMAL(10,8)  (NN)
   longitude : DECIMAL(11,8)  (NN)
   timestamp : DATETIME  (NN)
   payload_json : JSON
   created_at / updated_at : DATETIME
}

entity "locations" as locations {
  * id : UUID  (PK)
  --
   device_id : UUID  (FK, NN)
   latitude : DECIMAL(10,8)  (NN)
   longitude : DECIMAL(11,8)  (NN)
   timestamp : DATETIME  (NN)
   created_at / updated_at : DATETIME
}

entity "device_statuses" as device_statuses {
  * id : UUID  (PK)
  --
   device_id : UUID  (FK, NN)
   battery_percent : TINYINT  (NN)
   heart_rate_bpm : SMALLINT
   spo2_percent : TINYINT
   is_online : BOOLEAN  (NN)
   timestamp : DATETIME  (NN)
   created_at / updated_at : DATETIME
}

entity "emergency_contacts" as emergency_contacts {
  * id : INT  (PK)
  --
   relative_id : INT  (FK, NN)
   name : VARCHAR(100)  (NN)
   phone : VARCHAR(20)  (NN)
   relationship : VARCHAR(50)
   created_at / updated_at : DATETIME
}

entity "alerts" as alerts {
  * id : INT  (PK)
  --
   relative_id : INT  (FK)
   user_id : INT  (FK)
   type : ENUM(sos, fall, geofence, vital, manual)  (NN)
   urgency : ENUM(critical, warning)  (NN)
   message : TEXT  (NN)
   location_name : VARCHAR(255)
   latitude : DECIMAL(10,8)
   longitude : DECIMAL(11,8)
   timestamp : DATETIME  (NN)
   acknowledged : BOOLEAN  (NN)
   read : BOOLEAN  (NN)
   source_type : VARCHAR(20)
   source_id : VARCHAR(64)
   created_at / updated_at : DATETIME
}

' --- Quan hệ ---
users ||--o{ relatives : "sở hữu (1-n)"
users ||--o{ devices : "quản lý (1-n)"
users ||--o{ alerts : "phục vụ truy vấn (1-n)"
relatives ||--o{ emergency_contacts : "có (1-n) xóa cascade"
relatives ||--o{ devices : "ghép thiết bị (1-n)"
relatives ||--o{ alerts : "liên quan (1-n)"
devices ||--o{ sos_alerts : "gửi (1-n)"
devices ||--o{ events : "gửi (1-n)"
devices ||--o{ locations : "báo cáo (1-n)"
devices ||--o{ device_statuses : "snapshot (1-n)"

@enduml
```

**Mô tả quan hệ:**
- `users` 1—n `relatives`: một tài khoản chăm sóc quản lý nhiều người cao tuổi.
- `users` 1—n `devices`: một user quản lý nhiều thiết bị (trường `user_id` trên `devices`).
- `relatives` 1—n `devices`: người thân ghép với thiết bị qua `relative_id` / `device_elderly_id`.
- `relatives` 1—n `emergency_contacts`: liên hệ khẩn cấp, xóa cascade theo người thân.
- `devices` 1—n `sos_alerts | events | locations | device_statuses`: mỗi thiết bị sinh nhiều dòng telemetries.
- `alerts` là bảng cảnh báo cấp người dùng, `user_id`/`relative_id` được denormalize để truy vấn nhanh theo user; `source_type`/`source_id` truy vết dòng telemetries gốc.

---

## 9. Sơ đồ Trạng thái

### 9.1 Trạng thái cảnh báo (Alert)

```plantuml
@startuml state-alert
title Sơ đồ trạng thái — Cảnh báo (Alert)

state "Chưa đọc" as ChuaDoc
state "Đã đọc" as DaDoc
state "Đã xác nhận" as DaXacNhan
state "Đã giải quyết" as DaGiaiQuyet
state "Báo sai" as BaoSai

[*] --> ChuaDoc : thiết bị gửi SOS/event\nhoặc geofence breach
ChuaDoc --> DaDoc : người dùng mở chi tiết
DaDoc --> DaXacNhan : bấm Xác nhận
DaXacNhan --> DaGiaiQuyet : bấm Giải quyết
ChuaDoc --> BaoSai : bấm Báo sai
DaGiaiQuyet --> [*]
BaoSai --> [*]

note right of ChuaDoc
  status: pending -> resolved / false_alarm
  flags riêng: acknowledged, read
end note

@enduml
```

### 9.2 Trạng thái thiết bị (Device)

```plantuml
@startuml state-device
title Sơ đồ trạng thái — Thiết bị đeo (Device)

state "Hoạt động" as HoatDong {
  state "Online" as Online
  state "Offline" as Offline
  [*] --> Online
  Online --> Offline : mất tín hiệu / hết pin
  Offline --> Online : có dữ liệu mới
}
state "Mất kết nối" as MatKetNoi
state "Tạm ngưng" as TamNgung

[*] --> HoatDong : ghép với người thân
HoatDong --> MatKetNoi : không thấy last_seen quá ngưỡng
MatKetNoi --> HoatDong : phát hiện lại dữ liệu
MatKetNoi --> TamNgung : quản trị viên vô hiệu hóa
TamNgung --> HoatDong : kích hoạt lại
HoatDong --> [*] : xóa người thân (cascade)
MatKetNoi --> [*] : xóa thiết bị

note left of HoatDong
  status: active / inactive / lost
end note

@enduml
```

### 9.3 Trạng thái kết nối Socket.IO (app)

```plantuml
@startuml state-socket
title Sơ đồ trạng thái — Kết nối Socket.IO (ứng dụng)

state "Ngắt" as Ngat
state "Đang kết nối" as DangKetNoi
state "Đã kết nối" as DaKetNoi

[*] --> Ngat : app khởi động, chưa login
Ngat --> DangKetNoi : login thành công (forceNew)
DangKetNoi --> DaKetNoi : handshake JWT + join room user:<id>
DaKetNoi --> DangKetNoi : lỗi mạng (tự reconnect, delay 1s, max 60)
DaKetNoi --> Ngat : logout
DangKetNoi --> Ngat : hết lượt reconnect
DaKetNoi --> DaKetNoi : nhận event realtime (cập nhật AppState)

note right of DaKetNoi
  JWT gửi qua auth + ?token=
  forceNew đảm bảo re-auth thật
end note

@enduml
```

---

## 10. Sơ đồ Thành phần

> Sơ đồ thành phần thể hiện cấu trúc triển khai ba hệ thống con và các kết nối (REST, Socket.IO, DB).

```plantuml
@startuml component
skinparam componentStyle rectangle
skinparam nodesep 60
skinparam ranksep 60

title Sơ đồ thành phần — Hệ thống SOS Care

package "Ứng dụng chăm sóc (Flutter)" as App {
  component [Màn hình\n(18 screens)] as UI
  component [Widgets (~35)] as Widgets
  component [AppState\n(ChangeNotifier)] as AppState
  component [Services\n(Auth/Relatives/Alerts/...)] as Services
  component [ApiClient (HTTP)] as ApiClient
  component [SocketIoService] as SockApp
  component [DeviceEventService + Mapper] as DES
  component [NotificationService] as NotifApp
  component [TokenStorage] as TokenStorage
  component [Localizations / Theme] as L10n
}

package "Backend (Node.js + Express)" as BE {
  component [Express Routes\n(auth/sos/events/...)] as Routes
  component [Controllers] as Controllers
  component [Services + Socket emit] as SvcBE
  component [Repositories (Sequelize)] as Repos
  component [Middleware\n(JWT/Joi/Error)] as MW
  component [SocketHandler\n(join room, emit)] as SocketBE
  component [MySQL Database] as DB
}

package "Trình giả lập thiết bị (Flutter)" as Sim {
  component [Presentation\n(Riverpod)] as Pres
  component [Application Services] as AppSvc
  component [Data (Dio + Repository)] as DataSim
  component [Domain Entities] as Domain
}

actor "Người chăm sóc" as Caregiver
actor "Người cao tuổi" as Elderly

' --- Kết nối nội bộ app ---
UI --> Widgets
UI --> AppState
UI --> Services
Services --> ApiClient
Services --> AppState
DES --> SockApp
DES --> AppState
AppState --> NotifApp

' --- Kết nối backend ---
Routes --> Controllers
Controllers --> SvcBE
SvcBE --> Repos
Repos --> DB
Routes --> MW
SvcBE --> SocketBE
SocketBE --> DB

' --- Kết nối giữa hệ thống ---
Caregiver --> UI
Elderly --> Pres

ApiClient ..> Routes : REST /api/* (JWT)
SockApp ..> SocketBE : Socket.IO (websocket)
Pres --> DataSim
DataSim ..> Routes : REST /api/sos|events|location|device
DataSim ..> SocketBE : Socket.IO ack
Domain --> DataSim

@enduml
```

---

## Phụ lục — Danh mục sơ đồ

| # | Sơ đồ | Mục đích | Phần |
|---|-------|---------|------|
| 1 | Use Case Diagram | Tập hợp tác nhân & chức năng | §3 |
| 2 | Đặc tả Use Case | Mô tả chi tiết 6 use case chính | §4 |
| 3 | Activity Diagram (3) | Đăng nhập, xử lý cảnh báo, quản lý người thân | §5 |
| 4 | Sequence Diagram (4) | Login, SOS realtime, thêm người thân, lịch sử | §6 |
| 5 | Class Diagram | Cấu trúc lớp Flutter + backend | §7 |
| 6 | ERD | Cơ sở dữ liệu MySQL (9 thực thể) | §8 |
| 7 | State Diagram (3) | Alert, Device, Socket.IO | §9 |
| 8 | Component Diagram | Kiến trúc triển khai 3 hệ thống | §10 |

> **Cách render:** Dán từng khối `@startuml ... @enduml` vào PlantUML Web Server (plantuml.com) hoặc dùng extension PlantUML / VS Code PlantUML. Có thể xuất PNG/SVG.

---

## Câu hỏi còn mở (Unresolved Questions)

- **Q1:** Trong sơ đồ Use Case, hành động "Nghe xung quanh" / "Bật chuông thiết bị" từ xa hiện gửi qua kênh nào — REST riêng hay Socket.IO event tới thiết bị? Cần xác nhận để vẽ chính xác trình tự.
- **Q2:** `alerts.status` (pending/resolved/false_alarm) và cờ `acknowledged`/`read` có quan hệ chuyển trạng thái trùng lặp không — nên hợp nhất hay giữ tách biệt? Cần xác nhận ngữ nghĩa nghiệp vụ.
- **Q3:** Vùng an toàn (geofence) được tính phía backend (geofence service) hay phía app? README nhắc `geofence service` ở backend, nhưng app cũng có slider vùng an toàn — cần xác nhận nơi tính breach.