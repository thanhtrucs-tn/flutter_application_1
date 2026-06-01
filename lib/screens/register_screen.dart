import 'package:flutter/material.dart';
import '../database/db_helper.dart';

/// Trang đăng ký tài khoản
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controller để lấy dữ liệu từ TextField
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Biến trạng thái để hiển thị loading khi đang gọi database
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Xử lý logic khi người dùng nhấn nút đăng ký
  Future<void> _handleRegister() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Kiểm tra dữ liệu đầu vào
    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin.')),
      );
      return;
    }

    if (username.length > 32) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tài khoản không được vượt quá 32 ký tự.')),
      );
      return;
    }

    if (password.length > 64) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu không được vượt quá 64 ký tự.')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu nhập lại không khớp.')),
      );
      return;
    }

    // Bắt đầu quá trình đăng ký (hiển thị loading)
    setState(() {
      _isLoading = true;
    });

    // Gọi hàm đăng ký từ DbHelper
    String? errorMessage = await DbHelper.registerUser(username, password);

    // Kết thúc quá trình đăng ký (ẩn loading)
    setState(() {
      _isLoading = false;
    });

    if (errorMessage == null) {
      // Nếu thành công, hiển thị thông báo và quay lại trang đăng nhập
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng ký thành công! Vui lòng đăng nhập.')),
        );
        Navigator.pop(context);
      }
    } else {
      // Nếu thất bại (ví dụ: trùng tên đăng nhập hoặc lỗi MySQL)
      if (mounted) {
        // Tùy biến thông báo nếu lỗi do trùng lặp
        String displayError = errorMessage.contains('Duplicate entry') 
            ? 'Tài khoản này đã tồn tại.' 
            : 'Lỗi: $errorMessage';
            
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(displayError),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Điều chỉnh kích thước form dựa trên độ phân giải màn hình (Responsive)
    final double formWidth = screenWidth < 600 
        ? screenWidth * 0.9 
        : (screenWidth < 1200 ? 450.0 : 500.0);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Đăng ký'),
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: formWidth,
            child: Card(
              elevation: 8,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Ô nhập Tài khoản
                    TextField(
                      controller: _usernameController,
                      maxLength: 32,
                      decoration: const InputDecoration(
                        labelText: 'Tài khoản',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Ô nhập Mật khẩu
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      maxLength: 64,
                      decoration: const InputDecoration(
                        labelText: 'Mật khẩu',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Ô nhập lại Mật khẩu
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      maxLength: 64,
                      decoration: const InputDecoration(
                        labelText: 'Nhập lại mật khẩu',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Nút đăng ký
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _handleRegister,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Tạo tài khoản', style: TextStyle(fontSize: 16)),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
