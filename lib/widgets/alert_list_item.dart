import 'package:flutter/material.dart';
import '../models/alert_model.dart';

/// Một dòng cảnh báo trong danh sách lịch sử.
class AlertListItem extends StatelessWidget {
  final AlertModel alert;
  final VoidCallback onTap;

  const AlertListItem({super.key, required this.alert, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = alert.urgency == 'critical' ? Colors.red : Colors.orange;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.1),
                child: Icon(
                  alert.urgency == 'critical' ? Icons.gpp_maybe : Icons.warning,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.message,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${alert.elderlyName} • ${alert.time.hour}:${alert.time.minute.toString().padLeft(2, '0')} • ${alert.locationName}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: alert.acknowledged ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  alert.acknowledged ? 'ĐÃ XỬ LÝ' : 'CHƯA XỬ LÝ',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: alert.acknowledged ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
