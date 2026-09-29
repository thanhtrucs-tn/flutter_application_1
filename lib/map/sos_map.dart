import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/elderly_model.dart';
import '../utils/theme.dart';
import 'danger_zone.dart';
import 'map_format.dart';
import 'map_markers.dart';
import 'map_tiles.dart';
import 'smooth_wheel_zoom.dart';

/// Bản đồ theo dõi một người thân. Dùng chung cho mọi nơi có bản đồ trong app.
///
/// - `compact: true`: bản xem trước (màn chi tiết, màn cảnh báo). Không kéo/zoom
///   được để không tranh cử chỉ cuộn với trang; màn cha tự bắt chạm để mở bản
///   đồ đầy đủ.
/// - `compact: false`: bản đồ đầy đủ. Zoom bằng ngón tay (hoặc con lăn chuột
///   trên Windows), có nút đổi lớp nền và nút về vị trí.
///
/// Camera tự bám theo vị trí mới. Người dùng kéo bản đồ thì ngừng bám; bấm nút
/// về vị trí để bám lại.
///
/// Truyền [incident] để vào chế độ SOS: marker đỏ tại vị trí sự cố, đường nét
/// đứt từ nhà tới đó và camera canh để thấy cả hai điểm.
class SosMap extends StatefulWidget {
  final ElderlyModel elderly;
  final LatLng? incident;
  final bool compact;

  /// Khoảng trên cùng dành cho thanh tiêu đề nổi của màn cha (chế độ đầy đủ).
  final double topInset;

  /// Phần đáy bản đồ bị che bởi tấm thông tin của màn cha (nút và dòng ghi
  /// nguồn được đẩy lên trên phần này).
  final double bottomInset;

  final List<DangerZone> dangerZones;

  const SosMap({
    super.key,
    required this.elderly,
    this.incident,
    this.compact = false,
    this.topInset = 16,
    this.bottomInset = 0,
    this.dangerZones = const [],
  });

  @override
  State<SosMap> createState() => _SosMapState();
}

class _SosMapState extends State<SosMap> {
  final MapController _map = MapController();
  bool _ready = false;
  bool _follow = true;

  static const LatLng _vietnamCenter = LatLng(16.0, 106.3);
  static const double _followZoom = 16.5;
  static const Color _danger = Color(0xFFDC2626);

  ElderlyModel get _e => widget.elderly;
  bool get _sos => widget.incident != null;

  LatLng? _targetOf(SosMap w) {
    if (w.incident != null) return w.incident;
    final e = w.elderly;
    return e.hasLocation ? LatLng(e.latitude, e.longitude) : null;
  }

  LatLng? _homeOf(SosMap w) =>
      w.elderly.hasHome ? LatLng(w.elderly.safeZoneLat, w.elderly.safeZoneLng) : null;

  LatLng? get _target => _targetOf(widget);
  LatLng? get _home => _homeOf(widget);
  bool get _frameBoth => _sos && _home != null && _target != null;

