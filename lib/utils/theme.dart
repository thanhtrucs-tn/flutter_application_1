import 'package:flutter/material.dart';

/// Lớp định nghĩa hệ thống Theme cho SOS Care
class AppTheme {
  // Màu sắc chủ đạo (Healthcare Teal)
  static const Color primaryTeal = Color(0xFF0F766E); // Teal đậm
  static const Color secondaryTeal = Color(0xFF14B8A6); // Teal sáng

  // Màu trạng thái an toàn / cảnh báo
  static const Color statusSafe = Color(0xFF10B981); // Emerald Green (An toàn)
  static const Color statusWarning = Color(0xFFF59E0B); // Amber Orange (Cần lưu ý)
  static const Color statusCritical = Color(0xFFEF4444); // Bright Red (SOS Khẩn cấp)

  // Màu phụ trợ Light Mode
  static const Color bgLight = Color(0xFFF8FAFC); // Slate 50
  static const Color cardLight = Colors.white;
  static const Color textDark = Color(0xFF1E293B); // Slate 800
  static const Color textMutedDark = Color(0xFF64748B); // Slate 500

  // Màu phụ trợ Dark Mode
  static const Color bgDark = Color(0xFF0F172A); // Slate 900
  static const Color cardDark = Color(0xFF1E293B); // Slate 800
  static const Color textLight = Color(0xFFF8FAFC); // Slate 50
  static const Color textMutedLight = Color(0xFF94A3B8); // Slate 400

  /// Cấu hình Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryTeal,
      colorScheme: const ColorScheme.light(
        primary: primaryTeal,
        secondary: secondaryTeal,
        error: statusCritical,
        background: bgLight,
        surface: cardLight,
      ),
      scaffoldBackgroundColor: bgLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: statusCritical,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textDark),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textDark),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textDark),
        bodyLarge: TextStyle(fontSize: 18, color: textDark, height: 1.4),
        bodyMedium: TextStyle(fontSize: 16, color: textMutedDark, height: 1.4),
        labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryTeal),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryTeal, width: 2),
        ),
        labelStyle: const TextStyle(fontSize: 16, color: textMutedDark),
      ),
    );
  }

  /// Cấu hình Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: secondaryTeal,
      colorScheme: const ColorScheme.dark(
        primary: secondaryTeal,
        secondary: primaryTeal,
        error: statusCritical,
        background: bgDark,
        surface: cardDark,
      ),
      scaffoldBackgroundColor: bgDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFB71C1C),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondaryTeal,
          foregroundColor: bgDark,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textLight),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textLight),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textLight),
        bodyLarge: TextStyle(fontSize: 18, color: textLight, height: 1.4),
        bodyMedium: TextStyle(fontSize: 16, color: textMutedLight, height: 1.4),
        labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: secondaryTeal),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: secondaryTeal, width: 2),
        ),
        labelStyle: const TextStyle(fontSize: 16, color: textMutedLight),
      ),
    );
  }
}
