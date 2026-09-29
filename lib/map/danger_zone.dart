import 'package:latlong2/latlong.dart';

/// Vùng nguy hiểm hiển thị trên bản đồ (sông, hồ, đường lớn, vùng người chăm sóc
/// tự khoanh). Chuẩn bị sẵn cho tính năng cảnh báo vùng nguy hiểm: hiện tại bản
/// đồ chỉ vẽ, chưa có nguồn dữ liệu.
///
/// Một vùng là hình tròn ([center] + [radiusMeters]) hoặc đa giác ([polygon]).
class DangerZone {
  final String id;
  final String name;
  final LatLng? center;
  final double? radiusMeters;
  final List<LatLng> polygon;

  const DangerZone.circle({
    required this.id,
    required this.name,
    required LatLng this.center,
    required double this.radiusMeters,
  }) : polygon = const [];

  const DangerZone.polygon({
    required this.id,
    required this.name,
    required this.polygon,
  })  : center = null,
        radiusMeters = null;

  bool get isCircle => center != null && radiusMeters != null;

  /// Điểm đặt nhãn tên vùng.
  LatLng get labelPoint {
    if (center != null) return center!;
    if (polygon.isEmpty) return const LatLng(0, 0);
    double lat = 0, lng = 0;
    for (final p in polygon) {
      lat += p.latitude;
      lng += p.longitude;
    }
    return LatLng(lat / polygon.length, lng / polygon.length);
  }
}
