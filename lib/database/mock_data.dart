import '../models/elderly_model.dart';
import '../models/alert_model.dart';

/// Dữ liệu giả lập ban đầu cho SOS Care
class MockData {
  /// Danh sách người cao tuổi ban đầu
  static List<ElderlyModel> initialElderly = [
    ElderlyModel(
      id: 1,
      name: 'Bà Nguyễn Thị A',
      avatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150', // Link ảnh đại diện mẫu
      battery: 88,
      lastUpdated: DateTime.now().subtract(const Duration(minutes: 2)),
      status: 'safe',
      latitude: 10.762622,
      longitude: 106.660172,
      heartRate: 75,
      spo2: 98,
      isOffline: false,
      wearableDevice: 'ESP32-Wristband-V1',
      isFallen: false,
      safeZoneRadius: 200.0, // 200m
      safeZoneLat: 10.762622,
      safeZoneLng: 106.660172,
      emergencyContacts: ['0901234567', '0912345678'],
    ),
    ElderlyModel(
      id: 2,
      name: 'Ông Trần Văn B',
      avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
      battery: 45,
      lastUpdated: DateTime.now().subtract(const Duration(minutes: 5)),
      status: 'warning',
      latitude: 10.765100,
      longitude: 106.662500,
      heartRate: 110, // Nhịp tim hơi cao -> warning
      spo2: 94, // SpO2 hơi thấp -> warning
      isOffline: false,
      wearableDevice: 'ESP32-SmartRing-B3',
      isFallen: false,
      safeZoneRadius: 400.0,
      safeZoneLat: 10.764000,
      safeZoneLng: 106.661000,
      emergencyContacts: ['0987654321'],
    ),
    ElderlyModel(
      id: 3,
      name: 'Bà Lê Thị C',
      avatar: 'https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91?w=150',
      battery: 0,
      lastUpdated: DateTime.now().subtract(const Duration(hours: 12)),
      status: 'safe',
      latitude: 10.760000,
      longitude: 106.658000,
      heartRate: 0,
      spo2: 0,
      isOffline: true, // ESP32 Mất kết nối
      wearableDevice: 'ESP32-Band-X',
      isFallen: false,
      safeZoneRadius: 300.0,
      safeZoneLat: 10.760000,
      safeZoneLng: 106.658000,
      emergencyContacts: ['0933445566', '0944556677'],
    ),
  ];

  /// Danh sách sự cố SOS lịch sử ban đầu
  static List<AlertModel> initialAlerts = [
    AlertModel(
      id: 'alert_101',
      elderlyId: 1,
      elderlyName: 'Bà Nguyễn Thị A',
      time: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      locationName: '268 Lý Thường Kiệt, Q.10, TP.HCM',
      urgency: 'warning',
      message: 'Nhịp tim cao bất thường (115 bpm)',
      acknowledged: true,
      latitude: 10.762622,
      longitude: 106.660172,
    ),
    AlertModel(
      id: 'alert_102',
      elderlyId: 2,
      elderlyName: 'Ông Trần Văn B',
      time: DateTime.now().subtract(const Duration(days: 3)),
      locationName: 'Công viên Lê Thị Riêng, Q.10, TP.HCM',
      urgency: 'critical',
      message: 'Phát hiện Té Ngã (Fall Detected)',
      acknowledged: true,
      latitude: 10.764000,
      longitude: 106.661000,
    ),
    AlertModel(
      id: 'alert_103',
      elderlyId: 1,
      elderlyName: 'Bà Nguyễn Thị A',
      time: DateTime.now().subtract(const Duration(days: 5)),
      locationName: 'Ngoài Vùng An Toàn (Out of Safe Zone)',
      urgency: 'critical',
      message: 'Vượt ra ngoài khu vực an toàn (> 300m)',
      acknowledged: true,
      latitude: 10.768000,
      longitude: 106.665000,
    ),
  ];
}
