import 'package:flutter/material.dart';

/// Banner trạng thái an toàn tổng quan trên Home.
class StatusBanner extends StatelessWidget {
  final String status; // 'safe', 'warning', 'critical'

  const StatusBanner({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bannerColor = const Color(0xFF10B981);
    String bannerTitle = 'HỆ THỐNG AN TOÀN';
    String bannerDesc = 'Tất cả người thân đều đang an toàn.';
    IconData bannerIcon = Icons.check_circle_rounded;

    if (status == 'critical') {
      bannerColor = const Color(0xFFEF4444);
      bannerTitle = 'SOS KHẨN CẤP!';
      bannerDesc = 'Có người thân cần trợ giúp ngay!';
      bannerIcon = Icons.error_rounded;
    } else if (status == 'warning') {
      bannerColor = const Color(0xFFF59E0B);
      bannerTitle = 'CẦN CHÚ Ý';
      bannerDesc = 'Chỉ số sức khỏe có bất thường.';
      bannerIcon = Icons.warning_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: bannerColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(bannerIcon, color: Colors.white, size: 44),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bannerTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  bannerDesc,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
