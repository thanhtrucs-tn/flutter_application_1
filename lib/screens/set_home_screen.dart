import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../map/map_format.dart';
import '../map/map_tiles.dart';
import '../map/smooth_wheel_zoom.dart';
import '../models/address_model.dart';
import '../services/address_service.dart';
import '../utils/theme.dart';

/// Kết quả của màn ghim vị trí nhà.
class HomeLocation {
  final double lat;
  final double lng;
  final String address;
  const HomeLocation({required this.lat, required this.lng, required this.address});
}

/// Màn ghim vị trí nhà: tìm địa chỉ hoặc kéo bản đồ để ghim đứng yên ở giữa
/// nằm đúng nóc nhà. Trả về [HomeLocation] khi bấm lưu, null khi quay lại.
///
/// Nhà chỉ đổi khi người chăm sóc chủ động lưu ở đây; app không bao giờ tự
/// lấy vị trí hiện tại của người thân làm nhà.
class SetHomeScreen extends StatefulWidget {
  final String relativeName;

  /// Vị trí nhà đang lưu (để sửa).
  final LatLng? initial;

  /// Vị trí hiện tại của người thân (gợi ý nhanh), null nếu chưa có GPS.
  final LatLng? currentLocation;

  const SetHomeScreen({
    super.key,
    required this.relativeName,
    this.initial,
    this.currentLocation,
  });

  static Future<HomeLocation?> open(
    BuildContext context, {
    required String relativeName,
    LatLng? initial,
    LatLng? currentLocation,
  }) {
    return Navigator.of(context).push<HomeLocation>(
      MaterialPageRoute(
        builder: (_) => SetHomeScreen(
          relativeName: relativeName,
          initial: initial,
          currentLocation: currentLocation,
        ),
      ),
    );
  }

  @override
  State<SetHomeScreen> createState() => _SetHomeScreenState();
}

class _SetHomeScreenState extends State<SetHomeScreen> {
  static const LatLng _vietnamCenter = LatLng(16.0, 106.3);
  static const double _pinZoom = 18;

  /// Dưới mức zoom này một điểm ghim lệch cả trăm mét, nên chưa cho lưu.
  static const double _minSaveZoom = 15;

  final MapController _map = MapController();
  final TextEditingController _search = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  late LatLng _center;
  late double _zoom;
  /// Tọa độ tâm để hiện dưới địa chỉ. Tách riêng để kéo bản đồ không build lại
  /// cả màn mỗi frame (nguyên nhân làm kéo/zoom bị khựng).
  final ValueNotifier<LatLng> _centerText = ValueNotifier(const LatLng(0, 0));

  String? _address;
  bool _addressLoading = false;
  Timer? _geocodeDebounce;
  int _geocodeSeq = 0;

  Timer? _searchDebounce;
  List<Address> _results = const [];
  bool _searching = false;
  bool _searchedOnce = false;
  bool _searchFailed = false; // không gọi được dịch vụ tìm kiếm nào

  @override
  void initState() {
    super.initState();
    final start = widget.initial ?? widget.currentLocation;
    _center = start ?? _vietnamCenter;
    _centerText.value = _center;
    _zoom = start != null ? _pinZoom : 5.5;
    if (start != null) _geocode(immediate: true);
  }

