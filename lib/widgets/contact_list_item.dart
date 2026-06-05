import 'package:flutter/material.dart';

/// Một dòng trong danh sách liên hệ khẩn cấp.
class ContactListItem extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final String relationship;
  final String phone;
  final VoidCallback onCallTap;

  const ContactListItem({
    super.key,
    this.avatarUrl,
    required this.name,
    required this.relationship,
    required this.phone,
    required this.onCallTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
              backgroundColor: Colors.red.shade100,
              child: avatarUrl == null ? const Icon(Icons.person, color: Colors.red) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('$relationship • $phone', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: onCallTap,
              icon: const Icon(Icons.phone, size: 16),
              label: const Text('Gọi', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
