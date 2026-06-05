import 'package:flutter/material.dart';
import '../models/elderly_model.dart';
import '../utils/app_state.dart';
import '../utils/localization.dart';
import '../widgets/custom_map.dart';
import '../widgets/health_chart.dart';
import '../widgets/big_button.dart';
import 'ringing_device_screen.dart';
import 'ambient_listen_screen.dart';
import 'send_sms_screen.dart';
import 'remote_sos_screen.dart';
import 'test_scenario_screen.dart';

/// Màn hình chi tiết sức khỏe và thiết bị đeo của người cao tuổi
class DetailScreen extends StatefulWidget {
  final int elderlyId;

  const DetailScreen({
    super.key,
    required this.elderlyId,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  /// Mở màn hình rung chuông thiết bị đeo
  void _openRingingDevice(ElderlyModel elderly) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RingingDeviceScreen(elderly: elderly),
      ),
    );
  }

  /// Mở màn hình nghe âm thanh xung quanh
  void _openAmbientListen(ElderlyModel elderly) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AmbientListenScreen(elderly: elderly),
      ),
    );
  }

  /// Mở màn hình gửi SMS khẩn cấp
  void _openSendSms(ElderlyModel elderly) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SendSmsScreen(elderly: elderly),
      ),
    );
  }

  /// Mở màn hình báo động từ xa
  void _openRemoteSos(ElderlyModel elderly) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RemoteSosScreen(elderly: elderly),
      ),
    );
  }

  /// Mở màn hình chọn kịch bản kiểm thử
  void _openTestScenarios(ElderlyModel elderly) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TestScenarioScreen(elderly: elderly),
      ),
    );
  }

  /// Gọi điện thoại khẩn cấp (Mô phỏng gọi thoại trên desktop/simulators)
  void _makeCall(String phoneNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.phone, color: Colors.green),
            const SizedBox(width: 8),
            const Text('Cuộc gọi SOS Care'),
          ],
        ),
        content: Text(
            'Hệ thống đang kết nối cuộc gọi thoại khẩn cấp tới số:\n$phoneNumber'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Đăng ký lắng nghe sự thay đổi của AppState
    return AnimatedBuilder(
      animation: state,
      builder: (context, child) {
        // Tìm thông tin người cao tuổi cập nhật
        final elderly = state.relatives.firstWhere((e) => e.id == widget.elderlyId);
        
        // Màu trạng thái tương ứng
        Color statusColor = AppState().isWebSocketConnected 
            ? (elderly.status == 'safe' 
                ? Colors.green 
                : (elderly.status == 'warning' ? Colors.orange : Colors.red))
            : Colors.grey;

        return Scaffold(
          appBar: AppBar(
            title: Text(elderly.name),
            actions: [
              // Badge kết nối ESP32 Online/Offline
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: elderly.isOffline ? Colors.red.withOpacity(0.12) : Colors.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: elderly.isOffline ? Colors.red : Colors.green,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: elderly.isOffline ? Colors.red : Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      elderly.isOffline ? 'OFFLINE' : 'ONLINE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: elderly.isOffline ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Thẻ sinh hiệu sức khỏe chính
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundImage: NetworkImage(elderly.avatar),
                              backgroundColor: Colors.teal.shade100,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    elderly.name,
                                    style: theme.textTheme.titleLarge?.copyWith(fontSize: 22),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${Localization.translate('wearableDevice')}: ${elderly.wearableDevice}',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 12),
                        
                        // Các chỉ số Nhịp tim & SpO2 dạng lớn
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            // Nhịp tim
                            _buildHealthMetricCol(
                              context: context,
                              icon: Icons.favorite,
                              iconColor: Colors.red,
                              label: Localization.translate('heartRate'),
                              value: elderly.isOffline ? '--' : '${elderly.heartRate}',
                              unit: 'BPM',
                              alert: !elderly.isOffline && (elderly.heartRate > 100 || elderly.heartRate < 60),
                            ),
                            
                            // Vạch ngăn dọc
                            Container(width: 1.5, height: 60, color: Colors.grey.shade300),
                            
                            // SpO2
                            _buildHealthMetricCol(
                              context: context,
                              icon: Icons.opacity,
                              iconColor: Colors.blueAccent,
                              label: Localization.translate('spo2'),
                              value: elderly.isOffline ? '--' : '${elderly.spo2}',
                              unit: '%',
                              alert: !elderly.isOffline && elderly.spo2 < 94,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Biểu đồ nhịp tim tâm đồ ECG động
                const Text(
                  '📊 MÔ PHỎNG BIỂU ĐỒ ĐIỆN TÂM ĐỒ (ECG)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                HealthChart(
                  bpm: elderly.heartRate,
                  isOffline: elderly.isOffline,
                  waveColor: statusColor,
                ),
                const SizedBox(height: 16),

                // 3. Bản đồ & thiết lập vùng an toàn
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '📍 BẢN ĐỒ ĐỊNH VỊ VÀ VÙNG AN TOÀN',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'R = ${elderly.safeZoneRadius.toStringAsFixed(0)}m',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                CustomMap(
                  lat: elderly.latitude,
                  lng: elderly.longitude,
                  safeZoneLat: elderly.safeZoneLat,
                  safeZoneLng: elderly.safeZoneLng,
                  safeZoneRadius: elderly.safeZoneRadius,
                  safetyStatus: elderly.status,
                  height: 240,
                  relativeName: elderly.name,
                ),
                const SizedBox(height: 8),
                
                // Thanh kéo điều chỉnh Vùng an toàn
                Row(
                  children: [
                    const Icon(Icons.gpp_maybe, color: Colors.teal),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Slider(
                        value: elderly.safeZoneRadius,
                        min: 100.0,
                        max: 800.0,
                        divisions: 7,
                        activeColor: Colors.teal,
                        inactiveColor: Colors.grey.shade300,
                        label: '${elderly.safeZoneRadius.toStringAsFixed(0)}m',
                        onChanged: (newValue) {
                          // Cập nhật bán kính an toàn trực tiếp
                          final updated = elderly.copyWith(
                            safeZoneRadius: newValue,
                            lastUpdated: DateTime.now(),
                          );
                          state.updateElderly(updated);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 4. Các nút thao tác nhanh
                const Text(
                  '⚡ THAO TÁC ĐIỀU KHIỂN NHANH',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                
                // Khối nút grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.2,
                  children: [
                    // Gọi điện
                    BigButton(
                      label: Localization.translate('callElderly'),
                      icon: Icons.phone,
                      color: Colors.green,
                      height: 60,
                      onPressed: () => _makeCall(elderly.emergencyContacts.first),
                    ),
                    // Rung chuông — mở màn hình riêng
                    BigButton(
                      label: Localization.translate('ringDevice'),
                      icon: Icons.notification_important,
                      color: Colors.orange.shade700,
                      height: 60,
                      onPressed: () => _openRingingDevice(elderly),
                    ),
                    // Nghe âm thanh — mở màn hình riêng
                    BigButton(
                      label: Localization.translate('listenAmbient'),
                      icon: Icons.mic,
                      color: Colors.teal,
                      height: 60,
                      onPressed: () => _openAmbientListen(elderly),
                    ),
                    // Gửi tin nhắn khẩn — mở màn hình riêng
                    BigButton(
                      label: Localization.translate('sendSOSMsg'),
                      icon: Icons.sms,
                      color: Colors.red,
                      height: 60,
                      onPressed: () => _openSendSms(elderly),
                    ),
                  ],
                ),

                // 5. NÚT BÁO ĐỘNG TỪ XA (SOS lớn) — mở màn hình riêng
                const SizedBox(height: 24),
                BigButton(
                  label: 'BÁO ĐỘNG TỪ XA',
                  icon: Icons.gpp_maybe,
                  color: Colors.red.shade700,
                  height: 80,
                  iconSize: 36,
                  fontSize: 20,
                  onPressed: () => _openRemoteSos(elderly),
                ),

                // 6. KỊCH BẢN KIỂM THỬ — mở màn hình riêng
                const SizedBox(height: 24),
                Material(
                  color: isDark
                      ? Colors.amber.withValues(alpha: 0.08)
                      : Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => _openTestScenarios(elderly),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.amber.shade700,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade700,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.science,
                                color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '🧪 KỊCH BẢN KIỂM THỬ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.amber.shade800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Té ngã • Ra ngoài • Nhịp tim bất thường',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios,
                              color: Colors.amber.shade800, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                // 7. Danh sách số điện thoại liên hệ khẩn cấp hiển thị bên dưới
                const Text(
                  '📞 DANH SÁCH LIÊN HỆ KHẨN CẤP',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                ...elderly.emergencyContacts.map((phone) {
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        child: Icon(Icons.contact_phone, size: 20),
                      ),
                      title: Text(phone, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: const Text('Người giám hộ khẩn cấp'),
                      trailing: IconButton(
                        icon: const Icon(Icons.phone_forwarded, color: Colors.green),
                        onPressed: () => _makeCall(phone),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Cột hiển thị 1 chỉ số sức khỏe (nhịp tim, SpO2)
  Widget _buildHealthMetricCol({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String unit,
    required bool alert,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: alert ? Colors.red : theme.textTheme.displayLarge?.color,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              unit,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        if (alert)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'BẤT THƯỜNG',
              style: TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }
}
