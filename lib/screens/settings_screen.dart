import 'package:flutter/material.dart';
import '../utils/app_state.dart';
import '../utils/localization.dart';
import '../widgets/sos_app_header.dart';
import '../widgets/settings_section_card.dart';
import 'login_screen.dart';
import 'notification_settings_screen.dart';
import 'account_screen.dart';

/// Màn hình cài đặt chung.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _logout(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState();
    return AnimatedBuilder(
      animation: state,
      builder: (context, child) {
        final settings = state.settings;
        return Scaffold(
          appBar: SosAppHeader(title: Localization.translate('settings')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SettingsSectionCard(
                  title: Localization.translate('account'),
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person, color: Colors.red),
                      title: Text(Localization.translate('updateInfo')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountScreen())),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.lock, color: Colors.red),
                      title: Text(Localization.translate('changePassword')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {},
                    ),
                  ],
                ),
                SettingsSectionCard(
                  title: Localization.translate('notificationSettings'),
                  children: [
                    ListTile(
                      leading: const Icon(Icons.notifications, color: Colors.red),
                      title: Text(Localization.translate('notificationSettings')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
                      ),
                    ),
                  ],
                ),
                SettingsSectionCard(
                  title: Localization.translate('generalSettings'),
                  children: [
                    ListTile(
                      leading: const Icon(Icons.language, color: Colors.teal),
                      title: Text(Localization.translate('language')),
                      trailing: Switch(
                        value: settings.languageCode == 'en',
                        onChanged: (v) => state.toggleLanguage(v ? 'en' : 'vi'),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.dark_mode, color: Colors.indigo),
                      title: Text(Localization.translate('darkMode')),
                      trailing: Switch(
                        value: settings.isDarkMode,
                        onChanged: (v) => state.toggleDarkMode(v),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.volume_up, color: Colors.pink),
                      title: Text(Localization.translate('soundAlert')),
                      trailing: Switch(
                        value: settings.isSoundAlertEnabled,
                        onChanged: (v) => state.updateSettings(settings.copyWith(isSoundAlertEnabled: v)),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.phone_forwarded, color: Colors.green),
                      title: Text(Localization.translate('autoCall')),
                      subtitle: Text('${settings.autoCallTimeoutSeconds}s'),
                      trailing: Switch(
                        value: settings.isAutoCallEnabled,
                        onChanged: (v) => state.updateSettings(settings.copyWith(isAutoCallEnabled: v)),
                      ),
                    ),
                  ],
                ),
                SettingsSectionCard(
                  title: Localization.translate('settings'),
                  children: [
                    ListTile(
                      leading: const Icon(Icons.info, color: Colors.blue),
                      title: Text(Localization.translate('version')),
                      trailing: const Text('1.0.0', style: TextStyle(color: Colors.grey)),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.article, color: Colors.blue),
                      title: Text(Localization.translate('termsOfService')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {},
                    ),
                  ],
                ),
                SettingsSectionCard(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: Text(
                        Localization.translate('logout'),
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                      onTap: () => _logout(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ExpansionTile(
                  title: const Text('🧪 Developer Tools', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  childrenPadding: const EdgeInsets.all(12),
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
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.teal, width: 1.5)),
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
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(backgroundColor: color),
    );
  }
}
