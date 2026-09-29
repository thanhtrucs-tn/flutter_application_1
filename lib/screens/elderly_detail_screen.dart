import 'package:flutter/material.dart';
import '../models/elderly_model.dart';
import '../utils/app_state.dart';
import '../utils/localization.dart';
import '../widgets/sos_app_header.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/health_metrics_panel.dart';
import '../map/map_markers.dart';
import '../map/map_preview_card.dart';
import '../utils/theme.dart';
import '../widgets/big_button.dart';
import 'edit_relative_screen.dart';
import 'ringing_device_screen.dart';
import 'ambient_listen_screen.dart';
import 'send_sms_screen.dart';
import 'remote_sos_screen.dart';
import 'map_view_screen.dart';
import 'health_tracking_screen.dart';
import 'emergency_contacts_screen.dart';

/// Màn hình chi tiết người cao tuổi với thông tin, sức khỏe, bản đồ và thao tác.
class ElderlyDetailScreen extends StatefulWidget {
  final int elderlyId;
  const ElderlyDetailScreen({super.key, required this.elderlyId});

  @override
  State<ElderlyDetailScreen> createState() => _ElderlyDetailScreenState();
}

class _ElderlyDetailScreenState extends State<ElderlyDetailScreen> {
  void _openRingingDevice(ElderlyModel e) => _push(RingingDeviceScreen(elderly: e));
  void _openAmbientListen(ElderlyModel e) => _push(AmbientListenScreen(elderly: e));
  void _openSendSms(ElderlyModel e) => _push(SendSmsScreen(elderly: e));
  void _openRemoteSos(ElderlyModel e) => _push(RemoteSosScreen(elderly: e));
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
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          appBar: SosAppHeader(
            title: elderly.name,
            showBackButton: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: Localization.translate('editInfo'),
                onPressed: () => EditRelativeScreen.open(context, elderly.id),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Identity(
                  elderly: elderly,
                  statusText: _statusText(elderly),
                ),
                const SizedBox(height: 16),
                // Bản xem trước: không kéo được (tránh tranh cuộn với trang),
                // chạm để mở bản đồ đầy đủ.
                MapPreviewCard(
                  elderly: elderly,
                  onOpen: () => _openMap(elderly),
                ),
                const SizedBox(height: 16),
                _QuickActions(
                  onCall: () => _makeCall(elderly.emergencyContacts.first),
                  onListen: () => _openAmbientListen(elderly),
                  onRing: () => _openRingingDevice(elderly),
                  onSms: () => _openSendSms(elderly),
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

/// Dòng nhận diện gọn: avatar có vòng màu trạng thái, tên, tuổi · trạng thái.
class _Identity extends StatelessWidget {
  final ElderlyModel elderly;
  final String statusText;
  const _Identity({required this.elderly, required this.statusText});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = MapStatus.color(elderly);
    final muted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          child: ProfileAvatar(
            avatarUrl: elderly.avatar,
            avatarLocalPath: elderly.avatarLocalPath,
            radius: 25,
            backgroundColor: const Color(0xFFE6F2F0),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                elderly.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  if (elderly.age != null) ...[
                    Text(
                      '${elderly.age} ${Localization.translate('age').toLowerCase()}',
                      style: TextStyle(fontSize: 13, color: muted),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color.lerp(color, Colors.black, isDark ? 0 : 0.25),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 4 thao tác nhanh trên một hàng: biểu tượng trên, nhãn ngắn dưới.
class _QuickActions extends StatelessWidget {
  final VoidCallback onCall;
  final VoidCallback onListen;
  final VoidCallback onRing;
  final VoidCallback onSms;

  const _QuickActions({
    required this.onCall,
    required this.onListen,
    required this.onRing,
    required this.onSms,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.call_outlined, 'quickCall', onCall),
      (Icons.headphones_outlined, 'quickListen', onListen),
      (Icons.notifications_none_rounded, 'quickRing', onRing),
      (Icons.chat_bubble_outline_rounded, 'quickSms', onSms),
    ];
    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: _QuickButton(icon: items[i].$1, label: Localization.translate(items[i].$2), onTap: items[i].$3)),
        ],
      ],
    );
  }
}

class _QuickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 72,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: isDark ? AppTheme.secondaryTeal : AppTheme.primaryTeal),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: isDark ? Colors.white : const Color(0xFF1E293B)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
