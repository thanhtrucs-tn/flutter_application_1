import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';

import '../utils/localization.dart';

/// Định dạng chữ dùng trên bản đồ.
class MapFormat {
  MapFormat._();

  static String _t(String key, [Map<String, String> args = const {}]) {
    var s = Localization.translate(key);
    args.forEach((k, v) => s = s.replaceAll('{$k}', v));
    return s;
  }

  /// "Vừa cập nhật" / "Cập nhật 2 phút trước" / "Cập nhật 3 giờ trước" / "Lúc 15:02 28/9".
  static String updatedAgo(DateTime time, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(time);
    if (diff.inMinutes < 1) return _t('mapUpdatedJustNow');
    if (diff.inMinutes < 60) return _t('mapUpdatedMinutes', {'n': '${diff.inMinutes}'});
    if (diff.inHours < 24) return _t('mapUpdatedHours', {'n': '${diff.inHours}'});
    return _t('mapUpdatedAt', {'t': clock(time, withDate: true)});
  }

  /// Dạng ngắn cho chỗ hẹp: "Vừa xong" / "2 phút trước" / "3 giờ trước" / "15:02 28/9".
  static String ago(DateTime time, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(time);
    if (diff.inMinutes < 1) return _t('mapJustNow');
    if (diff.inMinutes < 60) return _t('mapMinutesAgo', {'n': '${diff.inMinutes}'});
    if (diff.inHours < 24) return _t('mapHoursAgo', {'n': '${diff.inHours}'});
    return clock(time, withDate: true);
  }

  /// "15:02 · 25 phút trước" cho vị trí cuối cùng khi mất kết nối.
  static String lastSeen(DateTime time, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(time);
    final ago = diff.inMinutes < 60
        ? _t('mapMinutesAgo', {'n': '${diff.inMinutes < 1 ? 1 : diff.inMinutes}'})
        : diff.inHours < 24
            ? _t('mapHoursAgo', {'n': '${diff.inHours}'})
            : clock(time, withDate: true);
    return '${clock(time)} · $ago';
  }

  static String clock(DateTime t, {bool withDate = false}) {
    final hm = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    return withDate ? '$hm ${t.day}/${t.month}' : hm;
  }

  static String accuracy(double meters) => _t('mapAccuracy', {'m': meters.round().toString()});

  /// "420 m" / "1,4 km" (dấu phẩy thập phân kiểu Việt).
  static String distance(LatLng a, LatLng b) {
    final m = const Distance().distance(a, b);
    if (m < 1000) return '${(m / 10).round() * 10} m';
    final km = (m / 1000).toStringAsFixed(1);
    return '${Localization.currentLanguage == 'vi' ? km.replaceAll('.', ',') : km} km';
  }

  static String tr(String key, [Map<String, String> args = const {}]) => _t(key, args);
}

/// Vẽ lại [builder] mỗi 30 giây để chữ "x phút trước" luôn đúng.
class MinuteTicker extends StatefulWidget {
  final WidgetBuilder builder;
  const MinuteTicker({super.key, required this.builder});

  @override
  State<MinuteTicker> createState() => _MinuteTickerState();
}

class _MinuteTickerState extends State<MinuteTicker> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}
