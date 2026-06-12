import 'package:flutter/material.dart';
import '../models/alert_model.dart';
import '../utils/app_state.dart';
import '../screens/alert_detail_screen.dart';
import '../screens/alerts_screen.dart';

/// Banner trạng thái an toàn tổng quan trên Home.
///
/// - Khi status = 'safe' (mọi người an toàn): banner màu xanh, không có InkWell.
/// - Khi có bất thường (warning/critical): banner màu vàng/đỏ, hiển thị TÓM TẮT
///   số lượng cảnh báo + tên người cao tuổi. Bấm vào banner để xem chi tiết:
///   - Nếu chỉ 1 alert chưa acknowledge → mở thẳng AlertDetailScreen
///   - Nếu nhiều alert → mở AlertsScreen (danh sách đầy đủ)
class StatusBanner extends StatelessWidget {
  final String status; // 'safe', 'warning', 'critical'

  const StatusBanner({super.key, required this.status});

  /// Lấy danh sách alert chưa acknowledge, sắp xếp giảm dần theo thời gian.
  static List<AlertModel> getUnackedAlerts(AppState state) {
    final list = state.alerts.where((a) => !a.acknowledged).toList()
      ..sort((a, b) => b.time.compareTo(a.time));
    return list;
  }

  void _onTap(BuildContext context) {
    final state = AppState();
    final unacked = getUnackedAlerts(state);
    if (unacked.isEmpty) return;
    if (unacked.length == 1) {
      // 1 alert → thẳng chi tiết
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AlertDetailScreen(alert: unacked.first)),
      );
    } else {
      // Nhiều alert → mở danh sách
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AlertsScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState();
    final unacked = getUnackedAlerts(state);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bannerColor = const Color(0xFF10B981);
    String bannerTitle = 'HỆ THỐNG AN TOÀN';
    String bannerDesc = 'Tất cả người thân đều đang an toàn.';
    IconData bannerIcon = Icons.check_circle_rounded;
    bool hasAbnormal = false;

    if (status == 'critical') {
      bannerColor = const Color(0xFFEF4444);
      bannerTitle = 'SOS KHẨN CẤP!';
      bannerIcon = Icons.error_rounded;
      hasAbnormal = true;
    } else if (status == 'warning') {
      bannerColor = const Color(0xFFF59E0B);
      bannerTitle = 'CẦN CHÚ Ý';
      bannerIcon = Icons.warning_rounded;
      hasAbnormal = true;
    }

    // Tóm tắt bất thường: 1 alert → tên elderly, nhiều alert → số lượng
    if (hasAbnormal && unacked.isNotEmpty) {
      if (unacked.length == 1) {
        bannerDesc = unacked.first.message;
      } else {
        // Liệt kê tên các người (tối đa 3 tên để banner không quá dài)
        final names = unacked.take(3).map((a) => a.elderlyName).toList();
        final more = unacked.length > 3 ? ' +${unacked.length - 3}' : '';
        bannerDesc = '${names.join(", ")}$more';
      }
    } else if (hasAbnormal) {
      // status = warning/critical nhưng không có alert unacked (do acknowledged gần đây)
      bannerDesc = status == 'critical'
          ? 'Có người thân cần trợ giúp ngay!'
          : 'Chỉ số sức khỏe có bất thường.';
    }

    final content = Container(
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        bannerTitle,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (hasAbnormal && unacked.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${unacked.length}',
                          style: TextStyle(
                            color: bannerColor,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  bannerDesc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (hasAbnormal && unacked.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        'BẤM ĐỂ XEM CHI TIẾT',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward, color: Colors.white, size: 14),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    // An toàn thì không bấm được; bất thường thì bấm để xem chi tiết
    if (!hasAbnormal || unacked.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: content,
      );
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _onTap(context),
        splashColor: Colors.white.withValues(alpha: 0.15),
        highlightColor: Colors.white.withValues(alpha: 0.08),
        child: content,
      ),
    );
  }
}
