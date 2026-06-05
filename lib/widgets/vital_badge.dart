import 'package:flutter/material.dart';

/// Badge hiển thị chỉ số sinh tồn dạng pill nhỏ.
class VitalBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final bool isSmall;

  const VitalBadge({
    super.key,
    required this.icon,
    required this.color,
    required this.value,
    this.isSmall = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 10 : 14, vertical: isSmall ? 6 : 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: isSmall ? 16 : 20),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmall ? 13 : 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
