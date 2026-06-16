import 'package:flutter/material.dart';
import '../utils/localization.dart';

/// BottomNavigationBar dùng chung cho 5 tab chính của SOS Care.
class SosBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int alertBadgeCount;

  const SosBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.alertBadgeCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      selectedItemColor: const Color(0xFFE53935),
      unselectedItemColor: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      iconSize: 28,
      elevation: 8,
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home_rounded),
          label: Localization.translate('home'),
        ),
        BottomNavigationBarItem(
          icon: alertBadgeCount > 0
              ? Badge(
                  label: Text(alertBadgeCount > 99 ? '99+' : '$alertBadgeCount'),
                  child: const Icon(Icons.notifications_rounded),
                )
              : const Icon(Icons.notifications_rounded),
          label: Localization.translate('alerts'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.settings_rounded),
          label: Localization.translate('settings'),
        ),
      ],
    );
  }
}
