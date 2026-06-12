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
        title: const Row(children: [Icon(Icons.phone, color: Colors.green), SizedBox(width: 8), Expanded(child: Text('Cuộc gọi SOS Care', overflow: TextOverflow.ellipsis))]),
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
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          appBar: SosAppHeader(
            title: elderly.name,
            showBackButton: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProfileHeader(
                  avatarUrl: elderly.avatar,
                  name: elderly.name,
                  age: elderly.age != null
                      ? '${elderly.age} ${Localization.translate('age')}'
                      : null,
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
                const SizedBox(height: 20),
                
                // Thẻ xem lịch sử sức khỏe to rõ cho người lớn tuổi
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                  ),
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: const Icon(Icons.monitor_heart, color: Colors.teal, size: 28),
                    title: const Text(
                      'Lịch sử sức khỏe',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 28),
                    onTap: () => _openHealth(elderly),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Thẻ xem danh bạ khẩn cấp
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                  ),
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: const Icon(Icons.contact_phone, color: Colors.green, size: 28),
                    title: const Text(
                      'Danh bạ khẩn cấp',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 28),
                    onTap: () => _openContacts(elderly),
                  ),
                ),
                const SizedBox(height: 16),
                SafeZoneSlider(
                  value: elderly.safeZoneRadius,
                  onChanged: (v) {
                    state.updateElderly(elderly.copyWith(safeZoneRadius: v, lastUpdated: DateTime.now()));
                  },
                ),
                const SizedBox(height: 16),
                BigButton(
                  label: 'KỊCH BẢN KIỂM THỬ',
                  icon: Icons.science,
                  color: const Color(0xFF1A1400), // Nền tối giống TestScenarioScreen
                  height: 60,
                  iconSize: 26,
                  fontSize: 17,
                  onPressed: () => _openTestScenarios(elderly),
                ),
                const SizedBox(height: 12),
                BigButton(
                  label: 'BÁO ĐỘNG TỪ XA',
                  icon: Icons.gpp_maybe,
                  color: Colors.red.shade700,
                  height: 72,
                  iconSize: 32,
                  fontSize: 20,
                  onPressed: () => _openRemoteSos(elderly),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