  CameraFit _fitBoth() => CameraFit.bounds(
        bounds: LatLngBounds.fromPoints([_home!, _target!]),
        padding: EdgeInsets.fromLTRB(
          56,
          widget.compact ? 40 : widget.topInset + 56,
          56,
          widget.compact ? 48 : widget.bottomInset + 88,
        ),
        maxZoom: 17,
      );

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SosMap old) {
    super.didUpdateWidget(old);
    final moved = _targetOf(old) != _target || _homeOf(old) != _home;
    if (moved && (_follow || widget.compact)) {
      // Không điều khiển camera giữa lúc đang build: chờ hết frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _moveCamera();
      });
    }
  }

  void _moveCamera() {
    if (!_ready) return;
    if (_frameBoth) {
      _map.fitCamera(_fitBoth());
      return;
    }
    final target = _target ?? _home;
    if (target == null) return;
    final zoom = _map.camera.zoom < 13 ? _followZoom : _map.camera.zoom;
    _map.move(target, zoom);
  }

  void _recenter() {
    setState(() => _follow = true);
    _moveCamera();
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    if (!hasGesture || widget.compact) return;
    if (_follow) setState(() => _follow = false);
  }

  @override
  Widget build(BuildContext context) {
    final target = _target;
    final home = _home;
    final statusColor = MapStatus.color(_e, sos: _sos);
    final accuracy = _e.accuracy;

    final map = FlutterMap(
      mapController: _map,
      options: MapOptions(
        initialCenter: target ?? home ?? _vietnamCenter,
        initialZoom: target != null ? _followZoom : (home != null ? 15 : 5.5),
        initialCameraFit: _frameBoth ? _fitBoth() : null,
        minZoom: 3,
        maxZoom: 19,
        backgroundColor: const Color(0xFFE8EAE4),
        interactionOptions: InteractionOptions(
          // Con lăn chuột do SmoothWheelZoom xử lý (mượt hơn nhảy từng nấc).
          flags: widget.compact
              ? InteractiveFlag.none
              : InteractiveFlag.all & ~InteractiveFlag.rotate & ~InteractiveFlag.scrollWheelZoom,
        ),
        onMapReady: () => _ready = true,
        onPositionChanged: _onPositionChanged,
      ),
      children: [
        ...MapTiles.layers(),
        if (widget.dangerZones.any((z) => !z.isCircle))
          PolygonLayer(
            polygons: [
              for (final z in widget.dangerZones)
                if (!z.isCircle)
                  Polygon(
                    points: z.polygon,
                    color: _danger.withValues(alpha: 0.18),
                    borderColor: _danger,
                    borderStrokeWidth: 2,
                  ),
            ],
          ),
        CircleLayer(
          circles: [
            for (final z in widget.dangerZones)
              if (z.isCircle)
                CircleMarker(
                  point: z.center!,
                  radius: z.radiusMeters!,
                  useRadiusInMeter: true,
                  color: _danger.withValues(alpha: 0.18),
                  borderColor: _danger,
                  borderStrokeWidth: 2,
                ),
            // Vòng sai số GPS: vị trí thật nằm đâu đó trong vòng này.
            if (target != null && !_sos && accuracy != null && accuracy > 0)
              CircleMarker(
                point: target,
                radius: accuracy,
                useRadiusInMeter: true,
                color: statusColor.withValues(alpha: 0.14),
                borderColor: statusColor.withValues(alpha: 0.45),
                borderStrokeWidth: 1,
              ),
            // Quầng đỏ quanh vị trí sự cố (theo pixel, luôn thấy rõ ở mọi mức zoom).
            if (target != null && _sos) ...[
              CircleMarker(point: target, radius: 56, color: _danger.withValues(alpha: 0.10)),
              CircleMarker(
                point: target,
                radius: 32,
                color: _danger.withValues(alpha: 0.16),
                borderColor: _danger.withValues(alpha: 0.4),
                borderStrokeWidth: 1,
              ),
            ],
          ],
        ),
        if (_frameBoth)
          PolylineLayer(
            polylines: [
              Polyline(
                points: [home!, target!],
                color: _danger,
                strokeWidth: 3.5,
                pattern: StrokePattern.dashed(segments: const [10, 8]),
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            if (!widget.compact)
              for (final z in widget.dangerZones)
                Marker(
                  point: z.labelPoint,
                  width: 180,
                  height: 30,
                  child: Center(child: _ZoneLabel(name: z.name)),
                ),
            if (home != null)
              Marker(
                point: home,
                width: HomeMarker.markerSize.width,
                height: HomeMarker.markerSize.height,
                child: HomeMarker(
                  label: MapFormat.tr('mapHome'),
                  showLabel: !widget.compact,
                ),
              ),
            if (_frameBoth && !widget.compact)
              Marker(
                point: LatLng(
                  (home!.latitude + target!.latitude) / 2,
                  (home!.longitude + target!.longitude) / 2,
                ),
                width: 96,
                height: 28,
                child: Center(child: _DistanceChip(text: MapFormat.distance(home!, target!))),
              ),
            if (target != null)
              () {
                final size = widget.compact ? 40.0 : (_sos ? 52.0 : 48.0);
                final box = PersonMarker.markerSize(size);
                return Marker(
                  point: target,
                  width: box.width,
                  height: box.height,
                  child: PersonMarker(elderly: _e, color: statusColor, size: size),
                );
              }(),
          ],
        ),
      ],
    );

    return Stack(
      children: [
        Positioned.fill(
          child: widget.compact
              ? map
              : SmoothWheelZoom(
                  controller: _map,
                  zoomAroundCenter: _follow,
                  child: map,
                ),
        ),
        if (target == null) Positioned.fill(child: _WaitingGps(name: _e.name, compact: widget.compact)),
        Positioned(
          left: 8,
          top: widget.compact ? 8 : null,
          bottom: widget.compact ? null : widget.bottomInset + 8,
          child: _Attribution(text: MapTiles.attribution()),
        ),
        if (!widget.compact) ...[
          if (target != null || home != null)
            Positioned(
              right: 16,
              bottom: widget.bottomInset + 16,
              child: _RecenterButton(
                following: _follow,
                label: MapFormat.tr(_sos ? 'mapFitAll' : 'mapBackToPerson'),
                onPressed: _recenter,
              ),
            ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------

/// Đang bám theo: nút tròn teal đặc. Đã kéo map: nút trắng có chữ để bấm bám lại.
class _RecenterButton extends StatelessWidget {
  final bool following;
  final String label;
  final VoidCallback onPressed;

  const _RecenterButton({required this.following, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    if (following) {
      return Tooltip(
        message: MapFormat.tr('mapFollowing'),
        child: Material(
          color: AppTheme.primaryTeal,
          shape: const CircleBorder(),
          elevation: 3,
          shadowColor: Colors.black45,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: const SizedBox(
              width: 48,
              height: 48,
              child: Icon(Icons.my_location, color: Colors.white, size: 22),
            ),
          ),
        ),
      );
    }
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      elevation: 3,
      shadowColor: Colors.black45,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onPressed,
        child: Container(
          height: 48,
          padding: const EdgeInsets.only(left: 12, right: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.my_location, color: AppTheme.primaryTeal, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryTeal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZoneLabel extends StatelessWidget {
  final String name;
  const _ZoneLabel({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 4)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFB91C1C)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFFB91C1C),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DistanceChip extends StatelessWidget {
  final String text;
  const _DistanceChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 3)],
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFB91C1C)),
      ),
    );
  }
}

class _Attribution extends StatelessWidget {
  final String text;
  const _Attribution({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: const TextStyle(fontSize: 9, color: Color(0xFF475569))),
    );
  }
}

class _WaitingGps extends StatelessWidget {
  final String name;
  final bool compact;
  const _WaitingGps({required this.name, required this.compact});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white.withValues(alpha: 0.82),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_searching, size: compact ? 28 : 36, color: const Color(0xFF64748B)),
              const SizedBox(height: 10),
              Text(
                MapFormat.tr('mapWaitingGps'),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
              ),
              if (!compact) ...[
                const SizedBox(height: 6),
                Text(
                  MapFormat.tr('mapWaitingGpsDesc', {'name': name}),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF475569)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
