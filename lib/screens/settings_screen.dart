import 'package:flutter/material.dart';
import '../utils/app_state.dart';
import '../utils/localization.dart';
import '../widgets/sos_app_header.dart';
import '../widgets/settings_section_card.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/manage_relatives_section.dart';
import '../widgets/developer_tools_section.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

/// Màn hình Cài đặt & Quản lý Tài khoản (Gộp từ 2 màn cũ)
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _logout(BuildContext context) async {
    final navigator = Navigator.of(context);
    await AppState().logout();
    // Đảm bảo Navigator còn khả dụng và có route để pop.
    if (!navigator.mounted) return;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  String _languageDisplayName(String code) {
    switch (code) {
      case 'en':
        return Localization.translate('english');
      case 'vi':
      default:
        return Localization.translate('vietnamese');
    }
  }

  Future<void> _showLanguagePicker(
    BuildContext context,
    AppState state,
    String currentCode,
  ) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(Localization.translate('selectLanguage')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption(context, 'vi', currentCode),
              _buildLanguageOption(context, 'en', currentCode),
            ],
          ),
        );
      },
    );

    if (selected != null && selected != currentCode) {
      await state.toggleLanguage(selected);
    }
  }

  Widget _buildLanguageOption(BuildContext context, String code, String currentCode) {
    final isSelected = code == currentCode;
    return ListTile(
      title: Text(_languageDisplayName(code)),
      trailing: isSelected ? const Icon(Icons.check, color: Color(0xFFE53935)) : null,
      onTap: () => Navigator.of(context).pop(code),
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
                                  child: const Text(
                                    'Quản trị viên',
                                    style: TextStyle(
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
                ManageRelativesSection(
                  relatives: state.relatives,
                  canDelete: true,
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
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _languageDisplayName(settings.languageCode),
                            style: const TextStyle(fontSize: 15, color: Colors.grey),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                      onTap: () => _showLanguagePicker(context, state, settings.languageCode),
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

                // 5. CÔNG CỤ PHÁT TRIỂN / MÔ PHỎNG
                DeveloperToolsSection(relatives: state.relatives),
              ],
            ),
          ),
        );
      },
    );
  }

}
