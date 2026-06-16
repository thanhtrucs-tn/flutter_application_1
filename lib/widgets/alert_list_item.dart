import 'package:flutter/material.dart';
import '../models/alert_model.dart';
import '../utils/localization.dart';

/// Một dòng cảnh báo trong danh sách lịch sử.
///
/// Hiển thị badge thời gian chi tiết ở góc phải và hỗ trợ hiệu ứng
/// highlight cho thông báo mới nhất.
class AlertListItem extends StatelessWidget {
  final AlertModel alert;
  final VoidCallback onTap;
  final bool isLatest;

  const AlertListItem({
    super.key,
    required this.alert,
    required this.onTap,
    this.isLatest = false,
  });

  String _formatTimestamp(DateTime t) {
    final d = t.day.toString().padLeft(2, '0');
    final m = t.month.toString().padLeft(2, '0');
    final y = t.year;
    final h = t.hour.toString().padLeft(2, '0');
    final min = t.minute.toString().padLeft(2, '0');
    final s = t.second.toString().padLeft(2, '0');
    return '$d/$m/$y - $h:$min:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = alert.urgency == 'critical' ? Colors.red : Colors.orange;

    final card = Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          width: 1,
        ),
      ),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withValues(alpha: 0.1),
                child: Icon(
                  alert.urgency == 'critical' ? Icons.error_rounded : Icons.warning_rounded,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.message,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${alert.elderlyName} • ${alert.locationName}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: alert.acknowledged ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    alert.acknowledged
                        ? Localization.translate('processed')
                        : Localization.translate('unprocessed'),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: alert.acknowledged ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (isLatest)
          _LatestHighlight(color: color, child: card)
        else
          card,
        Positioned(
          top: 0,
          right: 0,
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : Colors.grey.shade100,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(8),
                ),
                border: Border(
                  bottom: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                  left: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                ),
              ),
              child: Text(
                _formatTimestamp(alert.time),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Hiệu ứng nhấp nháy viền nhẹ quanh card thông báo mới nhất.
class _LatestHighlight extends StatefulWidget {
  final Widget child;
  final Color color;

  const _LatestHighlight({required this.child, required this.color});

  @override
  State<_LatestHighlight> createState() => _LatestHighlightState();
}

class _LatestHighlightState extends State<_LatestHighlight>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(
                  alpha: 0.25 + 0.35 * _controller.value,
                ),
                blurRadius: 6 + 8 * _controller.value,
                spreadRadius: 1 + 2 * _controller.value,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
