import 'dart:math';
import 'package:flutter/material.dart';
import '../models/elderly_model.dart';

/// Màn hình nghe âm thanh môi trường xung quanh thiết bị đeo (mô phỏng).
/// Hiển thị:
///  - Animation sóng âm thanh
///  - VU meter (thước đo cường độ âm thanh)
///  - Thông tin thiết bị & nút tắt kết nối
class AmbientListenScreen extends StatefulWidget {
  final ElderlyModel elderly;
  const AmbientListenScreen({super.key, required this.elderly});

  @override
  State<AmbientListenScreen> createState() => _AmbientListenScreenState();
}

class _AmbientListenScreenState extends State<AmbientListenScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveCtrl;
  final _random = Random();
  double _level = 0.0; // 0..1
  Duration _elapsed = Duration.zero;
  late final DateTime _startedAt;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _tickLevel();
    _tickTime();
  }

  void _tickLevel() async {
    while (mounted) {
      await Future.delayed(const Duration(milliseconds: 120));
      if (!mounted) return;
      setState(() {
        _level = 0.3 + _random.nextDouble() * 0.7;
      });
    }
  }

  void _tickTime() async {
    while (mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() {
        _elapsed = DateTime.now().difference(_startedAt);
      });
    }
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
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
      backgroundColor: const Color(0xFF0F172A),
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
                    '🎤 NGHE ÂM THANH XUNG QUANH',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon mic lớn
                    AnimatedBuilder(
                      animation: _waveCtrl,
                      builder: (context, _) {
                        return Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.teal.withValues(
                              alpha: 0.15 + _level * 0.15,
                            ),
                          ),
                          child: Icon(
                            Icons.mic,
                            size: 90,
                            color: Colors.teal.withValues(alpha: 0.9 + _level * 0.1),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    // Tên người thân
                    const Text(
                      'Đang phát âm thanh từ thiết bị của',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.elderly.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // VU meter
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'CƯỜNG ĐỘ ÂM THANH',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          letterSpacing: 1.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Stack(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 100),
                            width: MediaQuery.of(context).size.width * _level,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green,
                                  Colors.amber,
                                  if (_level > 0.8) Colors.red,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Đồng hồ
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer, color: Colors.white70, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            _fmt(_elapsed),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Mô phỏng: dữ liệu âm thanh môi trường xung quanh thiết bị ESP32',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Nút tắt
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 70,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.hearing_disabled, size: 28),
                  label: const Text(
                    'TẮT KẾT NỐI',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0F172A),
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
