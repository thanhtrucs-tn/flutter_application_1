import 'dart:math';
import 'package:flutter/material.dart';

/// Widget hiển thị sóng điện tâm đồ ECG động mô phỏng nhịp tim
class HealthChart extends StatefulWidget {
  final int bpm;
  final bool isOffline;
  final Color waveColor;

  const HealthChart({
    super.key,
    required this.bpm,
    required this.isOffline,
    this.waveColor = const Color(0xFF10B981), // Mặc định xanh lá
  });

  @override
  State<HealthChart> createState() => _HealthChartState();
}

class _HealthChartState extends State<HealthChart> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Tạo controller chạy lặp vô hạn để vẽ chuyển động sóng
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Điều chỉnh tốc độ chạy của sóng dựa trên nhịp tim (BPM)
    if (!widget.isOffline && widget.bpm > 0) {
      // Nhịp tim càng cao thì chu kỳ hoạt họa càng nhanh
      double durationSeconds = 120.0 / widget.bpm; // 120 nhịp tại 1s/chu kỳ
      _controller.duration = Duration(milliseconds: (durationSeconds * 1000).toInt());
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    } else {
      _controller.stop();
    }

    return Container(
      height: 90,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: EcgPainter(
                progress: _controller.value,
                bpm: widget.bpm,
                isOffline: widget.isOffline,
                waveColor: widget.waveColor,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Painter vẽ sóng ECG điện tâm đồ
class EcgPainter extends CustomPainter {
  final double progress;
  final int bpm;
  final bool isOffline;
  final Color waveColor;

  EcgPainter({
    required this.progress,
    required this.bpm,
    required this.isOffline,
    required this.waveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isOffline ? Colors.grey.shade400 : waveColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Vẽ lưới nền mờ (như giấy ghi điện tâm đồ)
    final gridPaint = Paint()
      ..color = waveColor.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    double gridSpace = 15.0;
    for (double i = 0; i < size.width; i += gridSpace) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += gridSpace) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    final path = Path();
    final width = size.width;
    final height = size.height;
    final centerY = height / 2;

    if (isOffline) {
      // Trạng thái offline: Vẽ đường thẳng tắp (Flatline)
      path.moveTo(0, centerY);
      path.lineTo(width, centerY);
      // Thi thoảng có nhiễu nhẹ
      final random = Random();
      for (double x = 0; x < width; x += 10) {
        double y = centerY + (random.nextDouble() - 0.5) * 1.5;
        path.lineTo(x, y);
      }
    } else {
      // Trạng thái online: Vẽ sóng ECG chạy qua màn hình
      path.moveTo(0, centerY);
      
      for (double x = 0; x < width; x++) {
        // Tọa độ phase của sóng tại điểm x (từ 0 đến 2*pi)
        double phase = (x / width * 3) - (progress * 2 * pi);
        // Lấy phần dư để sóng lặp lại tuần hoàn
        double normX = (x / width - progress) % 1.0;
        
        // Mô phỏng các pha P-Q-R-S-T
        double yOffset = 0.0;

        // Vị trí cục bộ trong 1 chu kỳ (0.0 đến 1.0)
        double cyclePos = normX;
        
        // Đoạn sóng P (0.15 - 0.25)
        if (cyclePos >= 0.15 && cyclePos < 0.25) {
          double t = (cyclePos - 0.15) / 0.10; // 0 -> 1
          yOffset = -sin(t * pi) * 6; // Sóng P cao 6px
        }
        // Đoạn sóng QRS (Q: 0.28, R: 0.32, S: 0.36)
        else if (cyclePos >= 0.28 && cyclePos < 0.31) {
          // Q đi xuống
          double t = (cyclePos - 0.28) / 0.03;
          yOffset = t * 8; // Đi xuống 8px
        } else if (cyclePos >= 0.31 && cyclePos < 0.34) {
          // R vọt lên đỉnh cao nhất
          double t = (cyclePos - 0.31) / 0.03;
          yOffset = 8 - (t * 40); // Lên đỉnh -32px
        } else if (cyclePos >= 0.34 && cyclePos < 0.37) {
          // S xuống cực tiểu dưới baseline
          double t = (cyclePos - 0.34) / 0.03;
          yOffset = -32 + (t * 44); // Xuống tận 12px
        } else if (cyclePos >= 0.37 && cyclePos < 0.40) {
          // Trở lại baseline
          double t = (cyclePos - 0.37) / 0.03;
          yOffset = 12 - (t * 12);
        }
        // Đoạn sóng T (0.50 - 0.65)
        else if (cyclePos >= 0.50 && cyclePos < 0.65) {
          double t = (cyclePos - 0.50) / 0.15;
          yOffset = -sin(t * pi) * 10; // Sóng T cao 10px
        }

        path.lineTo(x, centerY + yOffset);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant EcgPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isOffline != isOffline ||
        oldDelegate.bpm != bpm;
  }
}
