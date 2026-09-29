import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../map/location_address_text.dart';
import '../map/map_format.dart';
import '../map/map_markers.dart';
import '../map/sos_map.dart';
import '../models/alert_model.dart';
import '../models/elderly_model.dart';
import '../utils/app_state.dart';
import '../utils/localization.dart';
import '../utils/theme.dart';
import 'ringing_device_screen.dart';
import 'set_home_screen.dart';

/// Màn bản đồ đầy đủ của một người thân.
///
/// Truyền [alert] để mở ở chế độ SOS: đánh dấu vị trí sự cố, nối với nhà và
/// canh camera thấy cả hai điểm.
///
/// Lắng nghe [AppState] nên vị trí và trạng thái cập nhật realtime khi đang mở.
class MapViewScreen extends StatelessWidget {
  final ElderlyModel elderly;
  final AlertModel? alert;

  const MapViewScreen({super.key, required this.elderly, this.alert});

  bool get _sos =>
      alert != null && !(alert!.latitude == 0 && alert!.longitude == 0);

  @override
  Widget build(BuildContext context) {
    final state = AppState();
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final e = state.relatives.firstWhere(
          (r) => r.id == elderly.id,
          orElse: () => elderly,
        );
        final incident = _sos ? LatLng(alert!.latitude, alert!.longitude) : null;
        final topPad = MediaQuery.of(context).padding.top;
        final topBarBottom = _sos ? topPad + 72 : topPad + 12 + 44;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: _sos ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
          child: Scaffold(
            body: Stack(
              children: [
                CustomMultiChildLayout(
                  delegate: _MapSheetLayout(overlap: _sheetOverlap),
                  children: [
                    LayoutId(
                      id: _Slot.map,
                      child: SosMap(
                        elderly: e,
                        incident: incident,
                        topInset: topBarBottom + 16,
                        bottomInset: _sheetOverlap,
                      ),
                    ),
                    LayoutId(
                      id: _Slot.sheet,
                      child: _InfoSheet(elderly: e, alert: _sos ? alert : null),
                    ),
                  ],
                ),
                if (_sos)
                  _SosBanner(elderly: e, alert: alert!)
                else
                  Positioned(
                    left: 16,
                    right: 16,
                    top: topPad + 12,
                    child: _TopBar(elderly: e),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Phần bản đồ nằm dưới mép bo tròn của tấm thông tin.
const double _sheetOverlap = 20;

enum _Slot { map, sheet }

/// Đặt tấm thông tin ở đáy (cao theo nội dung), bản đồ lấp phần còn lại và
/// lấn xuống dưới tấm [overlap] px để thấy bản đồ sau góc bo.
/// Nhờ vậy tâm bản đồ = tâm vùng nhìn thấy, camera bám theo luôn đúng giữa.
class _MapSheetLayout extends MultiChildLayoutDelegate {
  final double overlap;
  _MapSheetLayout({required this.overlap});

  @override
  void performLayout(Size size) {
    final sheet = layoutChild(
      _Slot.sheet,
      BoxConstraints(
        minWidth: size.width,
        maxWidth: size.width,
        maxHeight: size.height * 0.6,
      ),
    );
    positionChild(_Slot.sheet, Offset(0, size.height - sheet.height));
    final mapHeight = (size.height - sheet.height + overlap).clamp(0.0, size.height);
    layoutChild(_Slot.map, BoxConstraints.tight(Size(size.width, mapHeight)));
    positionChild(_Slot.map, Offset.zero);
  }

  @override
  bool shouldRelayout(_MapSheetLayout old) => old.overlap != overlap;
}

// --- Thanh trên ---

class _TopBar extends StatelessWidget {
  final ElderlyModel elderly;
  const _TopBar({required this.elderly});

  (String, Color, Color) _status() {
    if (elderly.isOffline) {
      return (Localization.translate('statusOffline'), MapStatus.offline, const Color(0xFF475569));
    }
    switch (elderly.status) {
      case 'critical':
        return (Localization.translate('statusCriticalText'), AppTheme.statusCritical, const Color(0xFFB91C1C));
      case 'warning':
        return (Localization.translate('statusWarningText'), AppTheme.statusWarning, const Color(0xFFB45309));
      default:
        return (Localization.translate('statusSafeText'), AppTheme.statusSafe, const Color(0xFF047857));
    }
  }

  @override
  Widget build(BuildContext context) {
    final (label, dot, text) = _status();
    return Row(
      children: [
        _CircleButton(
          icon: Icons.arrow_back,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Container(
            height: 44,
            padding: const EdgeInsets.only(left: 14, right: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 1))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    elderly.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                  ),
                ),
                const SizedBox(width: 10),
                Container(width: 8, height: 8, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: text)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  const _CircleButton({required this.icon, required this.tooltip, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 2,
        shadowColor: Colors.black38,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, size: 22, color: const Color(0xFF1E293B)),
          ),
        ),
      ),
    );
  }
}

class _SosBanner extends StatelessWidget {
  final ElderlyModel elderly;
  final AlertModel alert;
  const _SosBanner({required this.elderly, required this.alert});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      child: Container(
        color: const Color(0xFFB91C1C),
        padding: EdgeInsets.fromLTRB(4, MediaQuery.of(context).padding.top + 6, 16, 12),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    MapFormat.tr('mapSosTitle', {'name': elderly.name}),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  MinuteTicker(
                    builder: (_) => Text(
                      '${MapFormat.tr('mapSosSubtitle', {'t': MapFormat.clock(alert.time)})} · ${MapFormat.ago(alert.time)}',
                      style: const TextStyle(color: Color(0xFFFECACA), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Tấm thông tin dưới ---

class _InfoSheet extends StatelessWidget {
  final ElderlyModel elderly;
  final AlertModel? alert;
  const _InfoSheet({required this.elderly, this.alert});

  bool get _sos => alert != null;

  LatLng? get _point {
    if (alert != null) return LatLng(alert!.latitude, alert!.longitude);
    return elderly.hasLocation ? LatLng(elderly.latitude, elderly.longitude) : null;
  }

  void _call(BuildContext context) {
    if (elderly.emergencyContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(MapFormat.tr('mapNoContact'))),
      );
      return;
    }
    // Giữ cùng cách gọi như các màn khác: gọi liên hệ khẩn cấp đầu tiên.
    final phone = ElderlyModel.splitContact(elderly.emergencyContacts.first).$2;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.phone, color: Colors.green),
            SizedBox(width: 8),
            Expanded(child: Text('Cuộc gọi SOS Care', overflow: TextOverflow.ellipsis)),
          ],
        ),
        content: Text('Hệ thống đang kết nối cuộc gọi thoại khẩn cấp tới số:\n$phone'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng'))],
      ),
    );
  }

  Future<void> _directions(BuildContext context, LatLng p) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${p.latitude},${p.longitude}',
    );
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uri.toString())));
    }
  }

  Future<void> _setHome(BuildContext context) async {
    final result = await SetHomeScreen.open(
      context,
      relativeName: elderly.name,
      currentLocation: elderly.hasLocation ? LatLng(elderly.latitude, elderly.longitude) : null,
    );
    if (result == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await AppState().updateElderly(
        elderly.copyWith(
          safeZoneLat: result.lat,
          safeZoneLng: result.lng,
          address: result.address.isNotEmpty ? result.address : null,
        ),
      );
      messenger.showSnackBar(SnackBar(content: Text(MapFormat.tr('homeSaved'))));
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(MapFormat.tr('homeSaveFailed')), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final muted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final border = isDark ? Colors.white24 : const Color(0xFFCBD5E1);
    final point = _point;
    final offline = elderly.isOffline && !_sos;

    final String label;
    if (_sos) {
      label = MapFormat.tr('mapIncidentLocation');
    } else if (offline) {
      label = MapFormat.tr('mapLastLocation');
    } else {
      label = MapFormat.tr('mapCurrentLocation');
    }

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 16, offset: Offset(0, -4))],
      ),
      padding: EdgeInsets.fromLTRB(20, 10, 20, 16 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
              color: _sos ? const Color(0xFFB91C1C) : muted,
            ),
          ),
          const SizedBox(height: 4),
          if (point == null)
            Text(
              MapFormat.tr('mapWaitingGps'),
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: textColor),
            )
          else ...[
            LocationAddressText(
              lat: point.latitude,
              lng: point.longitude,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, height: 1.35, color: textColor),
            ),
            const SizedBox(height: 8),
            MinuteTicker(
              builder: (_) => Wrap(
                spacing: 14,
                runSpacing: 4,
                children: [
                  _Meta(
                    icon: Icons.schedule,
                    color: muted,
                    text: offline
                        ? MapFormat.lastSeen(elderly.lastUpdated)
                        : MapFormat.updatedAgo(_sos ? alert!.time : elderly.lastUpdated),
                  ),
                  if (!_sos && elderly.accuracy != null && elderly.accuracy! > 0)
                    _Meta(
                      icon: Icons.gps_fixed,
                      color: muted,
                      text: MapFormat.accuracy(elderly.accuracy!),
                    ),
                ],
              ),
            ),
          ],
          if (offline) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.wifi_off_rounded, size: 18, color: muted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      MapFormat.tr('mapOfflineNote'),
                      style: TextStyle(fontSize: 13, height: 1.45, color: isDark ? Colors.white70 : const Color(0xFF334155)),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (!elderly.hasHome) ...[
            const SizedBox(height: 14),
            _NoHomeRow(onSetHome: () => _setHome(context)),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: () => _call(context),
                    icon: const Icon(Icons.call, size: 18),
                    label: Text(MapFormat.tr('mapCall')),
                    style: FilledButton.styleFrom(
                      backgroundColor: _sos ? const Color(0xFFB91C1C) : AppTheme.primaryTeal,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              if (!_sos) ...[
                const SizedBox(width: 8),
                Tooltip(
                  message: elderly.isOffline ? MapFormat.tr('mapRingOffline') : MapFormat.tr('mapRing'),
                  child: SizedBox(
                    width: 56,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: elderly.isOffline
                          ? null
                          : () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => RingingDeviceScreen(elderly: elderly)),
                              ),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        foregroundColor: textColor,
                        side: BorderSide(color: border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Icon(Icons.notifications_active_outlined, semanticLabel: MapFormat.tr('mapRing')),
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: point == null ? null : () => _directions(context, point),
                  icon: const Icon(Icons.directions_outlined, size: 18),
                  label: Text(MapFormat.tr(_sos ? 'mapDirectionsHere' : 'mapDirections')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textColor,
                    side: BorderSide(color: border),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _Meta({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(text, style: TextStyle(fontSize: 13, color: color)),
      ],
    );
  }
}

class _NoHomeRow extends StatelessWidget {
  final VoidCallback onSetHome;
  const _NoHomeRow({required this.onSetHome});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final muted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    const tint = Color(0xFFE6F2F0);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF99C9C2)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.home_outlined, size: 20, color: AppTheme.primaryTeal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  MapFormat.tr('mapNoHome'),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
                ),
                Text(
                  MapFormat.tr('mapNoHomeDesc'),
                  style: TextStyle(fontSize: 12, height: 1.4, color: muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onSetHome,
            style: TextButton.styleFrom(
              backgroundColor: tint,
              foregroundColor: AppTheme.primaryTeal,
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            child: Text(MapFormat.tr('mapSetHomeNow')),
          ),
        ],
      ),
    );
  }
}
