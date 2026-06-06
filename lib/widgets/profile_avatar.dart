import 'dart:io';
import 'package:flutter/material.dart';

/// Hiển thị avatar từ `avatarLocalPath` (ưu tiên) hoặc `avatarUrl` (fallback).
/// Nếu cả hai đều rỗng/không hợp lệ thì hiển thị icon người.
class ProfileAvatar extends StatelessWidget {
  final String avatarUrl;
  final String avatarLocalPath;
  final double radius;
  final Color backgroundColor;

  const ProfileAvatar({
    super.key,
    required this.avatarUrl,
    required this.avatarLocalPath,
    this.radius = 24,
    this.backgroundColor = const Color(0xFFE0E0E0),
  });

  ImageProvider? _buildProvider() {
    if (avatarLocalPath.isNotEmpty) {
      final file = File(avatarLocalPath);
      if (file.existsSync()) return FileImage(file);
    }
    if (avatarUrl.isNotEmpty) {
      return NetworkImage(avatarUrl);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final provider = _buildProvider();
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      backgroundImage: provider,
      child: provider == null
          ? Icon(
              Icons.person,
              size: radius * 0.9,
              color: Colors.grey.shade500,
            )
          : null,
    );
  }
}
