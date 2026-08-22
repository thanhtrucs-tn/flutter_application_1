import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'services/api_client.dart';
import 'services/device_event_service.dart';
import 'services/notification_service.dart';
import 'utils/app_state.dart';
import 'utils/theme.dart';

/// URL backend SOS Care mặc định. Trên Android emulator sẽ được tự động
/// thay thành `http://10.0.2.2:8081` (xem [DeviceEventMapper.resolveBackendUrl]).
const String _kSosBackendUrl = 'http://localhost:8081';

/// Key điều hướng gốc — dùng để ApiClient.onUnauthorized quay về LoginScreen
/// khi JWT hết hạn (401) từ bất kỳ màn nào.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  // Đảm bảo các dịch vụ Flutter đã được khởi tạo hoàn toàn trước khi chạy app
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo thông báo nội bộ trước khi chạy UI.
  try {
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Không khởi tạo được notification service: $e');
  }

  // Cấu hình HTTP client (base URL + xử lý 401 → đăng xuất, về login).
  ApiClient.instance.configure(_kSosBackendUrl);
  ApiClient.instance.onUnauthorized = () {
    if (!AppState().isAuthenticated) return; // đã ở login / đã logout
    final nav = rootNavigatorKey.currentState;
    if (nav == null) return;
    AppState().logout();
    DeviceEventService().reauthenticate(null);
    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  };

  // Khởi tạo AppState singleton để kích hoạt các cài đặt lưu trữ.
  AppState();

  // Kết nối realtime tới backend SOS Care (chưa auth; sẽ re-auth sau login).
  try {
    DeviceEventService().start(_kSosBackendUrl);
  } catch (e) {
    debugPrint('Không kết nối được realtime backend: $e');
  }

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
          navigatorKey: rootNavigatorKey,
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