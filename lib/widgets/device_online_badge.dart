import 'package:flutter/material.dart';
import '../models/elderly_model.dart';
import '../utils/localization.dart';

/// Badge hiển thị trạng thái thiết bị đang ONLINE hay OFFLINE.
///
/// Được thiết kế để thay đổi ngay lập tức khi [ElderlyModel.isOffline]
/// thay đổi, giúp người dùng nhận biết realtime thiết bị người thân.
class DeviceOnlineBadge extends StatelessWidget {
  final ElderlyModel elderly;

  const DeviceOnlineBadge({super.key, required this.elderly});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOnline = !elderly.isOffline;

    final backgroundColor = isOnline
        ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5))
        : (isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6));
    final textColor = isOnline
        ? const Color(0xFF059669)
        : (isDark ? Colors.grey.shade400 : Colors.grey.shade600);
    final dotColor = isOnline ? const Color(0xFF10B981) : Colors.grey.shade400;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOnline
              ? const Color(0xFF059669).withValues(alpha: 0.3)
              : (isDark ? Colors.grey.shade600 : Colors.grey.shade300),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              boxShadow: isOnline
                  ? [
                      BoxShadow(
                        color: dotColor.withValues(alpha: 0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isOnline ? Localization.translate('online') : Localization.translate('offline'),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
