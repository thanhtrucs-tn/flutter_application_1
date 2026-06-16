import 'package:flutter/material.dart';
import '../utils/app_state.dart';
import '../utils/localization.dart';
import '../widgets/sos_app_header.dart';
import '../widgets/filter_chip_bar.dart';
import '../widgets/alert_list_item.dart';
import 'alert_detail_screen.dart';
import 'add_alert_screen.dart';

/// Màn hình danh sách cảnh báo SOS đầy đủ có lọc.
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  String _filter = 'Tất cả';

  final List<String> _options = ['Tất cả', 'Khẩn cấp', 'Cảnh báo', 'Chưa xử lý'];

  @override
  Widget build(BuildContext context) {
    final state = AppState();
    return AnimatedBuilder(
      animation: state,
      builder: (context, child) {
        final sorted = state.sortedAlerts;
        final alerts = sorted.where((a) {
          if (_filter == 'Tất cả') return true;
          if (_filter == 'Khẩn cấp') return a.urgency == 'critical';
          if (_filter == 'Cảnh báo') return a.urgency == 'warning';
          if (_filter == 'Chưa xử lý') return !a.acknowledged;
          return true;
        }).toList();

        final topAlertId = sorted.isNotEmpty ? sorted.first.id : null;

        return Scaffold(
          appBar: SosAppHeader(title: Localization.translate('alerts')),
          body: alerts.isEmpty
              ? Center(
                  child: Text(
                    Localization.translate('noAlerts'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  children: [
                    FilterChipBar(
                      options: _options,
                      selected: _filter,
                      onSelected: (v) => setState(() => _filter = v),
                    ),
                    const SizedBox(height: 10),
                    ...alerts.map((a) => AlertListItem(
                      alert: a,
                      isLatest: a.id == topAlertId,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AlertDetailScreen(alert: a)),
                      ),
                    )),
                  ],
                ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: const Color(0xFFE53935),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddAlertScreen()),
              );
            },
            icon: const Icon(Icons.add_alert_rounded, color: Colors.white, size: 24),
            label: const Text(
              'Thêm Cảnh Báo',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
            ),
          ),
        );
      },
    );
  }
}
