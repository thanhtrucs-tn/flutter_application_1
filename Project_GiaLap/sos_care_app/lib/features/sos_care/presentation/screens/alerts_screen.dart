import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../widgets/alert_card.dart';

/// Screen that lists all realtime alerts received from the backend.
class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(careAlertsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử cảnh báo'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => ref.read(careAlertsNotifierProvider.notifier).clear(),
          ),
        ],
      ),
      body: alerts.isEmpty
          ? const Center(child: Text('Chưa có cảnh báo nào'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: alerts.length,
              itemBuilder: (context, index) {
                final alert = alerts[index];
                return AlertCard(
                  alert: alert,
                  onTap: () => ref
                      .read(careAlertsNotifierProvider.notifier)
                      .markAsRead(alert.id),
                );
              },
            ),
    );
  }
}
