import 'package:flutter/material.dart';
import '../utils/localization.dart';

/// BottomNavigationBar dùng chung cho 5 tab chính của SOS Care.
class SosBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const SosBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      selectedItemColor: const Color(0xFFE53935),
      unselectedItemColor: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
      unselectedLabelStyle: const TextStyle(fontSize: 11),
      elevation: 8,
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home_filled),
          label: Localization.translate('home'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.notifications),
          label: Localization.translate('alerts'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.add_circle, size: 32),
          label: Localization.translate('add'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.settings),
          label: Localization.translate('settings'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person),
          label: Localization.translate('account'),
        ),
      ],
    );
  }
}
