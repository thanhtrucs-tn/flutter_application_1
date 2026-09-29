import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

/// Cấu hình nguồn tile cho bản đồ. App chỉ dùng bản đồ vệ tinh (có nhãn đường).
///
/// Nguồn chính là MapTiler (style "hybrid" = ảnh vệ tinh + nhãn). Key truyền lúc
/// chạy/build, không ghi cứng trong code:
///
/// ```
/// flutter run --dart-define=MAPTILER_KEY=xxxxxxxx
/// ```
///
/// Chưa có key thì dùng ảnh vệ tinh Esri + lớp đường/nhãn của Esri (không cần
/// key, chỉ nên dùng khi phát triển/demo).
class MapTiles {
  MapTiles._();

  static const String mapTilerKey = String.fromEnvironment('MAPTILER_KEY');
  static bool get hasMapTilerKey => mapTilerKey.isNotEmpty;

  static const String _userAgent = 'com.example.flutter_application_1';

  /// Giữ lại tile của các mức zoom khác khi đang zoom/kéo, để không bị chớp
  /// trắng trong lúc chờ tile mới tải về.
  static const int _keepBuffer = 4;
  static const int _panBuffer = 1;
  static const TileDisplay _display = TileDisplay.fadeIn(duration: Duration(milliseconds: 120));

  /// Các lớp tile, xếp từ dưới lên.
  static List<Widget> layers() {
    if (hasMapTilerKey) {
      return [
        TileLayer(
          // Một lớp duy nhất (ảnh + nhãn), tile 512px: ít request hơn.
          urlTemplate:
              'https://api.maptiler.com/maps/hybrid/{z}/{x}/{y}.jpg?key=$mapTilerKey',
          tileSize: 512,
          zoomOffset: -1,
          maxNativeZoom: 20,
          keepBuffer: _keepBuffer,
          panBuffer: _panBuffer,
          tileDisplay: _display,
          userAgentPackageName: _userAgent,
        ),
      ];
    }

    const esri = 'https://server.arcgisonline.com/ArcGIS/rest/services';
    return [
      TileLayer(
        urlTemplate: '$esri/World_Imagery/MapServer/tile/{z}/{y}/{x}',
        maxNativeZoom: 19,
        keepBuffer: _keepBuffer,
        panBuffer: _panBuffer,
        tileDisplay: _display,
        userAgentPackageName: _userAgent,
      ),
      // Đường + tên đường phủ lên ảnh để vẫn đọc được bản đồ.
      TileLayer(
        urlTemplate: '$esri/Reference/World_Transportation/MapServer/tile/{z}/{y}/{x}',
        maxNativeZoom: 19,
        keepBuffer: _keepBuffer,
        panBuffer: _panBuffer,
        tileDisplay: _display,
        userAgentPackageName: _userAgent,
      ),
    ];
  }

  /// Dòng ghi nguồn bắt buộc hiển thị trên bản đồ.
  static String attribution() =>
      hasMapTilerKey ? '© MapTiler © OpenStreetMap' : '© Esri, Maxar';
}
