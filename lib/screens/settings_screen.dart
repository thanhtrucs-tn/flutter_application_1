import 'package:flutter/material.dart';
import '../utils/app_state.dart';
import '../utils/localization.dart';
import '../models/app_settings.dart';
import '../widgets/add_relative_dialog.dart';

/// Màn hình Cài đặt quản lý cấu hình và mô phỏng sự cố lập trình viên
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final state = AppState();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: state,
      builder: (context, child) {
        final settings = state.settings;

        return Scaffold(
          appBar: AppBar(
            title: Text(Localization.translate('settings')),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Khối Cấu hình Hệ thống (System Settings)
                _buildSectionHeader('🛠️ ' + Localization.translate('settings').toUpperCase()),
                Card(
                  child: Column(
                    children: [
                      // Chọn ngôn ngữ
                      ListTile(
                        leading: const Icon(Icons.language, color: Colors.teal),
                        title: Text(Localization.translate('language')),
                        subtitle: Text(settings.languageCode == 'vi' ? 'Tiếng Việt' : 'English'),
                        trailing: Switch(
                          value: settings.languageCode == 'en',
                          activeColor: Colors.teal,
                          onChanged: (val) {
                            state.toggleLanguage(val ? 'en' : 'vi');
                          },
                        ),
                      ),
                      const Divider(height: 1),
                      // Chế độ tối
                      ListTile(
                        leading: const Icon(Icons.dark_mode, color: Colors.indigo),
                        title: Text(Localization.translate('darkMode')),
                        subtitle: Text(settings.isDarkMode ? 'Đang bật' : 'Đang tắt'),
                        trailing: Switch(
                          value: settings.isDarkMode,
                          activeColor: Colors.teal,
                          onChanged: (val) {
                            state.toggleDarkMode(val);
                          },
                        ),
                      ),
                      const Divider(height: 1),
                      // Âm thanh cảnh báo
                      ListTile(
                        leading: const Icon(Icons.volume_up, color: Colors.pink),
                        title: Text(Localization.translate('soundAlert')),
                        trailing: Switch(
                          value: settings.isSoundAlertEnabled,
                          activeColor: Colors.teal,
                          onChanged: (val) {
                            state.updateSettings(settings.copyWith(isSoundAlertEnabled: val));
                          },
                        ),
                      ),
                      const Divider(height: 1),
                      // Tự động gọi điện
                      ListTile(
                        leading: const Icon(Icons.phone_forwarded, color: Colors.green),
                        title: Text(Localization.translate('autoCall')),
                        subtitle: Text('Gửi SOS sau ${settings.autoCallTimeoutSeconds}s'),
                        trailing: Switch(
                          value: settings.isAutoCallEnabled,
                          activeColor: Colors.teal,
                          onChanged: (val) {
                            state.updateSettings(settings.copyWith(isAutoCallEnabled: val));
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Khối Quản lý Người Thân & Thiết Bị (Relatives Management)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionHeader('👥 ' + Localization.translate('manageRelatives').toUpperCase()),
                    IconButton(
                      icon: const Icon(Icons.person_add_alt_1, color: Colors.teal),
                      tooltip: 'Thêm người thân',
                      onPressed: () => AddRelativeDialog.show(context),
                    ),
                  ],
                ),
                Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.relatives.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final r = state.relatives[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(r.avatar),
                        ),
                        title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${r.wearableDevice} • Batt: ${r.battery}%'),
                        trailing: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: r.isOffline ? Colors.grey : Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // 3. Khối Mô phỏng Cảnh báo - Developer Sandbox (Crucial for Demo)
                _buildSectionHeader('🧪 DEVELOPER SIMULATOR SANDBOX'),
                Text(
                  'Sử dụng các nút bên dưới để phát tin nhắn mô phỏng thiết bị đeo ESP32 truyền dữ liệu hoặc kích hoạt cảnh báo khẩn cấp ngay lập tức.',
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 8),
                Card(
                  color: Colors.amber.withOpacity(0.06),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Nút test té ngã
                        ElevatedButton.icon(
                          onPressed: () {
                            // Giả lập Té Ngã cho Nguyễn Thị A (id = 1)
                            state.simulateFall(1);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đang truyền tín hiệu té ngã (Fall) từ ESP32 của Bà Nguyễn Thị A...'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          icon: const Icon(Icons.personal_injury, color: Colors.white),
                          label: const Text('MÔ PHỎNG TÉ NGÃ (BÀ A)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Nút test đi ra khỏi Safe Zone
                        ElevatedButton.icon(
                          onPressed: () {
                            state.simulateExitSafeZone(2); // Ông B (id = 2)
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đang mô phỏng Ông Trần Văn B vượt ngoài ranh giới vùng an toàn...'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          icon: const Icon(Icons.directions_walk, color: Colors.white),
                          label: const Text('MÔ PHỎNG VƯỢT VÙNG AN TOÀN (ÔNG B)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Nút test nhịp tim bất thường
                        ElevatedButton.icon(
                          onPressed: () {
                            state.simulateHeartRateSpike(1);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đang truyền tín hiệu Nhịp tim 118 bpm, SpO2 91% từ ESP32...'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          icon: const Icon(Icons.heart_broken, color: Colors.white),
                          label: const Text('MÔ PHỎNG NHỊP TIM/SPO2 XẤU (BÀ A)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade800,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Nút ngắt kết nối ESP32 (Offline/Online)
                        OutlinedButton.icon(
                          onPressed: () {
                            // Cập nhật trạng thái online offline của Bà A
                            final elderly = state.relatives.firstWhere((e) => e.id == 1);
                            final updated = elderly.copyWith(
                              isOffline: !elderly.isOffline,
                              battery: elderly.isOffline ? 90 : 0,
                              heartRate: elderly.isOffline ? 75 : 0,
                              spo2: elderly.isOffline ? 98 : 0,
                            );
                            state.updateElderly(updated);
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Đã chuyển thiết bị đeo Bà A thành: ' + (updated.isOffline ? 'OFFLINE' : 'ONLINE')),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          icon: const Icon(Icons.wifi_off, color: Colors.teal),
                          label: const Text('ĐỔI ONLINE/OFFLINE THIẾT BỊ BÀ A'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.teal, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.teal,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
