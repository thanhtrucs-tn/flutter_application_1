import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/db_helper.dart';
import '../utils/localization.dart';
import '../utils/app_state.dart';
import 'home_screen.dart';
import 'register_screen.dart';

/// Trang đăng nhập cho ứng dụng SOS Care
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _dbStatusChecked = false;
  bool _isDbOnline = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _checkDatabaseStatus();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Kiểm tra trạng thái Database thực tế để hiển thị Badge cho lập trình viên
  Future<void> _checkDatabaseStatus() async {
    final conn = await DbHelper.getConnection();
    setState(() {
      _isDbOnline = conn != null;
      _dbStatusChecked = true;
    });
    if (conn != null) {
      await conn.close();
    }
  }

  /// Tải dữ liệu ghi nhớ đăng nhập
  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('saved_username') ?? '';
    final savedPassword = prefs.getString('saved_password') ?? '';
    final isRemembered = prefs.getBool('remember_me') ?? false;

    if (isRemembered) {
      setState(() {
        _usernameController.text = savedUsername;
        _passwordController.text = savedPassword;
        _rememberMe = true;
      });
    }
  }

  /// Lưu hoặc xóa dữ liệu ghi nhớ
  Future<void> _saveOrClearCredentials(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('saved_username', username);
      await prefs.setString('saved_password', password);
      await prefs.setBool('remember_me', true);
    } else {
      await prefs.remove('saved_username');
      await prefs.remove('saved_password');
      await prefs.setBool('remember_me', false);
    }
  }

  /// Xử lý logic đăng nhập
  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Localization.translate('Vui lòng nhập đầy đủ thông tin.')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    bool success = await DbHelper.loginUser(username, password);

    setState(() {
      _isLoading = false;
    });

    if (success) {
      await _saveOrClearCredentials(username, password);
      
      // Hiển thị thông báo trạng thái kết nối database
      String statusMsg = DbHelper.isUsingMock 
          ? "Đăng nhập offline thành công (Mock DB)" 
          : "Đăng nhập MySQL thành công!";
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(statusMsg),
            backgroundColor: DbHelper.isUsingMock ? Colors.amber.shade800 : Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sai tài khoản hoặc mật khẩu (Mặc định dùng admin / admin123)'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final double formWidth = size.width < 600 ? size.width * 0.92 : 460.0;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                : [const Color(0xFFE2F1F0), const Color(0xFFF8FAFC)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
              child: SizedBox(
                width: formWidth,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo y tế SOS Care
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.health_and_safety,
                          size: 72,
                          color: theme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      Localization.translate('appName'),
                      style: theme.textTheme.displayLarge?.copyWith(
                        color: theme.primaryColor,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hệ thống giám sát khẩn cấp cho người cao tuổi',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    
                    // Form đăng nhập đặt trong Card sang trọng
                    Card(
                      elevation: 4,
                      shadowColor: Colors.black12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              Localization.translate('login'),
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontSize: 26,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            
                            // Input Tài khoản
                            TextField(
                              controller: _usernameController,
                              style: const TextStyle(fontSize: 18),
                              decoration: InputDecoration(
                                labelText: Localization.translate('username'),
                                prefixIcon: const Icon(Icons.person_outline),
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Input Mật khẩu
                            TextField(
                              controller: _passwordController,
                              obscureText: true,
                              style: const TextStyle(fontSize: 18),
                              decoration: InputDecoration(
                                labelText: Localization.translate('password'),
                                prefixIcon: const Icon(Icons.lock_outline),
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // Ghi nhớ đăng nhập
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  activeColor: theme.primaryColor,
                                  onChanged: (value) {
                                    setState(() {
                                      _rememberMe = value ?? false;
                                    });
                                  },
                                ),
                                Text(
                                  Localization.translate('rememberMe'),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            
                            // Nút đăng nhập
                            _isLoading
                                ? const Center(child: CircularProgressIndicator())
                                : ElevatedButton(
                                    onPressed: _handleLogin,
                                    child: Text(
                                      Localization.translate('login').toUpperCase(),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Chuyển sang màn đăng ký
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          Localization.translate('noAccount'),
                          style: TextStyle(fontSize: 16, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RegisterScreen()),
                            );
                          },
                          child: Text(
                            Localization.translate('registerNow'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Trạng thái cơ sở dữ liệu MySQL badge
                    if (_dbStatusChecked)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _isDbOnline 
                                ? Colors.green.withOpacity(0.1) 
                                : Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _isDbOnline ? Colors.green.shade400 : Colors.amber.shade700,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isDbOnline ? Icons.cloud_done : Icons.cloud_off,
                                size: 14,
                                color: _isDbOnline ? Colors.green : Colors.amber.shade700,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isDbOnline 
                                    ? 'MySQL Server: Connected' 
                                    : 'Offline Mode: Local Mock DB Active',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _isDbOnline ? Colors.green.shade700 : Colors.amber.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
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
