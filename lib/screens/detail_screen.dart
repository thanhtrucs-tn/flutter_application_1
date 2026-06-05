import 'package:flutter/material.dart';
import '../models/elderly_model.dart';
import '../utils/app_state.dart';
import '../utils/localization.dart';
import '../widgets/sos_app_header.dart';
import '../widgets/profile_header.dart';
import '../widgets/action_button_grid.dart';
import '../widgets/health_metrics_panel.dart';
import '../widgets/safe_zone_slider.dart';
import '../widgets/custom_map.dart';
import '../widgets/big_button.dart';
import 'ringing_device_screen.dart';
import 'ambient_listen_screen.dart';
import 'send_sms_screen.dart';
import 'remote_sos_screen.dart';
import 'test_scenario_screen.dart';
import 'map_view_screen.dart';
import 'health_tracking_screen.dart';
import 'emergency_contacts_screen.dart';

/// Màn hình chi tiết người cao tuổi với thông tin, sức khỏe, bản đồ và thao tác.
class DetailScreen extends StatefulWidget {
  final int elderlyId;
  const DetailScreen({super.key, required this.elderlyId});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  void _openRingingDevice(ElderlyModel e) => _push(RingingDeviceScreen(elderly: e));
  void _openAmbientListen(ElderlyModel e) => _push(AmbientListenScreen(elderly: e));
  void _openSendSms(ElderlyModel e) => _push(SendSmsScreen(elderly: e));
  void _openRemoteSos(ElderlyModel e) => _push(RemoteSosScreen(elderly: e));
  void _openTestScenarios(ElderlyModel e) => _push(TestScenarioScreen(elderly: e));
  void _openMap(ElderlyModel e) => _push(MapViewScreen(elderly: e));
  void _openHealth(ElderlyModel e) => _push(HealthTrackingScreen(elderlyId: e.id));
  void _openContacts(ElderlyModel e) => _push(EmergencyContactsScreen(elderly: e));

  void _push(Widget screen) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  void _makeCall(String phone) {
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
        final elderly = state.relatives.firstWhere((e) => e.id == widget.elderlyId);
        final color = _statusColor(elderly);

        return Scaffold(
          appBar: SosAppHeader(
            title: elderly.name,
            showBackButton: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.monitor_heart),
                onPressed: () => _openHealth(elderly),
              ),
              IconButton(
                icon: const Icon(Icons.contact_phone),
                onPressed: () => _openContacts(elderly),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProfileHeader(
                  avatarUrl: elderly.avatar,
                  name: elderly.name,
                  age: '78 ${Localization.translate('age')}',
                  address: 'TP. Hồ Chí Minh',
                  statusColor: color,
                  statusText: _statusText(elderly),
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () => _openMap(elderly),
                  borderRadius: BorderRadius.circular(12),
                  child: CustomMap(
                    lat: elderly.latitude,
                    lng: elderly.longitude,
                    safeZoneLat: elderly.safeZoneLat,
                    safeZoneLng: elderly.safeZoneLng,
                    safeZoneRadius: elderly.safeZoneRadius,
                    safetyStatus: elderly.status,
                    height: 320,
                    relativeName: elderly.name,
                    address: elderly.address,
                  ),
                ),
                const SizedBox(height: 16),
                ActionButtonGrid(
                  onCall: () => _makeCall(elderly.emergencyContacts.first),
                  onRing: () => _openRingingDevice(elderly),
                  onListen: () => _openAmbientListen(elderly),
                  onSms: () => _openSendSms(elderly),
                  compact: true,
                ),
                const SizedBox(height: 20),
                HealthMetricsPanel(elderly: elderly),
                const SizedBox(height: 16),
                SafeZoneSlider(
                  value: elderly.safeZoneRadius,
                  onChanged: (v) {
                    state.updateElderly(elderly.copyWith(safeZoneRadius: v, lastUpdated: DateTime.now()));
                  },
                ),
                const SizedBox(height: 20),
                BigButton(
                  label: 'BÁO ĐỘNG TỪ XA',
                  icon: Icons.gpp_maybe,
                  color: Colors.red.shade700,
                  height: 70,
                  iconSize: 32,
                  fontSize: 18,
                  onPressed: () => _openRemoteSos(elderly),
                ),
                const SizedBox(height: 16),
                Material(
                  color: Colors.amber.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => _openTestScenarios(elderly),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade700, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.amber.shade700, shape: BoxShape.circle),
                            child: const Icon(Icons.science, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('🧪 KỊCH BẢN KIỂM THỬ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber.shade800)),
                                const SizedBox(height: 2),
                                Text('Té ngã • Ra ngoài • Nhịp tim bất thường', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios, color: Colors.amber.shade800, size: 16),
                        ],
                      ),
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
}
