import 'package:flutter/material.dart';
import '../utils/app_state.dart';
import '../utils/localization.dart';
import '../widgets/sos_app_header.dart';
import '../widgets/filter_chip_bar.dart';
import '../widgets/alert_list_item.dart';
import 'alert_detail_screen.dart';

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
        final alerts = state.alerts.where((a) {
          if (_filter == 'Tất cả') return true;
          if (_filter == 'Khẩn cấp') return a.urgency == 'critical';
          if (_filter == 'Cảnh báo') return a.urgency == 'warning';
          if (_filter == 'Chưa xử lý') return !a.acknowledged;
          return true;
        }).toList();

        return Scaffold(
          appBar: SosAppHeader(title: Localization.translate('alerts')),
          body: alerts.isEmpty
              ? const Center(child: Text('Không có cảnh báo nào.'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    FilterChipBar(
                      options: _options,
                      selected: _filter,
                      onSelected: (v) => setState(() => _filter = v),
                    ),
                    const SizedBox(height: 8),
                    ...alerts.map((a) => AlertListItem(
                      alert: a,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AlertDetailScreen(alert: a)),
                      ),
                    )),
                  ],
                ),
        );
      },
    );
  }
}
