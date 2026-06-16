import 'package:flutter/material.dart';
import '../models/elderly_model.dart';
import '../utils/localization.dart';
import 'device_online_badge.dart';
import 'elderly_avatar.dart';
import 'vital_badge.dart';

/// Phần nội dung hiển thị bên trong card người cao tuổi.
class ElderlyCardContent extends StatelessWidget {
  final ElderlyModel elderly;
  final Color statusDotColor;
  final String statusText;

  const ElderlyCardContent({
    super.key,
    required this.elderly,
    required this.statusDotColor,
    required this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            ElderlyAvatar(elderly: elderly, radius: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          elderly.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                      ),
                      const SizedBox(width: 8),
                      DeviceOnlineBadge(elderly: elderly),
                      const SizedBox(width: 8),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(color: statusDotColor, shape: BoxShape.circle),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${Localization.translate('wearableDevice')}: ${elderly.wearableDevice}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: VitalBadge(
                icon: Icons.favorite,
                color: Colors.red,
                value: elderly.isOffline ? '--' : '${elderly.heartRate} bpm',
                isSmall: false,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: VitalBadge(
                icon: Icons.opacity,
                color: Colors.blueAccent,
                value: elderly.isOffline ? '--' : 'SpO2: ${elderly.spo2}%',
                isSmall: false,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: VitalBadge(
                icon: Icons.battery_charging_full,
                color: elderly.battery > 30 ? Colors.green : Colors.orange,
                value: '${elderly.battery}%',
                isSmall: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                '${Localization.translate('lastUpdate')}: ${elderly.lastUpdated.hour}:${elderly.lastUpdated.minute.toString().padLeft(2, '0')}',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusDotColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusText.toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusDotColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
