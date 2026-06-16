import 'package:flutter/material.dart';
import '../utils/app_state.dart';
import '../widgets/sos_bottom_nav.dart';
import 'home_screen.dart';
import 'alerts_screen.dart';
import 'settings_screen.dart';

/// Shell chứa PageView + BottomNavigationBar cho 3 tab chính.
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
    // Đảm bảo chỉ số ban đầu hợp lệ cho 3 tab (0, 1, 2)
    int initialPage = AppState().currentNavIndex;
    if (initialPage > 2) {
      initialPage = 0;
      AppState().setNavIndex(0);
    }
    _pageController = PageController(initialPage: initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    final state = AppState();
    state.setNavIndex(index);
    if (index == 1) {
      // Tab Thông báo: đánh dấu tất cả cảnh báo đã đọc.
      state.markAllAlertsRead();
    }
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
        // Đảm bảo index hiện tại không vượt quá số tab
        int currentIndex = state.currentNavIndex;
        if (currentIndex > 2) {
          currentIndex = 0;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            state.setNavIndex(0);
          });
        }

        return Scaffold(
          body: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              HomeScreen(),
              AlertsScreen(),
              SettingsScreen(),
            ],
          ),
          bottomNavigationBar: SosBottomNav(
            currentIndex: currentIndex,
            onTap: _onNavTap,
            alertBadgeCount: state.alertBadgeCount,
          ),
        );
      },
    );
  }
}
