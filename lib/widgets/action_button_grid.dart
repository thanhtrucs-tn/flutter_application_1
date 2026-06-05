import 'package:flutter/material.dart';
import '../utils/localization.dart';

/// Lưới 2x2 các nút thao tác nhanh: Gọi, Rung, Nghe, SMS.
class ActionButtonGrid extends StatelessWidget {
  final VoidCallback onCall;
  final VoidCallback onRing;
  final VoidCallback onListen;
  final VoidCallback onSms;
  final bool compact;

  const ActionButtonGrid({
    super.key,
    required this.onCall,
    required this.onRing,
    required this.onListen,
    required this.onSms,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final aspectRatio = compact ? 4.5 : 2.4;
    final hPad = compact ? 10.0 : 12.0;
    final vPad = compact ? 6.0 : 10.0;
    final iconSize = compact ? 16.0 : 18.0;
    final iconInnerPad = compact ? 6.0 : 8.0;
    final fontSize = compact ? 12.0 : 13.0;
    final spacing = compact ? 8.0 : 10.0;

    final items = [
      _ActionItem(
        label: Localization.translate('callElderly'),
        icon: Icons.phone,
        color: Colors.green,
        onTap: onCall,
      ),
      _ActionItem(
        label: Localization.translate('ringDevice'),
        icon: Icons.notification_important,
        color: Colors.orange.shade700,
        onTap: onRing,
      ),
      _ActionItem(
        label: Localization.translate('listenAmbient'),
        icon: Icons.mic,
        color: Colors.teal,
        onTap: onListen,
      ),
      _ActionItem(
        label: Localization.translate('sendSOSMsg'),
        icon: Icons.sms,
        color: Colors.red,
        onTap: onSms,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
      childAspectRatio: aspectRatio,
      children: items.map((i) => _buildButton(i, hPad, vPad, iconSize, iconInnerPad, fontSize)).toList(),
    );
  }

  Widget _buildButton(_ActionItem item, double hPad, double vPad, double iconSize, double iconInnerPad, double fontSize) {
    return Material(
      color: item.color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: item.color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(iconInnerPad),
                decoration: BoxDecoration(color: item.color, shape: BoxShape.circle),
                child: Icon(item.icon, color: Colors.white, size: iconSize),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize, color: item.color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  _ActionItem({required this.label, required this.icon, required this.color, required this.onTap});
}
