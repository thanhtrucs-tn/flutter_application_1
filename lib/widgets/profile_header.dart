import 'package:flutter/material.dart';

/// Header hiển thị avatar lớn, tên, tuổi, địa chỉ và trạng thái.
class ProfileHeader extends StatelessWidget {
  final String avatarUrl;
  final String name;
  final String? age;
  final String? address;
  final Color statusColor;
  final String statusText;

  const ProfileHeader({
    super.key,
    required this.avatarUrl,
    required this.name,
    this.age,
    this.address,
    required this.statusColor,
    required this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: NetworkImage(avatarUrl),
              backgroundColor: Colors.grey.shade200,
            ),
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        if (age != null || address != null)
          Text(
            '${age ?? ''}${age != null && address != null ? ' • ' : ''}${address ?? ''}',
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            statusText.toUpperCase(),
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
          ),
        ),
      ],
    );
  }
}
