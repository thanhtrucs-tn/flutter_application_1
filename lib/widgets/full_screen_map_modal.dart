import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/address_model.dart';

/// Modal hiển thị bản đồ full-screen với khả năng zoom in/out trực quan.
///
/// Hỗ trợ:
/// - Pinch-to-zoom (mặc định của flutter_map)
/// - Double-tap-to-zoom
/// - Nút + / - phóng to / thu nhỏ
/// - Nút recenter
/// - Hiển thị địa chỉ chi tiết ở panel trên cùng
class FullScreenMapModal extends StatefulWidget {
  final double lat;
  final double lng;
  final double safeZoneLat;
  final double safeZoneLng;
  final double safeZoneRadius;
  final String relativeName;
  final String safetyStatus;
  final Address? address;

  const FullScreenMapModal({
    super.key,
    required this.lat,
    required this.lng,
    required this.safeZoneLat,
    required this.safeZoneLng,
    required this.safeZoneRadius,
    required this.relativeName,
    required this.safetyStatus,
    this.address,
  });

  /// Mở modal dạng bottom sheet full-screen
  static Future<void> show({
    required BuildContext context,
    required double lat,
    required double lng,
    required double safeZoneLat,
    required double safeZoneLng,
    required double safeZoneRadius,
    required String relativeName,
    required String safetyStatus,
    Address? address,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      enableDrag: true,
      isDismissible: true,
      useSafeArea: true,
      builder: (ctx) => FullScreenMapModal(
        lat: lat,
        lng: lng,
        safeZoneLat: safeZoneLat,
        safeZoneLng: safeZoneLng,
        safeZoneRadius: safeZoneRadius,
        relativeName: relativeName,
        safetyStatus: safetyStatus,
        address: address,
      ),
    );
  }

  @override
  State<FullScreenMapModal> createState() => _FullScreenMapModalState();
}

class _FullScreenMapModalState extends State<FullScreenMapModal> {
  late final MapController _mapController;
  double _zoom = 17.0;
  static const double _minZoom = 3;
  static const double _maxZoom = 19;
  static const String _tileUrl =
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
  static const String _tileAttribution =
      'Tiles © Esri — Source: Esri, Maxar, Earthstar Geographics';

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Color _statusColor() {
    switch (widget.safetyStatus) {
      case 'critical':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  void _zoomIn() {
    setState(() {
      _zoom = (_zoom + 1).clamp(_minZoom, _maxZoom);
    });
    _mapController.move(
      LatLng(widget.lat, widget.lng),
      _zoom,
    );
  }

  void _zoomOut() {
    setState(() {
      _zoom = (_zoom - 1).clamp(_minZoom, _maxZoom);
    });
    _mapController.move(
      LatLng(widget.lat, widget.lng),
      _zoom,
    );
  }

  void _recenter() {
    _mapController.move(
      LatLng(widget.lat, widget.lng),
      _zoom,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final target = LatLng(widget.lat, widget.lng);
    final home = LatLng(widget.safeZoneLat, widget.safeZoneLng);
    final statusColor = _statusColor();
    final screenH = MediaQuery.of(context).size.height;

    return DraggableScrollableSheet(
      initialChildSize: 1.0,
      minChildSize: 0.5,
      maxChildSize: 1.0,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          height: screenH,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              _buildDragHandle(isDark),
              // Top panel: address
              _buildTopPanel(isDark),
              // Map
              Expanded(
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: target,
                        initialZoom: _zoom,
                        minZoom: _minZoom,
                        maxZoom: _maxZoom,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: _tileUrl,
                          userAgentPackageName:
                              'com.example.flutter_application_1',
                          maxNativeZoom: 19,
                          tileProvider: NetworkTileProvider(),
                        ),
                        // Vùng an toàn
                        CircleLayer(
                          circles: [
                            CircleMarker(
                              point: home,
                              radius: widget.safeZoneRadius,
                              useRadiusInMeter: true,
                              color: Colors.orange.withValues(alpha: 0.2),
                              borderColor: Colors.orange,
                              borderStrokeWidth: 2,
                            ),
                          ],
                        ),
                        // Markers
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: target,
                              width: 60,
                              height: 60,
                              child: _buildPin(
                                color: statusColor,
                                showPulse: true,
                              ),
                            ),
                            Marker(
                              point: home,
                              width: 50,
                              height: 50,
                              child: _buildPin(
                                color: Colors.blue,
                                showPulse: false,
                              ),
                            ),
                          ],
                        ),
                        RichAttributionWidget(
                          attributions: [
                            TextSourceAttribution(_tileAttribution),
                          ],
                        ),
                      ],
                    ),

                    // Map controls (góc phải)
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Column(
                        children: [
                          _buildCtrl(
                            icon: Icons.add,
                            onPressed: _zoomIn,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 8),
                          _buildCtrl(
                            icon: Icons.remove,
                            onPressed: _zoomOut,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 8),
                          _buildCtrl(
                            icon: Icons.my_location,
                            onPressed: _recenter,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),

                    // Zoom indicator (góc trái dưới)
                    Positioned(
                      left: 12,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.black : Colors.white)
                              .withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.zoom_in,
                              size: 14,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Zoom: ${_zoom.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
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
        );
      },
    );
  }

  Widget _buildDragHandle(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: isDark ? Colors.white24 : Colors.black26,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildTopPanel(bool isDark) {
    final address = widget.address;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _statusColor(),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.relativeName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                color: isDark ? Colors.white70 : Colors.black54,
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Đóng',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (address != null && address.displayName.isNotEmpty)
            ..._buildAddressLines(address, isDark)
          else
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
                const SizedBox(width: 4),
                Text(
                  'Chưa có thông tin địa chỉ chi tiết',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 4),
          Text(
            'Tọa độ: ${widget.lat.toStringAsFixed(6)}, ${widget.lng.toStringAsFixed(6)}',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white38 : Colors.black45,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAddressLines(Address address, bool isDark) {
    final widgets = <Widget>[];
    if (address.displayName.isNotEmpty) {
      widgets.add(
        Text(
          address.displayName,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }
    final details = address.detailedLines;
    if (details.isNotEmpty) {
      widgets.add(const SizedBox(height: 4));
      widgets.add(
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: details
              .map(
                (line) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${line.label}: ${line.value}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      );
    }
    return widgets;
  }

  Widget _buildPin({
    required Color color,
    required bool showPulse,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (showPulse)
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
          ),
        Container(
          width: 40,
          height: 40,
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
          child: const Icon(Icons.person, color: Colors.white, size: 22),
        ),
      ],
    );
  }

  Widget _buildCtrl({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isDark,
  }) {
    return Material(
      color: isDark ? Colors.grey.shade800 : Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 4,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 24,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}
