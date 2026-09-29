import 'dart:math' show Point;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// Zoom bằng con lăn chuột mượt (Windows/desktop).
///
/// Mặc định flutter_map nhảy từng nấc theo mỗi lần lăn, trông giật. Widget này
/// bắt sự kiện lăn và chuyển mức zoom bằng animation ngắn, giữ nguyên điểm dưới
/// con trỏ (hoặc tâm bản đồ khi [zoomAroundCenter] = true, dùng khi camera đang
/// bám theo người thân để không bị lệch khỏi họ).
///
/// Bản đồ bên trong phải tắt `InteractiveFlag.scrollWheelZoom`.
class SmoothWheelZoom extends StatefulWidget {
  final MapController controller;
  final Widget child;
  final double minZoom;
  final double maxZoom;
  final bool zoomAroundCenter;

  const SmoothWheelZoom({
    super.key,
    required this.controller,
    required this.child,
    this.minZoom = 3,
    this.maxZoom = 19,
    this.zoomAroundCenter = false,
  });

  @override
  State<SmoothWheelZoom> createState() => _SmoothWheelZoomState();
}

class _SmoothWheelZoomState extends State<SmoothWheelZoom> with SingleTickerProviderStateMixin {
  /// Mức zoom đổi trên mỗi pixel lăn (một nấc chuột ~100px ≈ 0.4 mức zoom).
  static const double _zoomPerPixel = 0.004;

  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..addListener(_tick);

  MapCamera? _start;
  // flutter_map 7 dùng Point<double> (pixel tính từ góc trên-trái bản đồ).
  Point<double> _anchor = const Point(0, 0);
  double _from = 0;
  double _to = 0;

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _onSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    // Nhận sự kiện này để ScrollView bên ngoài (nếu có) không cuộn theo.
    GestureBinding.instance.pointerSignalResolver.register(event, (e) {
      final scroll = e as PointerScrollEvent;
      final camera = widget.controller.camera;
      // Lăn liên tục thì cộng dồn vào đích đang chạy tới, không bắt đầu lại từ đầu.
      final base = _anim.isAnimating ? _to : camera.zoom;
      final target = (base - scroll.scrollDelta.dy * _zoomPerPixel)
          .clamp(widget.minZoom, widget.maxZoom)
          .toDouble();
      if ((target - camera.zoom).abs() < 0.001) return;
      _start = camera;
      _from = camera.zoom;
      _to = target;
      _anchor = widget.zoomAroundCenter
          ? Point(camera.nonRotatedSize.x / 2, camera.nonRotatedSize.y / 2)
          : Point(scroll.localPosition.dx, scroll.localPosition.dy);
      _anim.forward(from: 0);
    });
  }

  void _tick() {
    final start = _start;
    if (start == null) return;
    final t = Curves.easeOutCubic.transform(_anim.value);
    final zoom = _from + (_to - _from) * t;
    final center = start.focusedZoomCenter(_anchor, zoom);
    widget.controller.move(center, zoom);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(onPointerSignal: _onSignal, child: widget.child);
  }
}
