import 'package:flutter/material.dart';
import '../utils/app_state.dart';
import '../utils/localization.dart';
import '../widgets/sos_app_header.dart';
import '../widgets/settings_section_card.dart';
import 'login_screen.dart';

/// Màn hình tài khoản người dùng.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

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
        return Scaffold(
          appBar: SosAppHeader(title: Localization.translate('account')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 30,
                          backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200'),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Người Thân', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const Text('nguoithan@example.com', style: TextStyle(fontSize: 13, color: Colors.grey)),
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE53935).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Tài khoản giám sát',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFE53935)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SettingsSectionCard(
                  title: Localization.translate('account'),
                  children: [
                    ListTile(
                      leading: const Icon(Icons.lock, color: Colors.red),
                      title: Text(Localization.translate('changePassword')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {},
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.edit, color: Colors.red),
                      title: Text(Localization.translate('updateInfo')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {},
                    ),
                  ],
                ),
                SettingsSectionCard(
                  title: Localization.translate('manageRelatives'),
                  children: state.relatives.map((r) {
                    return ListTile(
                      leading: CircleAvatar(backgroundImage: NetworkImage(r.avatar), radius: 18),
                      title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${r.wearableDevice} • Pin ${r.battery}%'),
                      trailing: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: r.isOffline ? Colors.grey : Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SettingsSectionCard(
                  title: Localization.translate('settings'),
                  children: [
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: Text(Localization.translate('logout'), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      onTap: () => _logout(context),
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
}
