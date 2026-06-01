import 'dart:math';
import 'package:flutter/material.dart';

/// Bản đồ mô phỏng Google Maps tương tác cao (Zoom/Pan/Vẽ Vùng an toàn/Dẫn đường SOS)
class CustomMap extends StatefulWidget {
  final double lat;
  final double lng;
  final double safeZoneLat;
  final double safeZoneLng;
  final double safeZoneRadius; // Bán kính vùng an toàn (mét)
  final String safetyStatus; // 'safe', 'warning', 'critical'
  final bool isSOSMode; // Chế độ dẫn đường cứu hộ khẩn cấp
  final double height;
  final String relativeName;

  const CustomMap({
    super.key,
    required this.lat,
    required this.lng,
    required this.safeZoneLat,
    required this.safeZoneLng,
    required this.safeZoneRadius,
    required this.safetyStatus,
    this.isSOSMode = false,
    this.height = 250.0,
    required this.relativeName,
  });

  @override
  State<CustomMap> createState() => _CustomMapState();
}

class _CustomMapState extends State<CustomMap> with SingleTickerProviderStateMixin {
  // Trạng thái thu phóng & di chuyển bản đồ
  double _zoom = 1.0;
  Offset _panOffset = Offset.zero;
  
  // Hỗ trợ lưu trữ tạm thời khi đang vuốt màn hình
  late Offset _startPanOffset;
  late double _startZoom;

