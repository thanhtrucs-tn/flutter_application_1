import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';

/// Slider card that displays and adjusts the simulated heart rate.
///
/// Highlights in red when the BPM exceeds the alert threshold.
class HeartRateSliderCard extends StatelessWidget {
  final int heartRateBpm;
  final ValueChanged<double> onChanged;

  const HeartRateSliderCard({
    super.key,
    required this.heartRateBpm,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isAlert = heartRateBpm > AppConstants.heartRateAlertThreshold;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.favorite,
                  color: isAlert ? Colors.red : null,
                ),
                const SizedBox(width: 8),
                Text(
                  'Nhịp tim: $heartRateBpm BPM',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isAlert ? Colors.red : null,
                        fontWeight: isAlert ? FontWeight.bold : null,
                      ),
                ),
              ],
            ),
            if (isAlert)
              const Padding(
                padding: EdgeInsets.only(top: 4, bottom: 4),
                child: Text(
                  'Cảnh báo: nhịp tim cao!',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            Slider(
              value: heartRateBpm.toDouble(),
              min: AppConstants.minHeartRate.toDouble(),
              max: AppConstants.maxHeartRate.toDouble(),
              divisions:
                  AppConstants.maxHeartRate - AppConstants.minHeartRate,
              label: '$heartRateBpm BPM',
              activeColor: isAlert ? Colors.red : null,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
