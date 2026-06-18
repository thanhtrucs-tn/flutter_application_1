import 'package:flutter/material.dart';
import '../models/elderly_model.dart';
import '../utils/app_state.dart';
import '../widgets/profile_avatar.dart';

/// Màn hình BÁO ĐỘNG TỪ XA — gửi tín hiệu SOS khẩn cấp từ xa.
/// Hiển thị:
///  - Ảnh người thân
///  - Nút xác nhận khẩn cấp
///  - Cảnh báo hậu quả
///  - Animation pulse đỏ
class RemoteSosScreen extends StatefulWidget {
  final ElderlyModel elderly;
  const RemoteSosScreen({super.key, required this.elderly});

  @override
  State<RemoteSosScreen> createState() => _RemoteSosScreenState();
}

class _RemoteSosScreenState extends State<RemoteSosScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmAndSend() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.gpp_maybe, color: Colors.red),
            SizedBox(width: 8),
            Text('Xác nhận báo động từ xa'),
          ],
        ),
        content: Text(
          'Bạn sắp gửi tín hiệu SOS tới hệ thống cho ${widget.elderly.name}.\n\n'
          'Ngay lập tức:\n'
          '• Cuộc gọi tự động tới ${widget.elderly.emergencyContacts.length} số khẩn cấp\n'
          '• SMS kèm vị trí GPS hiện tại\n'
          '• Màn hình SOS khẩn cấp bật lên',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('GỬI BÁO ĐỘNG',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    // Gọi AppState để tạo alert critical (POST /api/alerts type=sos)
    final state = AppState();
    try {
      await state.triggerSOS(
        widget.elderly.id,
        'BÁO ĐỘNG TỪ XA: Người thân đang cần trợ giúp khẩn cấp!',
        'critical',
        widget.elderly.latitude,
        widget.elderly.longitude,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gửi báo động thất bại'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (!mounted) return;
    // Đóng màn hình này, quay về Home
    // Home sẽ tự push AlertDetailScreen nhờ logic auto-push
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF330000),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '🚨 BÁO ĐỘNG TỪ XA',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Ảnh + tên người thân với pulse đỏ
                    AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (context, _) {
                        return Transform.scale(
                          scale: 1.0 + _pulseCtrl.value * 0.05,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.red.withValues(
                                  alpha: 0.4 + _pulseCtrl.value * 0.6,
                                ),
                                width: 4,
                              ),
                            ),
                            child: ProfileAvatar(
                              avatarUrl: widget.elderly.avatar,
                              avatarLocalPath: widget.elderly.avatarLocalPath,
                              radius: 70,
                              backgroundColor: Colors.red.shade100,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.elderly.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.elderly.wearableDevice,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Trạng thái hiện tại
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: widget.elderly.isOffline
                            ? Colors.grey.withValues(alpha: 0.3)
                            : Colors.green.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              widget.elderly.isOffline ? Colors.grey : Colors.green,
                        ),
                      ),
                      child: Text(
                        widget.elderly.isOffline
                            ? '⚠️ THIẾT BỊ OFFLINE'
                            : '● THIẾT BỊ ONLINE',
                        style: TextStyle(
                          color: widget.elderly.isOffline
                              ? Colors.grey.shade300
                              : Colors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Cảnh báo
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red, width: 1.5),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: Colors.red, size: 36),
                          const SizedBox(height: 8),
                          const Text(
                            'BÁO ĐỘNG TỪ XA',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Dùng khi bạn nghi ngờ người thân đang gặp nguy hiểm nhưng họ chưa kịp bấm nút trên thiết bị đeo.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Danh sách liên hệ sẽ gọi
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '📞 SỐ LIÊN HỆ SẼ ĐƯỢC GỌI:',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...widget.elderly.emergencyContacts.map(
                            (phone) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.phone, color: Colors.green, size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    phone,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Nút xác nhận
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 80,
                child: ElevatedButton.icon(
                  onPressed: _confirmAndSend,
                  icon: const Icon(Icons.gpp_maybe, size: 36),
                  label: const Text(
                    'XÁC NHẬN BÁO ĐỘNG',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
