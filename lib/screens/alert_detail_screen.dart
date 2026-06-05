import 'package:flutter/material.dart';
import '../models/alert_model.dart';
import '../utils/app_state.dart';
import '../utils/localization.dart';
import '../widgets/big_button.dart';
import '../widgets/custom_map.dart';

/// Màn hình thông báo đẩy khẩn cấp khi xảy ra sự cố SOS
class AlertDetailScreen extends StatefulWidget {
  final AlertModel alert;

  const AlertDetailScreen({
    super.key,
    required this.alert,
  });

  @override
  State<AlertDetailScreen> createState() => _AlertDetailScreenState();
}

class _AlertDetailScreenState extends State<AlertDetailScreen> with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;
  bool _soundMuted = false;

  @override
  void initState() {
    super.initState();
    // Tạo hiệu ứng nhấp nháy đỏ nền
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  /// Xử lý thoát màn hình: xác nhận alert + pop về home.
  /// Dùng cho cả nút X, nút "Đã xử lý" và phím Back hệ thống.
  void _confirmAndClose() {
    AppState().acknowledgeAlert(widget.alert.id);
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  /// Gọi điện thoại khẩn cấp (Mô phỏng gọi thoại trên desktop/simulators)
  void _makeCall(String phoneNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.phone, color: Colors.green),
            const SizedBox(width: 8),
            const Text('Cuộc gọi SOS Care'),
          ],
        ),
        content: Text('Hệ thống đang kết nối cuộc gọi thoại khẩn cấp tới số:\n$phoneNumber'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState();
    final relative = state.relatives.firstWhere((e) => e.id == widget.alert.elderlyId);

    // PopScope: cho phép bấm Back hệ thống (Android/Windows desktop) để thoát.
    // Trên desktop không có nút back vật lý, nên nếu chỉ dựa vào nút "Đã xử lý"
    // ở dưới cùng thì user không thấy được khi chưa scroll.
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // Đảm bảo acknowledge để không bị re-push ngay sau khi back
          state.acknowledgeAlert(widget.alert.id);
        }
      },
      child: Scaffold(
        body: AnimatedBuilder(
        animation: _blinkController,
        builder: (context, child) {
          // Nhấp nháy màu đỏ mờ/rực rỡ làm màu nền khẩn cấp
          final pulseColor = Color.lerp(
            Colors.red.shade900.withOpacity(0.95),
            Colors.red.shade600,
            _blinkController.value,
          );

          return Container(
            color: pulseColor,
            child: child,
          );
        },
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header khẩn cấp
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 30),
                        const SizedBox(width: 8),
                        Text(
                          Localization.translate('statusCriticalText').toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Nút tắt tiếng còi báo động mô phỏng
                        IconButton(
                          icon: Icon(
                            _soundMuted ? Icons.volume_off : Icons.volume_up,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: () {
                            setState(() {
                              _soundMuted = !_soundMuted;
                            });
                          },
                        ),
                        // NÚT ĐÓNG (X) — luôn hiển thị ở góc trên cùng để user
                        // có thể thoát ngay cả khi không scroll xuống thấy được nút "Đã xử lý".
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 28),
                          tooltip: 'Đóng',
                          onPressed: _confirmAndClose,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Nội dung cảnh báo chính
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              '⚠️ CẢNH BÁO SỰ CỐ KHẨN CẤP ⚠️',
                              style: TextStyle(
                                color: Colors.yellow,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.alert.message,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            const Divider(color: Colors.white24),
                            const SizedBox(height: 8),

                            // Các dòng chi tiết
                            _buildInfoRow(Icons.person, 'Người thân', widget.alert.elderlyName),
                            _buildInfoRow(Icons.access_time, 'Thời gian', '${widget.alert.time.hour}:${widget.alert.time.minute.toString().padLeft(2, '0')} (${widget.alert.time.day}/${widget.alert.time.month})'),
                            _buildInfoRow(Icons.location_on, 'Vị trí sự cố', '${widget.alert.latitude.toStringAsFixed(5)}, ${widget.alert.longitude.toStringAsFixed(5)}'),
                            _buildInfoRow(Icons.watch, 'Thiết bị đeo', relative.wearableDevice),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Bản đồ dẫn đường khẩn cấp
                      const Text(
                        '🗺️ BẢN ĐỒ CHỈ ĐƯỜNG CỨU HỘ',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      CustomMap(
                        lat: widget.alert.latitude,
                        lng: widget.alert.longitude,
                        safeZoneLat: relative.safeZoneLat,
                        safeZoneLng: relative.safeZoneLng,
                        safeZoneRadius: relative.safeZoneRadius,
                        safetyStatus: 'critical',
                        isSOSMode: true,
                        height: 280,
                        relativeName: widget.alert.elderlyName,
                      ),
                      const SizedBox(height: 20),

                      // Thao tác khẩn cấp
                      Row(
                        children: [
                          // Nút gọi điện người thân
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _makeCall(relative.emergencyContacts.first),
                              icon: const Icon(Icons.phone),
                              label: const Text('Gọi người thân'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Nút gọi cứu hộ / số liên hệ khác
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _makeCall(relative.emergencyContacts.length > 1 ? relative.emergencyContacts[1] : '115'),
                              icon: const Icon(Icons.emergency_share),
                              label: const Text('Gọi cứu hộ (115)'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // NÚT XÁC NHẬN ĐÃ XỬ LÝ — cố định ở đáy màn hình, luôn hiển thị
              // để user không cần scroll mới thấy được.
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.25),
                  border: const Border(top: BorderSide(color: Colors.white24)),
                ),
                child: BigButton(
                  label: Localization.translate('confirmAlert'),
                  icon: Icons.check_circle_outline,
                  color: Colors.white,
                  fontSize: 18,
                  iconSize: 32,
                  height: 64,
                  onPressed: _confirmAndClose,
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
