import 'package:flutter/material.dart';
import '../models/elderly_model.dart';
import '../utils/app_state.dart';

/// Công cụ phát triển / mô phỏng dùng trong SettingsScreen.
///
/// Cho phép kích hoạt các kịch bản SOS và chuyển đổi trạng thái online/offline
/// của thiết bị để phục vụ kiểm thử thủ công.
class DeveloperToolsSection extends StatelessWidget {
  final List<ElderlyModel> relatives;

  const DeveloperToolsSection({super.key, required this.relatives});

  @override
  Widget build(BuildContext context) {
    final state = AppState();

    return ExpansionTile(
      shape: const Border(),
      title: const Text(
        'Developer Tools',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
      childrenPadding: const EdgeInsets.all(8),
      children: [
        _buildDevButton('MÔ PHỎNG TÉ NGÃ (BÀ A)', Icons.personal_injury, Colors.red, () => state.simulateFall(1)),
        const SizedBox(height: 8),
        _buildDevButton('MÔ PHỎNG VƯỢT VÙNG AN TOÀN (ÔNG B)', Icons.directions_walk, Colors.deepOrange, () => state.simulateExitSafeZone(2)),
        const SizedBox(height: 8),
        _buildDevButton('MÔ PHỎNG NHỊP TIM/SPO2 XẤU (BÀ A)', Icons.heart_broken, Colors.amber.shade800, () => state.simulateHeartRateSpike(1)),
        const SizedBox(height: 8),
        _buildDevButton('MÔ PHỎNG THIẾT BỊ ONLINE (BÀ A)', Icons.wifi_tethering, Colors.teal, () => state.simulateDeviceOnline(1)),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () {
            final elderly = relatives.cast<ElderlyModel?>().firstWhere(
              (e) => e?.id == 1,
              orElse: () => null,
            );
            if (elderly == null) return;
            final updated = elderly.copyWith(
              isOffline: !elderly.isOffline,
              battery: elderly.isOffline ? 90 : 0,
              heartRate: elderly.isOffline ? 75 : 0,
              spo2: elderly.isOffline ? 98 : 0,
            );
            state.updateElderly(updated);
          },
          icon: const Icon(Icons.wifi_off, color: Colors.teal),
          label: const Text('ĐỔI ONLINE/OFFLINE THIẾT BỊ BÀ A'),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.teal, width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildDevButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white, size: 20),
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
