import 'package:flutter/material.dart';

/// Card chứa một nhóm cài đặt với tiêu đề tùy chọn.
class SettingsSectionCard extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const SettingsSectionCard({super.key, this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                title!.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE53935),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ...children,
        ],
      ),
    );
  }
}
