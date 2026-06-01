import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/db_helper.dart';
import 'home_screen.dart';
import 'register_screen.dart';

/// Trang đăng nhập
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controller để lấy dữ liệu từ TextField
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // Trạng thái ghi nhớ đăng nhập
  bool _rememberMe = false;
  // Biến hiển thị loading
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Tải dữ liệu tài khoản đã lưu (nếu có) khi màn hình khởi tạo
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Hàm đọc dữ liệu tài khoản từ bộ nhớ cục bộ
  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('saved_username') ?? '';
    final savedPassword = prefs.getString('saved_password') ?? '';
    final isRemembered = prefs.getBool('remember_me') ?? false;

    // Nếu người dùng đã chọn "Ghi nhớ đăng nhập" từ lần trước, điền sẵn thông tin
    if (isRemembered) {
      setState(() {
        _usernameController.text = savedUsername;
        _passwordController.text = savedPassword;
        _rememberMe = true;
      });
    }
  }

  /// Hàm lưu hoặc xóa dữ liệu tài khoản tùy thuộc vào trạng thái Checkbox
  Future<void> _saveOrClearCredentials(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      // Lưu lại thông tin nếu tích chọn ghi nhớ
      await prefs.setString('saved_username', username);
      await prefs.setString('saved_password', password);
      await prefs.setBool('remember_me', true);
    } else {
      // Xóa thông tin nếu không tích chọn
      await prefs.remove('saved_username');
      await prefs.remove('saved_password');
      await prefs.setBool('remember_me', false);
    }
  }

  /// Xử lý logic khi người dùng nhấn nút đăng nhập
  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    // Kiểm tra đầu vào
    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tài khoản và mật khẩu.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Gọi hàm kiểm tra thông tin từ database MySQL
    bool success = await DbHelper.loginUser(username, password);

    setState(() {
      _isLoading = false;
    });

    if (success) {
      // Lưu hoặc xóa thông tin autofill
      await _saveOrClearCredentials(username, password);
      
      // Đăng nhập thành công, chuyển hướng vào màn hình chính
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } else {
      // Đăng nhập thất bại, thông báo cho người dùng
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sai tài khoản hoặc mật khẩu.')),
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
        title: const Text('Đăng nhập'),
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
                    // Tài khoản
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
                    // Mật khẩu
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
                    const SizedBox(height: 8),
                    // Ghi nhớ đăng nhập
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                          },
                        ),
                        const Text('Ghi nhớ đăng nhập'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Nút đăng nhập
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _handleLogin,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Đăng nhập', style: TextStyle(fontSize: 16)),
                          ),
                    const SizedBox(height: 24),
                    // Divider
                    Row(
                      children: const [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('HOẶC'),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Nút đăng kí
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Chưa có tài khoản?'),
                        TextButton(
                          onPressed: () {
                            // Chuyển sang trang đăng kí
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RegisterScreen()),
                            );
                          },
                          child: const Text('Đăng ký ngay'),
                        ),
                      ],
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
