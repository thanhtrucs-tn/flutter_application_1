import 'package:flutter/material.dart';
import '../utils/app_state.dart';
import '../utils/localization.dart';
import '../widgets/sos_app_header.dart';
import '../widgets/status_banner.dart';
import '../widgets/elderly_list_card.dart';
import 'detail_screen.dart';
import 'alert_detail_screen.dart';

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
        if (activeAlert != null && _pushedAlertId != activeAlert.id) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!mounted) return;
            final modalRoute = ModalRoute.of(context);
            final isCurrentHome = modalRoute is PageRoute &&
                modalRoute.settings.name != null &&
                (modalRoute.settings.name == '/' || modalRoute.settings.name == '/home');
            if (!isCurrentHome) {
              _pushedAlertId = activeAlert.id;
              state.acknowledgeAlert(activeAlert.id);
              return;
            }
            _pushedAlertId = activeAlert.id;
            await Navigator.push(
              context,
              MaterialPageRoute(
                settings: const RouteSettings(name: '/alert-detail'),
                builder: (context) => AlertDetailScreen(alert: activeAlert),
              ),
            );
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
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: CircleAvatar(
                  radius: 18,
                  backgroundImage: const NetworkImage(
                    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100',
                  ),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StatusBanner(status: overallStatus),
                const SizedBox(height: 20),
                _buildSectionHeader('👥 ${Localization.translate('relativeList').toUpperCase()}'),
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
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFFE53935),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
