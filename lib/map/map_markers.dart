import 'dart:io';

import 'package:flutter/material.dart';

import '../models/elderly_model.dart';
import '../utils/theme.dart';

/// Màu và nhãn trạng thái dùng chung cho bản đồ.
class MapStatus {
  MapStatus._();

  static const Color offline = Color(0xFF94A3B8);

  static Color color(ElderlyModel e, {bool sos = false}) {
    if (sos) return AppTheme.statusCritical;
    if (e.isOffline) return offline;
    switch (e.status) {
      case 'critical':
        return AppTheme.statusCritical;
      case 'warning':
        return AppTheme.statusWarning;
      default:
        return AppTheme.statusSafe;
    }
  }

  /// Chữ cái đầu của tên gọi (từ cuối trong tên tiếng Việt: "Nguyễn Thị Lan" → "L").
  static String initial(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final last = parts.isEmpty ? '' : parts.last;
    return last.isEmpty ? '?' : last.characters.first.toUpperCase();
  }
}

/// Marker vị trí người thân: avatar (hoặc chữ cái đầu) trong vòng màu trạng thái,
/// có đuôi nhọn chỉ đúng vào tọa độ.
///
/// Widget cao gấp đôi phần ghim (nửa dưới để trống) để khi đặt vào [Marker] với
/// alignment mặc định (center), đầu nhọn nằm đúng trên tọa độ.
class PersonMarker extends StatelessWidget {
  final ElderlyModel elderly;
  final Color color;
  final double size;

  const PersonMarker({
    super.key,
    required this.elderly,
    required this.color,
    this.size = 48,
  });

  static const double tailHeight = 9;

  /// Kích thước cần khai báo cho [Marker].
  static Size markerSize(double size) => Size(size, (size + tailHeight) * 2);

  ImageProvider? _image() {
    if (elderly.avatarLocalPath.isNotEmpty) {
      final f = File(elderly.avatarLocalPath);
      if (f.existsSync()) return FileImage(f);
    }
    if (elderly.avatar.isNotEmpty) return NetworkImage(elderly.avatar);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final offline = elderly.isOffline;
    final image = _image();
    final inner = size - 6;

    Widget avatar = Container(
      width: inner,
      height: inner,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: offline ? const Color(0xFFF1F5F9) : const Color(0xFFF1F7F5),
        image: image != null
            ? DecorationImage(image: image, fit: BoxFit.cover, onError: (_, __) {})
            : null,
      ),
      alignment: Alignment.center,
      child: image == null
          ? Text(
              MapStatus.initial(elderly.name),
              style: TextStyle(
                fontSize: size * 0.38,
                fontWeight: FontWeight.w600,
                color: offline ? const Color(0xFF64748B) : AppTheme.primaryTeal,
              ),
            )
          : null,
    );
    if (offline && image != null) {
      // Ảnh chuyển xám khi mất kết nối để không bị hiểu là vị trí đang sống.
      avatar = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: avatar,
      );
    }

    final pin = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size,
              height: size,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: const [
                  BoxShadow(color: Color(0x40000000), blurRadius: 8, offset: Offset(0, 3)),
                ],
              ),
              child: avatar,
            ),
            if (offline)
              Positioned(
                right: -3,
                top: -3,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF475569),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.close_rounded, size: 10, color: Colors.white),
                ),
              ),
          ],
        ),
        CustomPaint(
          size: const Size(14, tailHeight),
          painter: _TailPainter(color),
        ),
      ],
    );

    return SizedBox(
      width: size,
      height: (size + tailHeight) * 2,
      child: Column(
        children: [pin, SizedBox(height: size + tailHeight)],
      ),
    );
  }
}

class _TailPainter extends CustomPainter {
  final Color color;
  _TailPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TailPainter old) => old.color != color;
}

/// Marker nhà: ô vuông trắng có biểu tượng nhà + nhãn "Nhà". Tâm ô nằm đúng tọa độ.
class HomeMarker extends StatelessWidget {
  final String label;
  final bool showLabel;

  const HomeMarker({super.key, required this.label, this.showLabel = true});

  static const Size markerSize = Size(64, 84);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: markerSize.width,
      height: markerSize.height,
      child: Column(
        children: [
          // Chừa khoảng phía trên bằng phần nhãn bên dưới để tâm ô nằm giữa marker.
          const SizedBox(height: 26),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(9),
              boxShadow: const [
                BoxShadow(color: Color(0x47000000), blurRadius: 4, offset: Offset(0, 1)),
              ],
            ),
            child: const Icon(Icons.home_rounded, size: 20, color: AppTheme.primaryTeal),
          ),
          if (showLabel) ...[
            const SizedBox(height: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryTeal,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
