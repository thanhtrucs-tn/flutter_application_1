import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../models/elderly_model.dart';
import 'location_address_text.dart';
import 'map_format.dart';
import 'sos_map.dart';

/// Bản xem trước bản đồ gọn trong một thẻ: chạm vào để mở bản đồ đầy đủ.
///
/// Dùng ở màn chi tiết người thân và màn cảnh báo SOS (truyền [incident]).
class MapPreviewCard extends StatelessWidget {
  final ElderlyModel elderly;
  final LatLng? incident;
  final DateTime? incidentTime;
  final VoidCallback onOpen;
  final double height;

  const MapPreviewCard({
    super.key,
    required this.elderly,
    required this.onOpen,
    this.incident,
    this.incidentTime,
    this.height = 232,
  });

  static const double _stripHeight = 44;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final muted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final point = incident ??
        (elderly.hasLocation ? LatLng(elderly.latitude, elderly.longitude) : null);

    return Semantics(
      button: true,
      label: MapFormat.tr('mapOpen'),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: _stripHeight,
              child: SosMap(elderly: elderly, incident: incident, compact: true),
            ),
            Positioned(
              right: 10,
              top: 10,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 3)],
                ),
                child: const Icon(Icons.open_in_full_rounded, size: 18, color: Color(0xFF1E293B)),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: _stripHeight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: surface,
                  border: Border(top: BorderSide(color: border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: point == null
                          ? Text(
                              MapFormat.tr('mapWaitingGps'),
                              style: TextStyle(fontSize: 14, color: muted),
                            )
                          : LocationAddressText(
                              lat: point.latitude,
                              lng: point.longitude,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: textColor,
                              ),
                            ),
                    ),
                    if (point != null) ...[
                      const SizedBox(width: 10),
                      MinuteTicker(
                        builder: (_) => Text(
                          elderly.isOffline && incident == null
                              ? MapFormat.lastSeen(elderly.lastUpdated)
                              : MapFormat.ago(incidentTime ?? elderly.lastUpdated),
                          style: TextStyle(fontSize: 12, color: muted),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(onTap: onOpen),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
