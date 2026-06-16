import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/device_status.dart';

/// Card that displays the simulated device's current status:
/// device ID, online/offline badge, battery, GPS coordinates, and last
/// updated timestamp.
class DeviceInfoCard extends StatelessWidget {
  final DeviceStatus status;

  const DeviceInfoCard({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(colorScheme),
            const Divider(height: 24),
            _buildInfoRow(
              icon: Icons.battery_full,
              label: 'Pin',
              value: '${status.batteryPercent}%',
              color: _batteryColor(status.batteryPercent, colorScheme),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              icon: Icons.favorite,
              label: 'Nhịp tim',
              value: '${status.heartRateBpm} BPM',
              color: _heartRateColor(status.heartRateBpm, colorScheme),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              icon: Icons.location_on,
              label: 'GPS',
              value:
                  '${status.latitude.toStringAsFixed(6)}, ${status.longitude.toStringAsFixed(6)}',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              icon: Icons.access_time,
              label: 'Cập nhật lúc',
              value: DateFormat('HH:mm:ss dd/MM/yyyy')
                  .format(status.lastUpdatedAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Row(
      children: [
        Icon(Icons.watch, color: colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            status.deviceId,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Chip(
          visualDensity: VisualDensity.compact,
          backgroundColor:
              status.isOnline ? Colors.green.shade100 : Colors.red.shade100,
          side: BorderSide.none,
          label: Text(
            status.isOnline ? 'Online' : 'Offline',
            style: TextStyle(
              color: status.isOnline ? Colors.green.shade900 : Colors.red.shade900,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
        Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Color _batteryColor(int percent, ColorScheme colorScheme) {
    if (percent <= 20) return Colors.red;
    if (percent <= 50) return Colors.orange;
    return colorScheme.primary;
  }

  Color _heartRateColor(int bpm, ColorScheme colorScheme) {
    if (bpm > 110) return Colors.red;
    return colorScheme.primary;
  }
}
