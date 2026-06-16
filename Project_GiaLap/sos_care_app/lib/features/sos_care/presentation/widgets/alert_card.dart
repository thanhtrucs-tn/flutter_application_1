import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/care_alert.dart';

/// Card that displays a realtime alert with type-specific color and icon.
class AlertCard extends StatelessWidget {
  final CareAlert alert;
  final VoidCallback onTap;

  const AlertCard({super.key, required this.alert, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: _backgroundColor().withValues(alpha: 0.08),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _backgroundColor(),
          child: Icon(_icon(), color: Colors.white),
        ),
        title: Text(
          _title(),
          style: theme.textTheme.titleSmall?.copyWith(
                color: _backgroundColor(),
                fontWeight: FontWeight.bold,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Thiết bị: ${alert.elderlyId}'),
            Text(
              '${alert.latitude.toStringAsFixed(5)}, ${alert.longitude.toStringAsFixed(5)}',
            ),
            Text(
              DateFormat('HH:mm:ss dd/MM/yyyy').format(alert.timestamp),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        trailing: alert.isRead
            ? const Icon(Icons.check_circle, color: Colors.grey)
            : const Icon(Icons.circle, color: Colors.red, size: 12),
        onTap: onTap,
      ),
    );
  }

  String _title() {
    return switch (alert.type) {
      'SOS' => 'Cảnh báo SOS',
      'FALL_DETECTED' => 'Phát hiện té ngã',
      'HEART_RATE_ALERT' => 'Nhịp tim bất thường',
      _ => alert.type,
    };
  }

  IconData _icon() {
    return switch (alert.type) {
      'SOS' => Icons.emergency,
      'FALL_DETECTED' => Icons.warning,
      'HEART_RATE_ALERT' => Icons.favorite,
      _ => Icons.notifications,
    };
  }

  Color _backgroundColor() {
    return switch (alert.type) {
      'SOS' => Colors.red,
      'FALL_DETECTED' => Colors.orange,
      'HEART_RATE_ALERT' => Colors.purple,
      _ => Colors.blue,
    };
  }
}
