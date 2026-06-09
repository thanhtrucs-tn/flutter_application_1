import 'package:flutter/material.dart';
import '../utils/app_state.dart';
import '../utils/localization.dart';
import '../widgets/sos_app_header.dart';
import '../widgets/status_banner.dart';
import '../widgets/elderly_list_card.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/add_relative_dialog.dart';
import 'detail_screen.dart';
import 'alert_detail_screen.dart';
import 'profile_screen.dart';

/// Màn hình chính tổng quan an toàn của SOS Care.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedElderlyId = 1;
  String? _pushedAlertId;

  @override
  Widget build(BuildContext context) {
    final state = AppState();

    return AnimatedBuilder(
      animation: state,
      builder: (context, child) {
        final relatives = state.relatives;
        final activeAlert = state.activeAlert;

        // TỰ ĐỘNG BẬT MÀN HÌNH BÁO ĐỘNG SOS NẾU CÓ ACTIVE ALERT
        // Lưu ý: _pushedAlertId được set NGAY TRƯỚC addPostFrameCallback để chặn
        // các lần build() liên tiếp đăng ký callback nhiều lần.
        if (activeAlert != null && _pushedAlertId != activeAlert.id) {
          _pushedAlertId = activeAlert.id;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!mounted) return;
            final navigator = Navigator.of(context);
            // Chỉ push khi Navigator còn root (không bị dispose giữa lúc user logout).
            if (!navigator.mounted) return;
            final modalRoute = ModalRoute.of(context);
            final isCurrentHome = modalRoute is PageRoute &&
                modalRoute.settings.name != null &&
                (modalRoute.settings.name == '/' || modalRoute.settings.name == '/home');
            if (!isCurrentHome) {
              state.acknowledgeAlert(activeAlert.id);
              _pushedAlertId = null;
              return;
            }
            // Tránh push chồng nếu route /alert-detail đã có trên stack
            // (ví dụ: user back xong, alert chưa kịp clear).
            final alreadyOnAlert = navigator.widget.initialRoute == '/alert-detail' ||
                ModalRoute.of(context)?.settings.name == '/alert-detail';
            if (alreadyOnAlert) {
              _pushedAlertId = null;
              return;
            }
            await navigator.push(
              MaterialPageRoute(
                settings: const RouteSettings(name: '/alert-detail'),
                builder: (_) => AlertDetailScreen(alert: activeAlert),
              ),
            );
            if (!mounted) return;
            _pushedAlertId = null;
            state.acknowledgeAlert(activeAlert.id);
          });
        }

        bool hasCritical = relatives.any((e) => e.status == 'critical' && !e.isOffline);
        bool hasWarning = relatives.any((e) => e.status == 'warning' && !e.isOffline);
        String overallStatus = hasCritical ? 'critical' : (hasWarning ? 'warning' : 'safe');

        return Scaffold(
          appBar: SosAppHeader(
            title: Localization.translate('appName'),
          ),
          floatingActionButton: FloatingActionButton(
            heroTag: 'add-relative-fab',
            backgroundColor: const Color(0xFFE53935),
            foregroundColor: Colors.white,
            onPressed: () => AddRelativeDialog.show(context),
            child: const Icon(Icons.person_add_alt_1),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _UserHeader(),
                const SizedBox(height: 18),
                StatusBanner(status: overallStatus),
                const SizedBox(height: 24),
                _buildSectionHeader(Localization.translate('relativeList').toUpperCase()),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: relatives.length,
                  itemBuilder: (context, index) {
                    final r = relatives[index];
                    return ElderlyListCard(
                      elderly: r,
                      isSelected: _selectedElderlyId == r.id,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailScreen(elderlyId: r.id),
                          ),
                        );
                      },
                      onLocateTap: () {
                        setState(() {
                          _selectedElderlyId = r.id;
                        });
                      },
                    );
                  },
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
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF64748B),
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// Widget hiển thị thông tin người dùng giám sát và trạng thái thiết bị của người cao tuổi ở đầu trang chủ.
class _UserHeader extends StatelessWidget {
  const _UserHeader();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = AppState();
    final profile = state.userProfile;
    final relatives = state.relatives;

    // Tính toán số lượng thiết bị của người cao tuổi đang online
    final onlineCount = relatives.where((r) => !r.isOffline).length;
    final totalCount = relatives.length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          },
          child: Row(
            children: [
              ProfileAvatar(
                avatarUrl: profile.avatarUrl,
                avatarLocalPath: profile.avatarLocalPath,
                radius: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chào, ${profile.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.role,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.sensors_rounded,
                        color: Color(0xFF0F766E),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '$onlineCount/$totalCount online',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF0F766E),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
