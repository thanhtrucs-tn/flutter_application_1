import 'package:flutter/material.dart';

/// Grid of four simulator function buttons below the SOS button.
class FunctionButtonGrid extends StatelessWidget {
  final VoidCallback onFallSimulated;
  final VoidCallback onHeartRateAlert;
  final VoidCallback onOfflineSimulated;
  final VoidCallback onSendLocation;

  const FunctionButtonGrid({
    super.key,
    required this.onFallSimulated,
    required this.onHeartRateAlert,
    required this.onOfflineSimulated,
    required this.onSendLocation,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.5,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildButton(
          label: 'Giả lập té ngã',
          icon: Icons.warning,
          color: Colors.orange,
          onPressed: onFallSimulated,
        ),
        _buildButton(
          label: 'Giả lập nhịp tim bất thường',
          icon: Icons.heart_broken,
          color: Colors.purple,
          onPressed: onHeartRateAlert,
        ),
        _buildButton(
          label: 'Giả lập mất kết nối',
          icon: Icons.wifi_off,
          color: Colors.red,
          onPressed: onOfflineSimulated,
        ),
        _buildButton(
          label: 'Gửi vị trí hiện tại',
          icon: Icons.location_on,
          color: Colors.blue,
          onPressed: onSendLocation,
        ),
      ],
    );
  }

  Widget _buildButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }
}
