-- ==========================================
-- SCRIPT KHỞI TẠO CƠ SỞ DỮ LIỆU MYSQL - SOS CARE
-- ==========================================
-- Hướng dẫn chạy:
-- 1. Mở phpMyAdmin hoặc công cụ MySQL Client (như Navicat, DBeaver, MySQL Workbench).
-- 2. Tạo một truy vấn SQL mới, dán toàn bộ mã dưới đây và thực thi (Run).
-- 3. Đảm bảo cấu hình trong db_helper.dart khớp với thông tin kết nối (host, port, user, db).

-- 1. Tạo database test_123
CREATE DATABASE IF NOT EXISTS test_123 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

USE test_123;

-- 2. Tạo bảng users (Tài khoản người thân giám sát)
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(32) NOT NULL UNIQUE,
    password VARCHAR(64) NOT NULL,
    name VARCHAR(100),
    email VARCHAR(48) UNIQUE,
    phone VARCHAR(10),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 3. Tạo bảng elderly (Thông tin sức khỏe & Vùng an toàn người cao tuổi)
CREATE TABLE IF NOT EXISTS elderly (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    avatar VARCHAR(255),
    battery INT DEFAULT 100,
    status VARCHAR(20) DEFAULT 'safe', -- 'safe', 'warning', 'critical'
    latitude DOUBLE DEFAULT 10.762622,
    longitude DOUBLE DEFAULT 106.660172,
    heart_rate INT DEFAULT 72,
    spo2 INT DEFAULT 98,
    is_offline TINYINT DEFAULT 0, -- 0: Online, 1: Offline
    wearable_device VARCHAR(100) DEFAULT 'ESP32 Smart Band V1',
    is_fallen TINYINT DEFAULT 0, -- 0: Bình thường, 1: Té ngã
    safe_zone_radius DOUBLE DEFAULT 300.0,
    safe_zone_lat DOUBLE DEFAULT 10.762622,
    safe_zone_lng DOUBLE DEFAULT 106.660172,
    emergency_contacts TEXT, -- Lưu dạng chuỗi JSON hoặc mảng số điện thoại
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 4. Tạo bảng alerts (Lịch sử sự cố SOS khẩn cấp)
CREATE TABLE IF NOT EXISTS alerts (
    id VARCHAR(50) PRIMARY KEY,
    elderly_id INT NOT NULL,
    elderly_name VARCHAR(100) NOT NULL,
    time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    location_name VARCHAR(255),
    urgency VARCHAR(20) DEFAULT 'critical', -- 'critical', 'warning'
    message VARCHAR(255) NOT NULL,
    acknowledged TINYINT DEFAULT 0, -- 0: Chưa xử lý, 1: Đã xác nhận xử lý
    latitude DOUBLE,
    longitude DOUBLE,
    FOREIGN KEY (elderly_id) REFERENCES elderly(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ==========================================
-- DỮ LIỆU BAN ĐẦU ĐỂ CHẠY THỬ (MOCK INSERTS)
-- ==========================================

-- Chèn tài khoản đăng nhập mẫu (Tên đăng nhập: admin / Mật khẩu: admin123)
-- Nếu đã có tài khoản, MySQL sẽ bỏ qua lệnh này do ràng buộc UNIQUE
INSERT IGNORE INTO users (username, password, name, email, phone)
VALUES ('admin', 'admin123', 'Quản trị viên', 'admin@soscare.local', '0901234567');

-- Chèn dữ liệu người cao tuổi mẫu
INSERT IGNORE INTO elderly (id, name, avatar, battery, status, latitude, longitude, heart_rate, spo2, is_offline, wearable_device, is_fallen, safe_zone_radius, safe_zone_lat, safe_zone_lng, emergency_contacts)
VALUES 
(1, 'Bà Nguyễn Thị A', 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150', 88, 'safe', 10.762622, 106.660172, 75, 98, 0, 'ESP32-Wristband-V1', 0, 200.0, 10.762622, 106.660172, '["0901234567", "0912345678"]'),
(2, 'Ông Trần Văn B', 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150', 45, 'warning', 10.765100, 106.662500, 110, 94, 0, 'ESP32-SmartRing-B3', 0, 400.0, 10.764000, 106.661000, '["0987654321"]'),
(3, 'Bà Lê Thị C', 'https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91?w=150', 0, 'safe', 10.760000, 106.658000, 0, 0, 1, 'ESP32-Band-X', 0, 300.0, 10.760000, 106.658000, '["0933445566", "0944556677"]');

-- Chèn một số lịch sử cảnh báo SOS mẫu
INSERT IGNORE INTO alerts (id, elderly_id, elderly_name, time, location_name, urgency, message, acknowledged, latitude, longitude)
VALUES
('alert_101', 1, 'Bà Nguyễn Thị A', NOW() - INTERVAL 1 DAY - INTERVAL 2 HOUR, '268 Lý Thường Kiệt, Q.10, TP.HCM', 'warning', 'Nhịp tim cao bất thường (115 bpm)', 1, 10.762622, 106.660172),
('alert_102', 2, 'Ông Trần Văn B', NOW() - INTERVAL 3 DAY, 'Công viên Lê Thị Riêng, Q.10, TP.HCM', 'critical', 'Phát hiện Té Ngã (Fall Detected)', 1, 10.764000, 106.661000),
('alert_103', 1, 'Bà Nguyễn Thị A', NOW() - INTERVAL 5 DAY, 'Ngoài Vùng An Toàn (Out of Safe Zone)', 'critical', 'Vượt ra ngoài khu vực an toàn (> 300m)', 1, 10.768000, 106.665000);

-- ==========================================
-- MIGRATION NOTE
-- ==========================================
-- Nếu bảng users đã được tạo từ phiên bản cũ (chỉ có id, username, password)
-- và ứng dụng báo lỗi Error 1054 (42S22): Unknown column 'name' in 'field list',
-- hãy chạy file db-migration-001-add-user-profile-columns.sql thay vì file này.
-- Câu lệnh ALTER TABLE trong file đó thêm các cột name/email/phone với NULL,
-- không làm mất dữ liệu cũ và giữ nguyên thứ tự cột như định nghĩa CREATE TABLE.
