import 'package:flutter/material.dart';

/// Banner trạng thái an toàn tổng quan trên Home.
class StatusBanner extends StatelessWidget {
  final String status; // 'safe', 'warning', 'critical'

  const StatusBanner({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bannerColor = const Color(0xFF10B981);
    String bannerTitle = 'TẤT CẢ AN TOÀN';
    String bannerDesc = 'Mọi người thân đang trong khu vực an toàn.';
    IconData bannerIcon = Icons.check_circle;

    if (status == 'critical') {
      bannerColor = const Color(0xFFEF4444);
      bannerTitle = 'SOS KHẨN CẤP!';
      bannerDesc = 'Có người thân cần hỗ trợ ngay lập tức!';
      bannerIcon = Icons.gpp_maybe;
    } else if (status == 'warning') {
      bannerColor = const Color(0xFFF59E0B);
      bannerTitle = 'CHÚ Ý CẢNH BÁO';
      bannerDesc = 'Có chỉ số sinh hiệu sức khỏe bất thường.';
      bannerIcon = Icons.warning;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: bannerColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(bannerIcon, color: Colors.white, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bannerTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  bannerDesc,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
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
