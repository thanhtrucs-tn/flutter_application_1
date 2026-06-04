import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Bản đồ vệ tinh thực tế sử dụng Google Maps với chế độ vệ tinh
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

class _CustomMapState extends State<CustomMap> {
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  final Set<Circle> _circles = {};
  final Set<Polyline> _polylines = {};

  // Trạng thái thu phóng & di chuyển bản đồ
  double _zoom = 15.0; // Zoom level mặc định cho bản đồ vệ tinh
  LatLng _mapCenter = const LatLng(0, 0);
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _mapCenter = LatLng(widget.lat, widget.lng);
    _updateMarkersAndCircles();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _updateMarkersAndCircles() {
    // Xóa markers và circles cũ
    _markers.clear();
    _circles.clear();
    _polylines.clear();

    // Thêm marker cho vị trí người cao tuổi
    final targetPosition = LatLng(widget.lat, widget.lng);
    _markers.add(
      Marker(
        markerId: const MarkerId('target'),
        position: targetPosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          widget.safetyStatus == 'critical'
              ? BitmapDescriptor.hueRed
              : (widget.safetyStatus == 'warning'
                  ? BitmapDescriptor.hueOrange
                  : BitmapDescriptor.hueGreen),
        ),
        infoWindow: InfoWindow(
          title: widget.relativeName,
          snippet: widget.safetyStatus == 'critical'
              ? 'TRẠNG THÁI: NGUY HIỂM'
              : (widget.safetyStatus == 'warning'
                  ? 'TRẠNG THÁI: CẢNH BÁO'
                  : 'TRẠNG THÁI: AN TOÀN'),
        ),
      ),
    );

    // Thêm marker cho vị trí nhà (vùng an toàn trung tâm)
    final homePosition = LatLng(widget.safeZoneLat, widget.safeZoneLng);
    _markers.add(
      Marker(
        markerId: const MarkerId('home'),
        position: homePosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(
          title: 'Nhà',
          snippet: 'Vùng an toàn trung tâm',
        ),
      ),
    );

    // Vẽ círculo vùng an toàn
    _circles.add(
      Circle(
        circleId: const CircleId('safe_zone'),
        center: homePosition,
        radius: widget.safeZoneRadius,
        fillColor: Colors.orange.withOpacity(0.2),
        strokeColor: Colors.orange,
        strokeWidth: 2,
      ),
    );

    // Nếu ở chế độ SOS, vẽ đường dẫn đường từ nhà tới người cao tuổi
    if (widget.isSOSMode) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('sos_route'),
          color: Colors.red,
          width: 5,
          points: [
            homePosition,
            targetPosition,
          ],
          // Thêm hiệu ứng đứt đoạn cho SOS
          patterns: [
            PatternItem.dash(20),
            PatternItem.gap(10),
          ],
        ),
      );
    }
  }

  /// Reset bản đồ về tâm vị trí người cao tuổi
  void _recenterMap() {
    if (_mapReady) {
      _mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(widget.lat, widget.lng),
            zoom: _zoom,
          ),
        ),
      );
    }
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
            // Bản đồ vệ tinh thực tế từ Google Maps
            _mapReady
                ? GoogleMap(
                    onMapCreated: (controller) {
                      _mapController = controller;
                      _mapReady = true;
                    },
                    initialCameraPosition: CameraPosition(
                      target: _mapCenter,
                      zoom: _zoom,
                    ),
                    mapType: MapType.satellite, // SỬ DỤNG CHẾ ĐỘ VỆ TINH
                    myLocationEnabled: false,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    compassEnabled: true,
                    markers: _markers,
                    circles: _circles,
                    polylines: _polylines,
                    onTap: (_) {
                      // Tắt thông tin chi tiết khi tapping trên bản đồ
                    },
                  )
                : const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
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
                        _zoom = (_zoom + 2).clamp(0, 20);
                        _updateCameraPosition();
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  // Nút Zoom Out
                  _buildMapControl(
                    icon: Icons.remove,
                    onPressed: () {
                      setState(() {
                        _zoom = (_zoom - 2).clamp(0, 20);
                        _updateCameraPosition();
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
                  widget.isSOSMode ? 'SOS NAVIGATION' : 'BẢN ĐỒ VỆ TINH',
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

  void _updateCameraPosition() {
    if (_mapReady) {
      _mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(widget.lat, widget.lng),
            zoom: _zoom,
          ),
        ),
      );
    }
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