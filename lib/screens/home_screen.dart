import 'package:flutter/material.dart';
import '../utils/app_state.dart';
import '../utils/localization.dart';
import '../widgets/sos_app_header.dart';
import '../widgets/add_relative_dialog.dart';
import '../widgets/relative_reorderable_list.dart';
import 'detail_screen.dart';
import 'alert_detail_screen.dart';

/// Màn hình chính tổng quan an toàn của SOS Care.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _pushedAlertId;
  static const int _defaultSelectedElderlyId = 1;

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
              // Không tự động acknowledge khi user đang ở màn hình khác;
              // alert sẽ được đẩy khi user quay lại Home.
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

        // Tổng hợp trạng thái banner: xét CÃ elderly.status VÃ  alerts chưa acknowledge.
        // (Vì alert "Nhịp tim 115 bpm" có thể được trigger cho elderly đang offline
        // do simulator test, hoặc elderly đã acknowledge alert cũ nhưng vẫn ở critical.)
        bool hasCritical = relatives.any((e) => e.status == 'critical' && !e.isOffline) ||
            state.alerts.any((a) => !a.acknowledged && a.urgency == 'critical');
        bool hasWarning = relatives.any((e) => e.status == 'warning' && !e.isOffline) ||
            state.alerts.any((a) => !a.acknowledged && a.urgency == 'warning');
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
          body: RelativeReorderableList(
            relatives: relatives,
            overallStatus: overallStatus,
            selectedElderlyId: _defaultSelectedElderlyId,
            onTap: (id) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DetailScreen(elderlyId: id)),
              );
            },
          ),
        );
      },
    );
  }
}
