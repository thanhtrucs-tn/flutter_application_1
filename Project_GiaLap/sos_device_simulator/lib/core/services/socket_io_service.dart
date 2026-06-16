import 'package:socket_io_client/socket_io_client.dart' as io;

import '../config/api_config.dart';

/// Lightweight Socket.IO client used by the simulator to stay connected
/// to the backend and optionally receive broadcast acknowledgements.
class SocketIOService {
  io.Socket? _socket;

  bool get isConnected => _socket?.connected ?? false;

  void connect() {
    if (_socket != null) return;

    _socket = io.io(
      ApiConfig.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(3000)
          .build(),
    );

    _socket!.onConnect((_) {
      // ignore: avoid_print
      print('✅ Simulator socket connected');
    });

    _socket!.onDisconnect((_) {
      // ignore: avoid_print
      print('⚠️ Simulator socket disconnected');
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
