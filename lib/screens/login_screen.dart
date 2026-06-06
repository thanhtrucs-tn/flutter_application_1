import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/db_helper.dart';
import '../services/auth_api_service.dart';
import '../utils/localization.dart';
import 'main_shell.dart';
import 'register_screen.dart';

/// Trang đăng nhập cho ứng dụng SOS Care
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();                            
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();        //  Điều khiển input tài khoản
  final TextEditingController _passwordController = TextEditingController();      //  Điều khiển input mật khẩu
  bool _rememberMe = false;                                                 //  Trạng thái ghi nhớ đăng nhập
  bool _isLoading = false;                                             //  Trạng thái đang xử lý đăng nhập
  bool _dbStatusChecked = false;                                     //  Đã kiểm tra trạng thái database chưa
  bool _isDbOnline = false;                                          //  Trạng thái kết nối database thực tế (MySQL online hay Mock offline)

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
    if (kIsWeb) {
      // Trên web (Chrome): Gọi backend health check trước
      // Nếu backend sẵn sàng → dùng API gọi MySQL
      // Nếu không → fallback localStorage
      final backendOk = await AuthApiService.healthCheck();
      DbHelper.backendAvailable = backendOk;
      setState(() {
        _isDbOnline = backendOk;
        _dbStatusChecked = true;
      });
      return;
    }
    // Trên Windows/MySQL: thử kết nối trực tiếp
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
      String statusMsg;
      if (kIsWeb) {
        statusMsg = "Đăng nhập thành công trên Chrome (Web - Offline Mode)";
      } else if (DbHelper.isUsingMock) {
        statusMsg = "Đăng nhập offline thành công (Mock DB)";
      } else {
        statusMsg = "Đăng nhập MySQL thành công!";
      }

      if (!mounted) return;

      // Lưu tham chiếu ScaffoldMessenger TRƯỚC khi navigate
      // tránh lỗi "Looking up a deactivated widget's ancestor" vì
      // Navigator.pushReplacement sẽ dispose LoginScreen ngay lập tức.
      final messenger = ScaffoldMessenger.of(context);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainShell()),
      );

      // Hiển thị snackbar trên messenger đã capture (an toàn sau navigate)
      messenger.showSnackBar(
        SnackBar(
          content: Text(statusMsg),
          backgroundColor: (kIsWeb || DbHelper.isUsingMock) ? Colors.amber.shade800 : Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
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
                              maxLength: 32,
                              style: const TextStyle(fontSize: 18),
                              decoration: InputDecoration(
                                labelText: Localization.translate('username'),
                                prefixIcon: const Icon(Icons.person_outline),
                                counterText: '',
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Input Mật khẩu
                            TextField(
                              controller: _passwordController,
                              obscureText: true,
                              maxLength: 64,
                              style: const TextStyle(fontSize: 18),
                              decoration: InputDecoration(
                                labelText: Localization.translate('password'),
                                prefixIcon: const Icon(Icons.lock_outline),
                                counterText: '',
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
                            color: _getPlatformBadgeColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _getPlatformBadgeColor(),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getPlatformBadgeIcon(),
                                size: 14,
                                color: _getPlatformBadgeColor(),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _getPlatformBadgeText(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _getPlatformBadgeColor(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),

                    // Gợi ý tài khoản mặc định cho chế độ Offline (Web/Windows không có MySQL)
                    if (_dbStatusChecked && !_isDbOnline)
                      Center(
                        child: Text(
                          'Tài khoản mặc định: admin / admin123',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
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

  /// Màu sắc của badge trạng thái theo nền tảng
  Color _getPlatformBadgeColor() {
    if (kIsWeb) {
      return _isDbOnline ? Colors.green.shade700 : Colors.blue.shade700;
    }
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return _isDbOnline ? Colors.green.shade700 : Colors.deepPurple;
    }
    return _isDbOnline ? Colors.green.shade700 : Colors.amber.shade800;
  }

  /// Icon của badge trạng thái theo nền tảng
  IconData _getPlatformBadgeIcon() {
    if (kIsWeb) {
      return _isDbOnline ? Icons.cloud_done : Icons.public;
    }
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return _isDbOnline ? Icons.cloud_done : Icons.desktop_windows;
    }
    return _isDbOnline ? Icons.cloud_done : Icons.cloud_off;
  }

  /// Văn bản của badge trạng thái theo nền tảng
  String _getPlatformBadgeText() {
    if (kIsWeb) {
      return _isDbOnline
          ? 'Chrome (Web): MySQL Synced via API'
          : 'Chrome (Web): Local Account Ready';
    }
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return _isDbOnline
          ? 'Windows: MySQL Connected'
          : 'Windows: Offline Mock DB Active';
    }
    return _isDbOnline
        ? 'MySQL Server: Connected'
        : 'Offline Mode: Local Mock DB Active';
  }
}
