import 'dart:io';
import 'package:flutter/material.dart';
import '../models/elderly_model.dart';

/// Widget hiển thị avatar của người cao tuổi.
/// Ưu tiên ảnh local nếu có, fallback về URL, cuối cùng là icon mặc định.
class ElderlyAvatar extends StatelessWidget {
  final ElderlyModel elderly;
  final double radius;
  final VoidCallback? onTap;

  const ElderlyAvatar({
    super.key,
    required this.elderly,
    this.radius = 20,
    this.onTap,
  });

  ImageProvider? _buildImageProvider() {
    if (elderly.avatarLocalPath.isNotEmpty) {
      final file = File(elderly.avatarLocalPath);
      if (file.existsSync()) {
        return FileImage(file);
      }
    }
    if (elderly.avatar.isNotEmpty) {
      return NetworkImage(elderly.avatar);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final image = _buildImageProvider();
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey.shade200,
      backgroundImage: image,
      child: image == null
          ? Icon(Icons.person, size: radius, color: Colors.grey)
          : null,
    );

    if (onTap == null) return avatar;

    return GestureDetector(
      onTap: onTap,
      child: avatar,
    );
  }
}
