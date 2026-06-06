import 'package:flutter/material.dart';
import '../models/elderly_model.dart';
import '../utils/localization.dart';
import 'vital_badge.dart';

/// Card hiển thị thông tin người cao tuổi trong danh sách Home.
class ElderlyListCard extends StatelessWidget {
  final ElderlyModel elderly;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLocateTap;

  const ElderlyListCard({
    super.key,
    required this.elderly,
    required this.isSelected,
    required this.onTap,
    required this.onLocateTap,
  });

  @override
  Widget build(BuildContext context) {
    Color cardBorderColor = Colors.grey.shade300;
    Color statusDotColor = const Color(0xFF10B981);
    String statusText = Localization.translate('statusSafeText');

    if (elderly.isOffline) {
      cardBorderColor = Colors.grey.shade400;
      statusDotColor = Colors.grey;
      statusText = Localization.translate('statusOffline');
    } else if (elderly.status == 'critical') {
      cardBorderColor = const Color(0xFFEF4444);
      statusDotColor = const Color(0xFFEF4444);
      statusText = Localization.translate('statusCriticalText');
    } else if (elderly.status == 'warning') {
      cardBorderColor = const Color(0xFFF59E0B);
      statusDotColor = const Color(0xFFF59E0B);
      statusText = Localization.translate('statusWarningText');
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? statusDotColor : cardBorderColor,
          width: isSelected ? 2.5 : 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: NetworkImage(elderly.avatar),
                  ),
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
                  Text(
                    '${Localization.translate('lastUpdate')}: ${elderly.lastUpdated.hour}:${elderly.lastUpdated.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusDotColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusText.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusDotColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
