import 'package:flutter/material.dart';
import '../utils/app_state.dart';
import '../utils/localization.dart';
import '../widgets/sos_app_header.dart';
import '../widgets/settings_section_card.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/add_relative_dialog.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

/// Màn hình Cài đặt & Quản lý Tài khoản (Gộp từ 2 màn cũ)
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _logout(BuildContext context) {
    final navigator = Navigator.of(context);
    // Đảm bảo Navigator còn khả dụng và có route để pop.
    if (!navigator.mounted) return;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: state,
      builder: (context, child) {
        final settings = state.settings;
        final profile = state.userProfile;

        return Scaffold(
          appBar: SosAppHeader(title: Localization.translate('settings')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. PHẦN THÔNG TIN TÀI KHOẢN (Đưa từ AccountScreen sang)
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                  ),
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          ProfileAvatar(
                            avatarUrl: profile.avatarUrl,
                            avatarLocalPath: profile.avatarLocalPath,
                            radius: 32,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile.name,
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  profile.email,
                                  style: TextStyle(fontSize: 14, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE53935).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    profile.role,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFE53935),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. DANH SÁCH NGƯỜI THÂN ĐANG GIÁM SÁT
                SettingsSectionCard(
                  title: Localization.translate('manageRelatives'),
                  children: [
                    ...state.relatives.map((r) {
                      final statusColor = r.isOffline
                          ? Colors.grey
                          : (r.status == 'critical'
                              ? const Color(0xFFEF4444)
                              : (r.status == 'warning' ? const Color(0xFFF59E0B) : const Color(0xFF10B981)));

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(r.avatar),
                          radius: 20,
                        ),
                        title: Text(
                          r.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Text(
                          '${r.wearableDevice} • Pin ${r.battery}%',
                          style: const TextStyle(fontSize: 13),
                        ),
                        trailing: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    }),
                    if (state.relatives.isNotEmpty) const Divider(height: 1),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_add_alt_1, color: Color(0xFFE53935), size: 22),
                      ),
                      title: const Text(
                        'Thêm người thân',
                        style: TextStyle(
                          color: Color(0xFFE53935),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      trailing: const Icon(Icons.add, color: Color(0xFFE53935)),
                      onTap: () => AddRelativeDialog.show(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 3. CÀI ĐẶT HỆ THỐNG
                SettingsSectionCard(
                  title: Localization.translate('generalSettings'),
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person, color: Colors.blue),
                      title: Text(
                        Localization.translate('profile'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ProfileScreen()),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: Text(Localization.translate('language'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      trailing: Switch(
                        value: settings.languageCode == 'en',
                        onChanged: (v) => state.toggleLanguage(v ? 'en' : 'vi'),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: Text(Localization.translate('darkMode'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      trailing: Switch(
                        value: settings.isDarkMode,
                        onChanged: (v) => state.toggleDarkMode(v),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: Text(Localization.translate('soundAlert'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      trailing: Switch(
                        value: settings.isSoundAlertEnabled,
                        onChanged: (v) => state.updateSettings(settings.copyWith(isSoundAlertEnabled: v)),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: Text(Localization.translate('autoCall'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      subtitle: Text('${settings.autoCallTimeoutSeconds}s', style: const TextStyle(fontSize: 13)),
                      trailing: Switch(
                        value: settings.isAutoCallEnabled,
                        onChanged: (v) => state.updateSettings(settings.copyWith(isAutoCallEnabled: v)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 4. THÔNG TIN & ĐĂNG XUẤT
                SettingsSectionCard(
                  children: [
                    ListTile(
                      title: Text(Localization.translate('version'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      trailing: const Text('1.0.0', style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: Text(
                        Localization.translate('logout'),
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      onTap: () => _logout(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 5. CÔNG CỤ PHÁT TRIỂN / MÔ PHỎNG (Ẩn dưới menu mở rộng)
                ExpansionTile(
                  shape: const Border(),
                  title: const Text(
                    'Developer Tools',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  childrenPadding: const EdgeInsets.all(8),
                  children: [
                    _buildDevButton('MÔ PHỎNG TÉ NGÃ (BÀ A)', Icons.personal_injury, Colors.red, () => state.simulateFall(1)),
                    const SizedBox(height: 8),
                    _buildDevButton('MÔ PHỎNG VƯỢT VÙNG AN TOÀN (ÔNG B)', Icons.directions_walk, Colors.deepOrange, () => state.simulateExitSafeZone(2)),
                    const SizedBox(height: 8),
                    _buildDevButton('MÔ PHỎNG NHỊP TIM/SPO2 XẤU (BÀ A)', Icons.heart_broken, Colors.amber.shade800, () => state.simulateHeartRateSpike(1)),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        final elderly = state.relatives.firstWhere((e) => e.id == 1);
                        final updated = elderly.copyWith(
                          isOffline: !elderly.isOffline,
                          battery: elderly.isOffline ? 90 : 0,
                          heartRate: elderly.isOffline ? 75 : 0,
                          spo2: elderly.isOffline ? 98 : 0,
                        );
                        state.updateElderly(updated);
                      },
                      icon: const Icon(Icons.wifi_off, color: Colors.teal),
                      label: const Text('ĐỔI ONLINE/OFFLINE THIẾT BỊ BÀ A'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.teal, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDevButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white, size: 20),
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
