import 'package:flutter/material.dart';

/// Toggle tile that controls the simulated device's online/offline state.
class OnlineSwitchTile extends StatelessWidget {
  final bool isOnline;
  final ValueChanged<bool> onChanged;

  const OnlineSwitchTile({
    super.key,
    required this.isOnline,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SwitchListTile(
        title: const Text('Trạng thái thiết bị'),
        subtitle: Text(
          isOnline
              ? 'Online - dữ liệu sẽ được gửi lên server'
              : 'Offline - ngừng gửi dữ liệu GPS',
        ),
        value: isOnline,
        onChanged: onChanged,
        // Online = màu XANH (không theo primary đỏ của theme).
        activeTrackColor: Colors.green,
        activeThumbColor: Colors.white,
        inactiveTrackColor: Colors.grey.shade300,
        secondary: Icon(
          isOnline ? Icons.wifi : Icons.wifi_off,
          color: isOnline ? Colors.green : Colors.red,
        ),
      ),
    );
  }
}
