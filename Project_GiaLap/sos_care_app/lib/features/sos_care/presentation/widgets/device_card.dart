import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/care_device.dart';

/// Card summarising a monitored device: online status, battery, heart
/// rate, and last known GPS coordinates.
class DeviceCard extends StatelessWidget {
  final CareDevice device;
  final VoidCallback onTap;

  const DeviceCard({super.key, required this.device, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        leading: Icon(
          device.isOnline ? Icons.wifi : Icons.wifi_off,
          color: device.isOnline ? Colors.green : Colors.red,
        ),
        title: Text(
          device.elderlyName ?? device.elderlyId,
          style: theme.textTheme.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (device.batteryPercent != null)
              Text('Pin: ${device.batteryPercent}%'),
            if (device.heartRateBpm != null)
              Text('Nhịp tim: ${device.heartRateBpm} BPM'),
            if (device.latestLocation != null)
              Text(
                'GPS: ${device.latestLocation!.latitude.toStringAsFixed(5)}, '
                '${device.latestLocation!.longitude.toStringAsFixed(5)}',
              ),
            if (device.lastSeenAt != null)
              Text(
                'Cập nhật: ${DateFormat('HH:mm:ss').format(device.lastSeenAt!)}',
                style: theme.textTheme.bodySmall,
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
