import 'package:flutter/material.dart';
import '../models/elderly_model.dart';
import '../utils/app_state.dart';

/// Công cụ phát triển / mô phỏng dùng trong SettingsScreen.
///
/// Cho phép kích hoạt các kịch bản SOS và chuyển đổi trạng thái online/offline
/// của thiết bị để phục vụ kiểm thử thủ công.
class DeveloperToolsSection extends StatelessWidget {
  const DeveloperToolsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState(),
      builder: (context, _) {
        final state = AppState();
        final elderly = state.relatives.cast<ElderlyModel?>().firstWhere(
          (e) => e?.id == 1,
          orElse: () => null,
        );
        final isOffline = elderly?.isOffline ?? true;

        return ExpansionTile(
          shape: const Border(),
          title: const Text(
            'Developer Tools',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          childrenPadding: const EdgeInsets.all(8),
          children: [
            _buildDevButton(
              'MÔ PHỎNG TÉ NGÃ (BÀ A)',
              Icons.personal_injury,
              Colors.red,
              () => state.simulateFall(1),
            ),
            const SizedBox(height: 8),
            _buildDevButton(
              'MÔ PHỎNG VƯỢT VÙNG AN TOÀN (ÔNG B)',
              Icons.directions_walk,
              Colors.deepOrange,
              () => state.simulateExitSafeZone(2),
            ),
            const SizedBox(height: 8),
            _buildDevButton(
              'MÔ PHỎNG NHỊP TIM/SPO2 XẤU (BÀ A)',
              Icons.heart_broken,
              Colors.amber.shade800,
              () => state.simulateHeartRateSpike(1),
            ),
            const SizedBox(height: 8),
            _buildDevButton(
              isOffline
                  ? 'MÔ PHỎNG THIẾT BỊ ONLINE (BÀ A)'
                  : 'MÔ PHỎNG THIẾT BỊ OFFLINE (BÀ A)',
              isOffline ? Icons.wifi_tethering : Icons.wifi_off,
              isOffline ? Colors.teal : Colors.grey.shade700,
              () => isOffline
                  ? state.simulateDeviceOnline(1)
                  : state.simulateDeviceOffline(1),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDevButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white, size: 20),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
