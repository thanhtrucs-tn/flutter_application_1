import 'package:flutter/material.dart';
import '../models/elderly_model.dart';
import '../utils/localization.dart';
import 'metric_card.dart';

/// Panel 2x2 hiển thị 4 chỉ số sức khỏe.
class HealthMetricsPanel extends StatelessWidget {
  final ElderlyModel elderly;

  const HealthMetricsPanel({super.key, required this.elderly});

  @override
  Widget build(BuildContext context) {
    final bool isOffline = elderly.isOffline;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.4,
      children: [
        MetricCard(
          icon: Icons.favorite,
          iconColor: Colors.red,
          label: Localization.translate('heartRate'),
          value: isOffline ? '--' : '${elderly.heartRate}',
          unit: 'BPM',
          alert: !isOffline && (elderly.heartRate > 100 || elderly.heartRate < 60),
        ),
        MetricCard(
          icon: Icons.opacity,
          iconColor: Colors.blueAccent,
          label: Localization.translate('spo2'),
          value: isOffline ? '--' : '${elderly.spo2}',
          unit: '%',
          alert: !isOffline && elderly.spo2 < 94,
        ),
        MetricCard(
          icon: Icons.thermostat,
          iconColor: Colors.orange,
          label: Localization.translate('temperature'),
          value: isOffline ? '--' : '36.5',
          unit: '°C',
          alert: false,
        ),
        MetricCard(
          icon: Icons.monitor_heart,
          iconColor: Colors.purple,
          label: Localization.translate('bloodPressure'),
          value: isOffline ? '--' : '120/80',
          unit: 'mmHg',
          alert: false,
        ),
      ],
    );
  }
}
