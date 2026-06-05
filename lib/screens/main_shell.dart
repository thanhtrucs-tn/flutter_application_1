import 'package:flutter/material.dart';
import '../utils/app_state.dart';
import '../widgets/sos_bottom_nav.dart';
import 'home_screen.dart';
import 'alerts_screen.dart';
import 'add_alert_screen.dart';
import 'settings_screen.dart';
import 'account_screen.dart';

/// Shell chứa IndexedStack + BottomNavigationBar cho 5 tab chính.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: AppState().currentNavIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    AppState().setNavIndex(index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState();
    return AnimatedBuilder(
      animation: state,
      builder: (context, child) {
        return Scaffold(
          body: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              HomeScreen(),
              AlertsScreen(),
              AddAlertScreen(),
              SettingsScreen(),
              AccountScreen(),
            ],
          ),
          bottomNavigationBar: SosBottomNav(
            currentIndex: state.currentNavIndex,
            onTap: _onNavTap,
          ),
        );
      },
    );
  }
}
