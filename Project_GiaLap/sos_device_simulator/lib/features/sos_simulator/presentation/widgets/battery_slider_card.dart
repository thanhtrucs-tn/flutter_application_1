import 'package:flutter/material.dart';

/// Slider card for adjusting the simulated battery level.
class BatterySliderCard extends StatelessWidget {
  final int batteryPercent;
  final ValueChanged<double> onChanged;

  const BatterySliderCard({
    super.key,
    required this.batteryPercent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _batteryIcon(batteryPercent),
                  color: _batteryColor(batteryPercent),
                ),
                const SizedBox(width: 8),
                Text(
                  'Pin: $batteryPercent%',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            Slider(
              value: batteryPercent.toDouble(),
              min: 0,
              max: 100,
              divisions: 100,
              label: '$batteryPercent%',
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  IconData _batteryIcon(int percent) {
    if (percent <= 20) return Icons.battery_alert;
    if (percent <= 50) return Icons.battery_3_bar;
    return Icons.battery_full;
  }

  Color _batteryColor(int percent) {
    if (percent <= 20) return Colors.red;
    if (percent <= 50) return Colors.orange;
    return Colors.green;
  }
}
