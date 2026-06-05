import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Bản đồ vệ tinh MIỄN PHÍ dùng OpenStreetMap/Esri (thay thế Google Maps)
/// - Không cần API key
/// - Hỗ trợ vệ tinh, marker, circle, polyline, zoom controls
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
  final VoidCallback? onZoneTap; // Callback khi người dùng tap vào zone map (không phải marker)

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
    this.onZoneTap,
  });

  @override
  State<CustomMap> createState() => _CustomMapState();
}

class _CustomMapState extends State<CustomMap> {
  final MapController _mapController = MapController();
  double _zoom = 16.0;
  // Tile vệ tinh miễn phí từ Esri ArcGIS World Imagery - không cần API key
  // Tham khảo: https://wiki.openstreetmap.org/wiki/Esri
  static const String _satelliteTileUrl =
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
  static const String _satelliteAttribution =
      'Tiles © Esri — Source: Esri, Maxar, Earthstar Geographics';

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Color _getStatusColor() {
    switch (widget.safetyStatus) {
      case 'critical':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  String _getStatusSnippet() {
    switch (widget.safetyStatus) {
      case 'critical':
        return 'TRẠNG THÁI: NGUY HIỂM';
      case 'warning':
        return 'TRẠNG THÁI: CẢNH BÁO';
      default:
        return 'TRẠNG THÁI: AN TOÀN';
    }
  }

  /// Reset bản đồ về tâm vị trí người cao tuổi
  void _recenterMap() {
    _mapController.move(LatLng(widget.lat, widget.lng), _zoom);
  }

  void _updateCameraPosition() {
    _mapController.move(LatLng(widget.lat, widget.lng), _zoom);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final targetPos = LatLng(widget.lat, widget.lng);
    final homePos = LatLng(widget.safeZoneLat, widget.safeZoneLng);
    final statusColor = _getStatusColor();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: widget.height,
        width: double.infinity,
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        child: Stack(
          children: [
            // Bản đồ vệ tinh từ Esri - hoàn toàn miễn phí
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: targetPos,
                initialZoom: _zoom,
                minZoom: 1,
                maxZoom: 19,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
                onTap: (tapPosition, point) {
                  // Bắt tap vào zone map (không phải marker) - mở modal fullscreen
                  if (widget.onZoneTap != null) {
                    widget.onZoneTap!();
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: _satelliteTileUrl,
                  userAgentPackageName: 'com.example.flutter_application_1',
                  maxNativeZoom: 19,
                  tileProvider: NetworkTileProvider(),
                ),
                // Vùng an toàn - vẽ trước marker để marker nổi bật
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: homePos,
                      // flutter_map dùng đơn vị mét cho radius
                      radius: widget.safeZoneRadius,
                      useRadiusInMeter: true,
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderColor: Colors.orange,
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
                // Đường dẫn SOS (nếu bật)
                if (widget.isSOSMode)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [homePos, targetPos],
                        color: Colors.red,
                        strokeWidth: 4,
                        pattern: StrokePattern.dashed(
                          segments: const [20, 10],
                        ),
                      ),
                    ],
                  ),
                // Markers cho người cao tuổi và nhà
                MarkerLayer(
                  markers: [
                    Marker(
                      point: targetPos,
                      width: 140,
                      height: 80,
                      child: _buildPinMarker(
                        color: statusColor,
                        label: widget.relativeName,
                        snippet: _getStatusSnippet(),
                      ),
                    ),
                    Marker(
                      point: homePos,
                      width: 140,
                      height: 80,
                      child: _buildPinMarker(
                        color: Colors.blue,
                        label: 'Nhà',
                        snippet: 'Vùng an toàn trung tâm',
                        showPulse: false,
                      ),
                    ),
                  ],
                ),
                // Attribution bắt buộc theo policy của Esri
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(_satelliteAttribution),
                  ],
                ),
              ],
            ),

            // Các nút điều khiển bản đồ ở góc phải
            Positioned(
              right: 12,
              bottom: 12,
              child: Column(
                children: [
                  _buildMapControl(
                    icon: Icons.my_location,
                    onPressed: _recenterMap,
                  ),
                  const SizedBox(height: 8),
                  _buildMapControl(
                    icon: Icons.add,
                    onPressed: () {
                      setState(() {
                        _zoom = (_zoom + 2).clamp(1, 19);
                      });
                      _updateCameraPosition();
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildMapControl(
                    icon: Icons.remove,
                    onPressed: () {
                      setState(() {
                        _zoom = (_zoom - 2).clamp(1, 19);
                      });
                      _updateCameraPosition();
                    },
                  ),
                ],
              ),
            ),

            // Nhãn hiển thị chế độ bản đồ
            Positioned(
              left: 12,
              top: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      (widget.isSOSMode ? Colors.red : Colors.teal).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'BẢN ĐỒ VỆ TINH (FREE)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Hint: Tap vào map để mở rộng
            if (widget.onZoneTap != null)
              Positioned(
                left: 12,
                bottom: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.open_in_full, color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'Nhấn để phóng to',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
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
    );
  }

  Widget _buildPinMarker({
    required Color color,
    required String label,
    required String snippet,
    bool showPulse = true,
  }) {
    return Tooltip(
      message: '$label — $snippet',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Vùng chứa pin (đặt phía trên nhãn tên, neo giữa theo chiều ngang)
          SizedBox(
            width: 50,
            height: 50,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Vòng tròn pulse cho vị trí người cao tuổi
                if (showPulse)
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                  ),
                // Pin chính
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 16),
                ),
              ],
            ),
          ),
          // Nhãn tên hiển thị bên dưới pin (giống Google Maps)
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            constraints: const BoxConstraints(maxWidth: 130),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapControl({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
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
        color: isDark ? Colors.white : Colors.black.withValues(alpha: 0.85),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }
}
