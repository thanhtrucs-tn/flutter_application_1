import 'package:flutter/material.dart';
import '../models/elderly_model.dart';

/// Màn hình kích hoạt còi báo động 90dB trên thiết bị đeo của người thân.
/// Hiển thị:
///  - Vòng tròn pulse màu cam đập theo animation
///  - Đếm ngược thời gian còi đang kêu
///  - Nút dừng khẩn cấp
class RingingDeviceScreen extends StatefulWidget {
  final ElderlyModel elderly;
  const RingingDeviceScreen({super.key, required this.elderly});

  @override
  State<RingingDeviceScreen> createState() => _RingingDeviceScreenState();
}

class _RingingDeviceScreenState extends State<RingingDeviceScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  Duration _elapsed = Duration.zero;
  bool _isRinging = true;
  late final DateTime _startedAt;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _tick();
  }

  void _tick() async {
    while (_isRinging && mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() {
        _elapsed = DateTime.now().difference(_startedAt);
      });
    }
  }

  void _stop() {
    setState(() {
      _isRinging = false;
    });
    _pulseCtrl.stop();
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade900,
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
                    onPressed: _stop,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '🔔 CÒI BÁO ĐỘNG 90dB',
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

            // Nội dung chính
            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (context, _) {
                    final scale = 1.0 + _pulseCtrl.value * 0.3;
                    final alpha = 0.4 - _pulseCtrl.value * 0.3;
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Vòng pulse ngoài
                        Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 240,
                            height: 240,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.amber.withValues(alpha: alpha),
                            ),
                          ),
                        ),
                        // Icon chuông (overlap lên trên vòng pulse)
                        const Positioned.fill(
                          child: Icon(
                            Icons.notifications_active,
                            color: Colors.white,
                            size: 120,
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Tên người thân
                        Text(
                          'Đang kêu trên thiết bị của',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.elderly.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.elderly.wearableDevice,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Đồng hồ đếm
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'THỜI GIAN ĐANG KÊU',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  letterSpacing: 1.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _fmt(_elapsed),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            // Nút dừng
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 70,
                child: ElevatedButton.icon(
                  onPressed: _stop,
                  icon: const Icon(Icons.stop_circle, size: 32),
                  label: const Text(
                    'DỪNG CÒI BÁO ĐỘNG',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.orange.shade900,
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
