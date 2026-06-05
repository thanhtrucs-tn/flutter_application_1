import 'package:flutter/material.dart';
import '../models/elderly_model.dart';
import '../utils/localization.dart';
import '../widgets/sos_app_header.dart';
import '../widgets/custom_map.dart';
import '../widgets/map_action_overlay.dart';

/// Màn hình bản đồ toàn màn hình theo dõi vị trí người cao tuổi.
class MapViewScreen extends StatelessWidget {
  final ElderlyModel elderly;

  const MapViewScreen({super.key, required this.elderly});

  void _makeCall(BuildContext context, String phone) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(children: [Icon(Icons.phone, color: Colors.green), SizedBox(width: 8), Text('Cuộc gọi SOS Care')]),
        content: Text('Hệ thống đang kết nối cuộc gọi thoại khẩn cấp tới số:\n$phone'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SosAppHeader(
        title: '${Localization.translate('mapViewTitle')} ${elderly.name}',
        showBackButton: true,
      ),
      body: Stack(
        children: [
          CustomMap(
            lat: elderly.latitude,
            lng: elderly.longitude,
            safeZoneLat: elderly.safeZoneLat,
            safeZoneLng: elderly.safeZoneLng,
            safeZoneRadius: elderly.safeZoneRadius,
            safetyStatus: elderly.status,
            height: MediaQuery.of(context).size.height,
            relativeName: elderly.name,
            address: elderly.address,
          ),
          MapActionOverlay(
            onCall: () => _makeCall(context, elderly.emergencyContacts.first),
            onRing: () {},
            onDirections: () {},
          ),
        ],
      ),
    );
  }
}