  @override
  void dispose() {
    _geocodeDebounce?.cancel();
    _searchDebounce?.cancel();
    _map.dispose();
    _centerText.dispose();
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // --- Địa chỉ của điểm ghim ---

  void _geocode({bool immediate = false}) {
    _geocodeDebounce?.cancel();
    Future<void> run() async {
      final seq = ++_geocodeSeq;
      final point = _center;
      if (mounted) setState(() => _addressLoading = true);
      final a = await AddressService.instance.getAddress(point.latitude, point.longitude);
      if (!mounted || seq != _geocodeSeq) return;
      setState(() {
        _addressLoading = false;
        final line = a?.line ?? '';
        _address = line.isEmpty ? null : line;
      });
    }

    if (immediate) {
      // Gọi sau frame đầu để không setState trong initState.
      WidgetsBinding.instance.addPostFrameCallback((_) => run());
    } else {
      // Nominatim giới hạn ~1 request/giây: chờ người dùng thả tay rồi mới hỏi.
      _geocodeDebounce = Timer(const Duration(milliseconds: 700), run);
    }
  }

  /// flutter_map có thể báo đổi camera ngay trong lúc layout (vd. bàn phím mở
  /// làm bản đồ đổi kích thước); khi đó dời setState sang sau frame.
  void _safeSetState(VoidCallback fn) {
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(fn);
      });
    } else {
      setState(fn);
    }
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    final wasSavable = _zoom >= _minSaveZoom;
    final zoomChanged = (camera.zoom - _zoom).abs() > 0.01;
    _center = camera.center;
    _zoom = camera.zoom;
    _centerText.value = camera.center;
    if (hasGesture) _searchFocus.unfocus();

    // Chỉ build lại màn khi thật sự có gì đổi trên UI, không phải mỗi frame kéo.
    final savableChanged = wasSavable != (_zoom >= _minSaveZoom);
    final closeResults = hasGesture && _results.isNotEmpty;
    if (savableChanged || closeResults) {
      _safeSetState(() {
        if (closeResults) _results = const [];
      });
    }
    if (zoomChanged || hasGesture) _geocode();
  }

  void _moveTo(LatLng point, {String? knownAddress}) {
    _map.move(point, _pinZoom);
    _center = point;
    _centerText.value = point;
    _zoom = _pinZoom;
    _geocodeDebounce?.cancel();
    _geocodeSeq++; // bỏ kết quả địa chỉ cũ đang chờ
    setState(() {
      _results = const [];
      if (knownAddress != null && knownAddress.isNotEmpty) _address = knownAddress;
    });
    if (knownAddress == null || knownAddress.isEmpty) _geocode();
  }

  // --- Tìm kiếm ---

  void _onSearchChanged(String text) {
    _searchDebounce?.cancel();
    if (text.trim().length < 3) {
      setState(() {
        _results = const [];
        _searchedOnce = false;
      });
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 700), () => _runSearch(text));
  }

  Future<void> _runSearch(String text) async {
    setState(() => _searching = true);
    // Đang xem gần một khu vực cụ thể thì ưu tiên kết quả quanh đó.
    final near = _zoom >= 10 ? _center : null;
    final results = await AddressService.instance.search(
      text,
      nearLat: near?.latitude,
      nearLng: near?.longitude,
    );
    if (!mounted || _search.text != text) return;
    setState(() {
      _searching = false;
      _searchedOnce = true;
      _searchFailed = results == null;
      _results = results ?? const [];
    });
  }

  void _pickResult(Address a) {
    _searchFocus.unfocus();
    _search.text = a.line;
    _moveTo(LatLng(a.lat, a.lng), knownAddress: a.line);
  }

  void _save() {
    Navigator.of(context).pop(
      HomeLocation(
        lat: _center.latitude,
        lng: _center.longitude,
        address: _address ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final muted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final fieldBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final canSave = _zoom >= _minSaveZoom;
    final name = widget.relativeName;

    return Scaffold(
      backgroundColor: surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // --- Tiêu đề + tìm kiếm ---
            Container(
              color: surface,
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Text(
                          MapFormat.tr('homeTitle', {'name': name}),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: textColor),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: TextField(
                      controller: _search,
                      focusNode: _searchFocus,
                      onChanged: _onSearchChanged,
                      onSubmitted: (t) {
                        _searchDebounce?.cancel();
                        if (t.trim().length >= 3) _runSearch(t);
                      },
                      textInputAction: TextInputAction.search,
                      style: TextStyle(fontSize: 15, color: textColor),
                      decoration: InputDecoration(
                        hintText: MapFormat.tr('homeSearchHint'),
                        hintStyle: TextStyle(color: muted),
                        prefixIcon: Icon(Icons.search, color: muted),
                        suffixIcon: _searching
                            ? const Padding(
                                padding: EdgeInsets.all(14),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : (_search.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.close, color: muted),
                                    onPressed: () {
                                      _search.clear();
                                      _onSearchChanged('');
                                    },
                                  )
                                : null),
                        filled: true,
                        fillColor: fieldBg,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- Bản đồ + ghim cố định ở giữa ---
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: SmoothWheelZoom(
                      controller: _map,
                      child: FlutterMap(
                      mapController: _map,
                      options: MapOptions(
                        initialCenter: _center,
                        initialZoom: _zoom,
                        minZoom: 3,
                        maxZoom: 19,
                        backgroundColor: const Color(0xFFE8EAE4),
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all &
                              ~InteractiveFlag.rotate &
                              ~InteractiveFlag.scrollWheelZoom,
                        ),
                        onPositionChanged: _onPositionChanged,
                      ),
                      children: MapTiles.layers(),
                    ),
                    ),
                  ),
                  const _CenterPin(),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 16,
                    child: Center(
                      child: _Hint(
                        text: canSave
                            ? MapFormat.tr('homeDragHint')
                            : MapFormat.tr('homeZoomIn'),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        MapTiles.attribution(),
                        style: const TextStyle(fontSize: 9, color: Color(0xFF475569)),
                      ),
                    ),
                  ),
                  // Kết quả tìm kiếm phủ lên bản đồ.
                  if (_results.isNotEmpty || (_searchedOnce && !_searching && _search.text.trim().length >= 3))
                    Positioned(
                      left: 16,
                      right: 16,
                      top: 0,
                      child: _SearchResults(
                        results: _results,
                        emptyText: MapFormat.tr(_searchFailed ? 'homeSearchError' : 'homeNoResults'),
                        onPick: _pickResult,
                      ),
                    ),
                ],
              ),
            ),

            // --- Địa chỉ + lưu ---
            Container(
              decoration: BoxDecoration(
                color: surface,
                boxShadow: const [
                  BoxShadow(color: Color(0x1A000000), blurRadius: 16, offset: Offset(0, -4)),
                ],
              ),
              padding: EdgeInsets.fromLTRB(20, 18, 20, 16 + MediaQuery.of(context).padding.bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    MapFormat.tr('homeAddressLabel'),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: muted, letterSpacing: 0.2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _address ??
                        (_addressLoading
                            ? MapFormat.tr('mapAddressLoading')
                            : MapFormat.tr('homePinned')),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, height: 1.35, color: textColor),
                  ),
                  const SizedBox(height: 4),
                  ValueListenableBuilder<LatLng>(
                    valueListenable: _centerText,
                    builder: (_, c, __) => Text(
                      '${c.latitude.toStringAsFixed(6)}, ${c.longitude.toStringAsFixed(6)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: muted,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 50,
                    child: FilledButton(
                      onPressed: canSave ? _save : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryTeal,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      child: Text(MapFormat.tr('homeSave')),
                    ),
                  ),
                  if (widget.currentLocation != null) ...[
                    const SizedBox(height: 4),
                    TextButton.icon(
                      onPressed: () => _moveTo(widget.currentLocation!),
                      icon: const Icon(Icons.my_location, size: 18),
                      label: Text(
                        MapFormat.tr('homeUseCurrent', {'name': name}),
                        textAlign: TextAlign.center,
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryTeal,
                        minimumSize: const Size.fromHeight(44),
                        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ghim nhà đứng yên ở tâm bản đồ; đầu nhọn chạm đúng tâm.
class _CenterPin extends StatelessWidget {
  const _CenterPin();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: SizedBox(
          width: 46,
          height: 128, // gấp đôi chiều cao ghim để đầu nhọn nằm đúng tâm
          child: Column(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryTeal,
                  boxShadow: [BoxShadow(color: Color(0x4D000000), blurRadius: 10, offset: Offset(0, 4))],
                ),
                child: const Icon(Icons.home_rounded, color: Colors.white, size: 24),
              ),
              Container(
                width: 3,
                height: 18,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryTeal,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(2)),
                ),
              ),
              // Bóng dưới chân ghim, đặt ngay tại tâm.
              Container(
                width: 16,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  final String text;
  const _Hint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  final List<Address> results;
  final String emptyText;
  final ValueChanged<Address> onPick;

  const _SearchResults({required this.results, required this.emptyText, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final muted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    return Material(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      elevation: 6,
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: results.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Text(emptyText, style: TextStyle(color: muted)),
            )
          : ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: results.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: muted.withValues(alpha: 0.2)),
                itemBuilder: (_, i) {
                  final a = results[i];
                  return ListTile(
                    leading: Icon(Icons.place_outlined, color: muted),
                    title: Text(
                      a.line,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 15, color: textColor),
                    ),
                    subtitle: a.province.isNotEmpty
                        ? Text(a.province, style: TextStyle(fontSize: 12, color: muted))
                        : null,
                    onTap: () => onPick(a),
                  );
                },
              ),
            ),
    );
  }
}