  // Animation cho vòng tròn SOS nhấp nháy
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// Reset bản đồ về tâm vị trí người cao tuổi
  void _recenterMap() {
    setState(() {
      _zoom = 1.0;
      _panOffset = Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: widget.height,
        width: double.infinity,
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        child: Stack(
          children: [
            // Lớp vẽ bản đồ vector mô phỏng bằng CustomPaint
            GestureDetector(
              onScaleStart: (details) {
                _startPanOffset = _panOffset;
                _startZoom = _zoom;
              },
              onScaleUpdate: (details) {
                setState(() {
                  // Giới hạn zoom từ 0.5x tới 4.0x
                  _zoom = (_startZoom * details.scale).clamp(0.5, 4.0);
                  // Di chuyển bản đồ
                  _panOffset = _startPanOffset + details.focalPointDelta;
                });
              },
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size(double.infinity, widget.height),
                    painter: MapPainter(
                      zoom: _zoom,
                      panOffset: _panOffset,
                      targetLat: widget.lat,
                      targetLng: widget.lng,
                      homeLat: widget.safeZoneLat,
                      homeLng: widget.safeZoneLng,
                      radiusMeters: widget.safeZoneRadius,
                      status: widget.safetyStatus,
                      isSOSMode: widget.isSOSMode,
                      pulseValue: _pulseController.value,
                      isDarkMode: isDark,
                      name: widget.relativeName,
                    ),
                  );
                },
              ),
            ),
            
            // Các nút điều khiển bản đồ ở góc phải
            Positioned(
              right: 12,
              bottom: 12,
              child: Column(
                children: [
                  // Nút Reset/Recenter
                  _buildMapControl(
                    icon: Icons.my_location,
                    onPressed: _recenterMap,
                  ),
                  const SizedBox(height: 8),
                  // Nút Zoom In
                  _buildMapControl(
                    icon: Icons.add,
                    onPressed: () {
                      setState(() {
                        _zoom = (_zoom * 1.2).clamp(0.5, 4.0);
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  // Nút Zoom Out
                  _buildMapControl(
                    icon: Icons.remove,
                    onPressed: () {
                      setState(() {
                        _zoom = (_zoom / 1.2).clamp(0.5, 4.0);
                      });
                    },
                  ),
                ],
              ),
            ),
            
            // Nhãn hiển thị bản đồ định vị
            Positioned(
              left: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (widget.isSOSMode ? Colors.red : Colors.teal).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.isSOSMode ? 'SOS NAVIGATION' : 'GOOGLE MAPS SIMULATOR',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapControl({required IconData icon, required VoidCallback onPressed}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 20),
        color: isDark ? Colors.white : Colors.black.withOpacity(0.85),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }
}

/// Painter vẽ đường sá, sông ngòi, ranh giới vùng an toàn
class MapPainter extends CustomPainter {
  final double zoom;
  final Offset panOffset;
  final double targetLat;
  final double targetLng;
  final double homeLat;
  final double homeLng;
  final double radiusMeters;
  final String status;
  final bool isSOSMode;
  final double pulseValue;
  final bool isDarkMode;
  final String name;

  MapPainter({
    required this.zoom,
    required this.panOffset,
    required this.targetLat,
    required this.targetLng,
    required this.homeLat,
    required this.homeLng,
    required this.radiusMeters,
    required this.status,
    required this.isSOSMode,
    required this.pulseValue,
    required this.isDarkMode,
    required this.name,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Định nghĩa màu sắc bản đồ dựa theo theme sáng tối
    final bgColor = isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final waterColor = isDarkMode ? const Color(0xFF1D4ED8).withOpacity(0.2) : const Color(0xFF93C5FD);
    final parkColor = isDarkMode ? const Color(0xFF065F46).withOpacity(0.15) : const Color(0xFFA7F3D0);
    final roadColor = isDarkMode ? const Color(0xFF334155) : Colors.white;
    final roadBorderColor = isDarkMode ? const Color(0xFF475569) : const Color(0xFFCBD5E1);

    // Tô nền bản đồ
    final bgPaint = Paint()..color = bgColor;
    canvas.drawRect(Offset.zero & size, bgPaint);

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Quy đổi tọa độ GPS sang điểm vẽ cục bộ
    // Lấy Home làm điểm gốc (0,0) ở giữa bản đồ
    // Trục Y của bản đồ ngược với Vĩ độ GPS (Vĩ độ tăng -> Lên trên)
    // Tỷ lệ quy đổi: 1 độ Lat/Lng = 250000 pixels tại zoom = 1
    const scale = 250000.0;
    
    // Tọa độ vẽ của Home Base
    double homeDrawX = centerX + panOffset.dx;
    double homeDrawY = centerY + panOffset.dy;

    // Tọa độ vẽ của người cao tuổi (Target)
    double targetDiffLat = targetLat - homeLat;
    double targetDiffLng = targetLng - homeLng;
    
    double targetDrawX = homeDrawX + (targetDiffLng * scale * zoom);
    double targetDrawY = homeDrawY - (targetDiffLat * scale * zoom);

    // Bán kính vùng an toàn tính bằng pixel (1m ~ 0.25 pixels tại zoom 1)
    double drawRadius = radiusMeters * 0.25 * zoom;

    // 2. Vẽ Sông Ngòi giả lập
    final waterPaint = Paint()
      ..color = waterColor
      ..style = PaintingStyle.fill;
    final riverPath = Path();
    riverPath.moveTo(0, centerY + 80 * zoom + panOffset.dy);
    riverPath.quadraticBezierTo(
      centerX + panOffset.dx, 
      centerY - 40 * zoom + panOffset.dy, 
      size.width, 
      centerY + 50 * zoom + panOffset.dy
    );
    riverPath.lineTo(size.width, size.height);
    riverPath.lineTo(0, size.height);
    riverPath.close();
    canvas.drawPath(riverPath, waterPaint);

    // 3. Vẽ Công viên giả lập
    final parkPaint = Paint()..color = parkColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(homeDrawX - 100 * zoom, homeDrawY - 60 * zoom),
          width: 140 * zoom,
          height: 100 * zoom,
        ),
        Radius.circular(12 * zoom),
      ),
      parkPaint,
    );

    // 4. Vẽ Mạng lưới đường xá
    final roadPaint = Paint()
      ..color = roadColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14 * zoom
      ..strokeCap = StrokeCap.round;

    final roadBorderPaint = Paint()
      ..color = roadBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18 * zoom
      ..strokeCap = StrokeCap.round;

    void drawRoad(Offset p1, Offset p2) {
      canvas.drawLine(p1, p2, roadBorderPaint);
      canvas.drawLine(p1, p2, roadPaint);
    }

    // Vẽ 1 số đường lớn xung quanh
    // Đường ngang chính (Đường 3 Tháng 2)
    drawRoad(
      Offset(0, homeDrawY), 
      Offset(size.width, homeDrawY)
    );
    // Đường dọc chính (Đường Lý Thường Kiệt)
    drawRoad(
      Offset(homeDrawX, 0), 
      Offset(homeDrawX, size.height)
    );
    // Đường chéo phụ (Tô Hiến Thành)
    drawRoad(
      Offset(0, homeDrawY - 80 * zoom), 
      Offset(size.width, homeDrawY + 80 * zoom)
    );

    // Ghi tên đường (chỉ viết khi zoom lớn)
    if (zoom > 0.8) {
      final textPainter = TextPainter(
        textDirection: TextDirection.ltr,
      );
      
      void drawText(String text, Offset pos, double angle) {
        textPainter.text = TextSpan(
          text: text,
          style: TextStyle(
            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            fontSize: 9 * zoom,
            fontWeight: FontWeight.bold,
          ),
        );
        textPainter.layout();
        
        canvas.save();
        canvas.translate(pos.dx, pos.dy);
        canvas.rotate(angle);
        textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
        canvas.restore();
      }

      drawText('LÝ THƯỜNG KIỆT', Offset(homeDrawX + 10 * zoom, centerY + panOffset.dy - 30 * zoom), pi / 2);
      drawText('ĐƯỜNG 3 THÁNG 2', Offset(centerX + panOffset.dx + 40 * zoom, homeDrawY - 10 * zoom), 0);
    }

    // 5. Vẽ Ranh giới Vùng an toàn (Geofence Circle)
    final zonePaint = Paint()
      ..color = Colors.teal.withOpacity(0.12)
      ..style = PaintingStyle.fill;
    final zoneBorderPaint = Paint()
      ..color = Colors.teal.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(Offset(homeDrawX, homeDrawY), drawRadius, zonePaint);
    canvas.drawCircle(Offset(homeDrawX, homeDrawY), drawRadius, zoneBorderPaint);

    // 6. Vẽ Nhà ở (Home base)
    final homePaint = Paint()
      ..color = Colors.teal.shade700
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(homeDrawX, homeDrawY), 10 * zoom, homePaint);
    
    // Vẽ ký hiệu ngôi nhà nhỏ
    final homeIconPainter = TextPainter(
      text: TextSpan(
        text: '🏠',
        style: TextStyle(fontSize: 10 * zoom),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    homeIconPainter.paint(canvas, Offset(homeDrawX - homeIconPainter.width / 2, homeDrawY - homeIconPainter.height / 2));

    // 7. Vẽ Dẫn đường khẩn cấp (Nếu trong chế độ SOS Mode)
    if (isSOSMode) {
      final routePaint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.round;

      // Vẽ đường gấp khúc chỉ đường (mô phỏng đường giao thông từ nhà đến người thân)
      final routePath = Path();
      routePath.moveTo(homeDrawX, homeDrawY);
      routePath.lineTo(targetDrawX, homeDrawY); // Chạy dọc đường ngang
      routePath.lineTo(targetDrawX, targetDrawY); // Rẽ sang đường dọc tới đích
      
      // Vẽ hiệu ứng đứt đoạn chạy động bằng nhấp nháy mờ
      if (pulseValue > 0.4) {
        canvas.drawPath(routePath, routePaint);
      } else {
        canvas.drawPath(
          routePath, 
          routePaint..color = Colors.red.withOpacity(0.4)
        );
      }

      // Vẽ mũi tên điều hướng
      final arrowPaint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset((homeDrawX + targetDrawX) / 2, homeDrawY), 4, arrowPaint);
      canvas.drawCircle(Offset(targetDrawX, (homeDrawY + targetDrawY) / 2), 4, arrowPaint);
    }

    // 8. Vẽ Người Cao Tuổi Marker (Target)
    Color statusColor = Colors.teal;
    if (status == 'warning') statusColor = Colors.orange;
    if (status == 'critical') statusColor = Colors.red;

    // Vòng tròn định vị nhấp nháy phát xạ (Radar pulse)
    final radarPaint = Paint()
      ..color = statusColor.withOpacity(1.0 - pulseValue)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(targetDrawX, targetDrawY), (12 + pulseValue * 16) * zoom, radarPaint);

    // Vòng tròn pin lõi
    final pinCorePaint = Paint()
      ..color = statusColor
      ..style = PaintingStyle.fill;
    final pinBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(Offset(targetDrawX, targetDrawY), 8 * zoom, pinCorePaint);
    canvas.drawCircle(Offset(targetDrawX, targetDrawY), 8 * zoom, pinBorderPaint);

    // Ký hiệu Marker Pin
    final markerTextPainter = TextPainter(
      text: TextSpan(
        text: status == 'critical' ? '⚠️' : '📍',
        style: TextStyle(fontSize: 12 * zoom),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    markerTextPainter.paint(
      canvas, 
      Offset(targetDrawX - markerTextPainter.width / 2, targetDrawY - markerTextPainter.height - 2 * zoom)
    );

    // Nhãn Tên Người Cao Tuổi hiển thị mờ trên Marker
    final namePainter = TextPainter(
      text: TextSpan(
        text: name,
        style: TextStyle(
          color: Colors.white,
          fontSize: 10 * zoom,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.black.withOpacity(0.75),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    namePainter.paint(
      canvas, 
      Offset(targetDrawX - namePainter.width / 2, targetDrawY + 12 * zoom)
    );
  }

  @override
  bool shouldRepaint(covariant MapPainter oldDelegate) {
    return oldDelegate.zoom != zoom ||
        oldDelegate.panOffset != panOffset ||
        oldDelegate.targetLat != targetLat ||
        oldDelegate.targetLng != targetLng ||
        oldDelegate.status != status ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.isSOSMode != isSOSMode ||
        oldDelegate.isDarkMode != isDarkMode;
  }
}
