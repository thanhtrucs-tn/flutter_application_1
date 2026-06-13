import 'package:flutter/material.dart';
import 'profile_avatar.dart';

/// Header hiển thị avatar lớn, tên, tuổi, địa chỉ và trạng thái.
class ProfileHeader extends StatelessWidget {
  final String avatarUrl;
  final String? avatarLocalPath;
  final String name;
  final String? age;
  final String? address;
  final Color statusColor;
  final String statusText;

  const ProfileHeader({
    super.key,
    required this.avatarUrl,
    this.avatarLocalPath,
    required this.name,
    this.age,
    this.address,
    required this.statusColor,
    required this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            ProfileAvatar(
              avatarUrl: avatarUrl,
              avatarLocalPath: avatarLocalPath ?? '',
              radius: 44,
              backgroundColor: Colors.grey.shade200,
            ),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                border: Border.all(color: isDark ? const Color(0xFF0F172A) : Colors.white, width: 2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        if (age != null || address != null)
          Text(
            '${age ?? ''}${age != null && address != null ? ' • ' : ''}${address ?? ''}',
            style: TextStyle(fontSize: 14, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            statusText.toUpperCase(),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor),
          ),
        ),
      ],
    );
  }
}
