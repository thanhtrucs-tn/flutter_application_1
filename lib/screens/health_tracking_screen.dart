import 'package:flutter/material.dart';
import '../models/elderly_model.dart';
import '../utils/app_state.dart';
import '../utils/localization.dart';
import '../widgets/sos_app_header.dart';
import '../widgets/health_metrics_panel.dart';
import '../widgets/profile_header.dart';
import 'send_sms_screen.dart';
import 'remote_sos_screen.dart';

/// Màn hình theo dõi sức khỏe chuyên sâu.
class HealthTrackingScreen extends StatelessWidget {
  final int elderlyId;

  const HealthTrackingScreen({super.key, required this.elderlyId});

  void _makeCall(BuildContext context, String phone) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(children: [Icon(Icons.phone, color: Colors.green), SizedBox(width: 8), Text('Cuộc gọi SOS Care')]),
        content: Text('Hệ thống đang kết nối cuộc gọi thoại khẩn cấp tới số:\n$phone'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng'))],
      ),
    );
  }

  Color _statusColor(ElderlyModel e) {
    if (e.isOffline) return Colors.grey;
    if (e.status == 'safe') return Colors.green;
    if (e.status == 'warning') return Colors.orange;
    return Colors.red;
  }

  String _statusText(ElderlyModel e) {
    if (e.isOffline) return Localization.translate('statusOffline');
    if (e.status == 'safe') return Localization.translate('statusSafeText');
    if (e.status == 'warning') return Localization.translate('statusWarningText');
    return Localization.translate('statusCriticalText');
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState();
    return AnimatedBuilder(
      animation: state,
      builder: (context, child) {
        final elderly = state.relatives.firstWhere((e) => e.id == elderlyId);
        final color = _statusColor(elderly);

        return Scaffold(
          appBar: SosAppHeader(
            title: Localization.translate('healthTracking'),
            showBackButton: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProfileHeader(
                  avatarUrl: elderly.avatar,
                  avatarLocalPath: elderly.avatarLocalPath,
                  name: elderly.name,
                  statusColor: color,
                  statusText: _statusText(elderly),
                ),
                const SizedBox(height: 20),
                HealthMetricsPanel(elderly: elderly),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _makeCall(context, elderly.emergencyContacts.first),
                        icon: const Icon(Icons.phone),
                        label: Text(Localization.translate('callElderly')),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SendSmsScreen(elderly: elderly))),
                        icon: const Icon(Icons.sms),
                        label: Text(Localization.translate('sendSOSMsg')),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RemoteSosScreen(elderly: elderly))),
                        icon: const Icon(Icons.gpp_maybe),
                        label: const Text('SOS'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
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
}
