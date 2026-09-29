import 'package:flutter/material.dart';

import '../services/address_service.dart';
import 'map_format.dart';

/// Hiện địa chỉ chữ của một tọa độ (reverse geocoding qua Nominatim, có cache).
///
/// Chỉ gọi lại khi tọa độ đổi quá ~10 m (làm tròn 4 chữ số thập phân), để GPS
/// dao động nhẹ không tạo request mới.
class LocationAddressText extends StatefulWidget {
  final double lat;
  final double lng;
  final TextStyle? style;
  final int maxLines;

  const LocationAddressText({
    super.key,
    required this.lat,
    required this.lng,
    this.style,
    this.maxLines = 2,
  });

  @override
  State<LocationAddressText> createState() => _LocationAddressTextState();
}

class _LocationAddressTextState extends State<LocationAddressText> {
  String? _text;
  bool _loading = true;
  String _key = '';

  static String _keyOf(double lat, double lng) =>
      '${lat.toStringAsFixed(4)},${lng.toStringAsFixed(4)}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(LocationAddressText old) {
    super.didUpdateWidget(old);
    if (_keyOf(widget.lat, widget.lng) != _key) _load();
  }

  /// Được gọi từ initState/didUpdateWidget: phần chạy đồng bộ chỉ đổi field,
  /// vì framework sẽ build lại ngay sau hai hàm này (không được setState ở đó).
  Future<void> _load() async {
    final key = _keyOf(widget.lat, widget.lng);
    _key = key;
    if (widget.lat == 0 && widget.lng == 0) {
      _loading = false;
      _text = null;
      return;
    }
    _loading = _text == null;
    final address = await AddressService.instance.getAddress(widget.lat, widget.lng);
    if (!mounted || _key != key) return; // tọa độ đã đổi trong lúc chờ
    setState(() {
      _loading = false;
      final line = address?.line ?? '';
      _text = line.isEmpty ? null : line;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String text;
    if (_text != null) {
      text = _text!;
    } else if (_loading) {
      text = MapFormat.tr('mapAddressLoading');
    } else {
      // Không tra được địa chỉ (mất mạng, dịch vụ từ chối…): hiện tọa độ để
      // người chăm sóc vẫn có thông tin dùng được.
      text = '${widget.lat.toStringAsFixed(5)}, ${widget.lng.toStringAsFixed(5)}';
    }
    return Text(
      text,
      maxLines: widget.maxLines,
      overflow: TextOverflow.ellipsis,
      style: widget.style,
    );
  }
}
