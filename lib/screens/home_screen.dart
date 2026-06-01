import 'package:flutter/material.dart';
import 'login_screen.dart';

/// Trang chủ của ứng dụng sau khi đăng nhập thành công
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// Xử lý đăng xuất
  void _logout(BuildContext context) {
    // Chuyển hướng người dùng về trang đăng nhập và xóa toàn bộ các trang trước đó
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false, // Xóa tất cả route trong ngăn xếp
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang chủ'),
        backgroundColor: Colors.white,
        actions: [
          // Nút đăng xuất ở góc trên bên phải
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Chữ "Hello" theo yêu cầu
            const Text(
              'Hello',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 32),
            // Nút đăng xuất phụ ở giữa màn hình
            ElevatedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.exit_to_app),
              label: const Text('Đăng xuất'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: const TextStyle(fontSize: 18),
              ),
            )
          ],
        ),
      ),
    );
  }
}
