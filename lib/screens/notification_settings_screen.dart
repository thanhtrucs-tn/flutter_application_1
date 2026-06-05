import 'package:flutter/material.dart';
import '../utils/app_state.dart';
import '../utils/localization.dart';
import '../widgets/sos_app_header.dart';
import '../widgets/settings_section_card.dart';

/// Màn hình cài đặt thông báo chi tiết.
class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState();
    return AnimatedBuilder(
      animation: state,
      builder: (context, child) {
        final s = state.settings;
        return Scaffold(
          appBar: SosAppHeader(
            title: Localization.translate('notificationSettings'),
            showBackButton: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SettingsSectionCard(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.gpp_maybe, color: Colors.red),
                  title: Text(Localization.translate('sosAlerts')),
                  value: s.notifySos,
                  onChanged: (v) => state.updateSettings(s.copyWith(notifySos: v)),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.gpp_maybe, color: Colors.orange),
                  title: Text(Localization.translate('safeZoneAlerts')),
                  value: s.notifySafeZone,
                  onChanged: (v) => state.updateSettings(s.copyWith(notifySafeZone: v)),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.monitor_heart, color: Colors.teal),
                  title: Text(Localization.translate('healthReminders')),
                  value: s.notifyHealth,
                  onChanged: (v) => state.updateSettings(s.copyWith(notifyHealth: v)),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.system_update, color: Colors.blue),
                  title: Text(Localization.translate('firmwareUpdates')),
                  value: s.notifyFirmware,
                  onChanged: (v) => state.updateSettings(s.copyWith(notifyFirmware: v)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
