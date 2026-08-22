import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/device_event_service.dart';
import '../services/token_storage.dart';
import '../utils/app_state.dart';
import '../utils/localization.dart';
import 'main_shell.dart';
import 'register_screen.dart';

/// Trang đăng nhập cho ứng dụng SOS Care (REST/JWT tới backend :8081).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Tải email đã ghi nhớ (không lưu mật khẩu — chỉ username/email).
  Future<void> _loadSavedCredentials() async {
    final rm = await TokenStorage.loadRememberMe();
    if (rm.remember && rm.username.isNotEmpty) {
      setState(() {
        _emailController.text = rm.username;
        _rememberMe = true;
      });
    }
  }

  /// Xử lý đăng nhập: gọi backend, lưu JWT, tải dữ liệu, kết nối realtime.
  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Localization.translate('fillAllFields')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await AuthService.instance.login(email, password);
      await TokenStorage.saveRememberMe(email, _rememberMe);
      await AppState().setCurrentAccount(result.profile, result.token);
      DeviceEventService().reauthenticate(result.token);

      if (!mounted) return;
      setState(() => _isLoading = false);

      final messenger = ScaffoldMessenger.of(context);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Đăng nhập thành công'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không kết nối được tới máy chủ'),
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
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15),
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
                              style: theme.textTheme.headlineMedium?.copyWith(fontSize: 26),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),

                            // Input Email
                            TextField(
                              controller: _emailController,
                              maxLength: 48,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(fontSize: 18),
                              decoration: InputDecoration(
                                labelText: Localization.translate('email'),
                                prefixIcon: const Icon(Icons.email_outlined),
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
                                    setState(() => _rememberMe = value ?? false);
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
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const RegisterScreen()),
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