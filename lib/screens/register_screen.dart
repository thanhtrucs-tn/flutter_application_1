import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../utils/localization.dart';

/// Trang đăng ký tài khoản cho ứng dụng SOS Care
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Xử lý logic khi người dùng nhấn nút đăng ký
  Future<void> _handleRegister() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Localization.translate('fillAllFields')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Localization.translate('invalidEmail')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Localization.translate('passwordMismatch')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String? errorMessage = await DbHelper.registerUser(
      username,
      password,
      email: email,
    );

    setState(() {
      _isLoading = false;
    });

    if (errorMessage == null) {
      if (mounted) {
        String regSuccessMsg;
        if (kIsWeb) {
          regSuccessMsg = 'Đăng ký tài khoản thành công trên Chrome (Web)!';
        } else if (DbHelper.isUsingMock) {
          regSuccessMsg = 'Đăng ký tài khoản offline thành công!';
        } else {
          regSuccessMsg = 'Đăng ký tài khoản MySQL thành công!';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(regSuccessMsg),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Quay lại trang đăng nhập
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Kiểm tra định dạng email cơ bản.
  bool _isValidEmail(String value) {
    return RegExp(r"^[^\s@]+@[^\s@]+\.[^\s@]+$")
        .hasMatch(value.trim());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final double formWidth = size.width < 600 ? size.width * 0.92 : 460.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(Localization.translate('register')),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
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
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: formWidth,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                              Localization.translate('register'),
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontSize: 26,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),

                            // Input Tên tài khoản
                            TextField(
                              controller: _usernameController,
                              maxLength: 32,
                              style: const TextStyle(fontSize: 18),
                              decoration: InputDecoration(
                                labelText: Localization.translate('username'),
                                prefixIcon: const Icon(Icons.person_outline),
                                counterText: "",
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Input Email
                            TextField(
                              controller: _emailController,
                              maxLength: 48,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(fontSize: 18),
                              decoration: InputDecoration(
                                labelText: Localization.translate('email'),
                                prefixIcon: const Icon(Icons.email_outlined),
                                counterText: "",
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
                                counterText: "",
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Xác nhận mật khẩu
                            TextField(
                              controller: _confirmPasswordController,
                              obscureText: true,
                              maxLength: 64,
                              style: const TextStyle(fontSize: 18),
                              decoration: InputDecoration(
                                labelText: Localization.translate('confirmPassword'),
                                prefixIcon: const Icon(Icons.lock_outline),
                                counterText: "",
                              ),
                            ),
                            const SizedBox(height: 32),
                            
                            // Nút Đăng ký
                            _isLoading
                                ? const Center(child: CircularProgressIndicator())
                                : ElevatedButton(
                                    onPressed: _handleRegister,
                                    child: Text(
                                      Localization.translate('register').toUpperCase(),
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
