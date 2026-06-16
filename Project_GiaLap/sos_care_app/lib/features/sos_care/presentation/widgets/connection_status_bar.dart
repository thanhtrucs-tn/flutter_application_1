import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../providers/socket_state_notifier.dart';

/// Small bar at the top of the dashboard showing Socket.IO connection
/// status.
class ConnectionStatusBar extends ConsumerWidget {
  const ConnectionStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(socketStateNotifierProvider);

    final (label, color) = switch (state) {
      SocketConnectionState.connected => ('Kết nối realtime', Colors.green),
      SocketConnectionState.connecting => ('Đang kết nối...', Colors.orange),
      SocketConnectionState.error => ('Mất kết nối', Colors.red),
      SocketConnectionState.disconnected => ('Ngắt kết nối', Colors.grey),
    };

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      color: color.withValues(alpha: 0.1),
      child: Row(
        children: [
          Icon(Icons.circle, size: 10, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          if (state != SocketConnectionState.connected)
            TextButton(
              onPressed: () => ref.read(socketIOServiceProvider).connect(),
              child: const Text('Kết nối lại'),
            ),
        ],
      ),
    );
  }
}
