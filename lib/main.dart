import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'utils/app_state.dart';
import 'utils/theme.dart';

void main() {
  // Đảm bảo các dịch vụ Flutter đã được khởi tạo hoàn toàn trước khi chạy app
  WidgetsFlutterBinding.ensureInitialized();
  
  // Khởi tạo trước AppState singleton để kích hoạt các cài đặt lưu trữ
  AppState();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState();

    // Dùng AnimatedBuilder lắng nghe AppState thay đổi cài đặt Sáng/Tối toàn hệ thống
    return AnimatedBuilder(
      animation: state,
      builder: (context, child) {
        return MaterialApp(
          title: 'SOS Care',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          // Đọc cấu hình dark mode lưu trong AppState
          themeMode: state.settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const LoginScreen(),
        );
      },
    );
  }
}
