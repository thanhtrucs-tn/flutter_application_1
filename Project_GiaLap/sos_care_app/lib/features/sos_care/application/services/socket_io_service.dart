import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../../core/config/api_config.dart';

/// Callback signature for incoming realtime events.
typedef RealtimeEventCallback = void Function(String event, Map<String, dynamic> payload);

/// Manages the Socket.IO connection to the SOS Care backend and
/// dispatches incoming events to registered listeners.
class SocketIOService {
  io.Socket? _socket;
  final List<RealtimeEventCallback> _listeners = [];

  bool get isConnected => _socket?.connected ?? false;

  /// Connects to the backend Socket.IO server.
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
      print('✅ Socket connected');
    });

    _socket!.onDisconnect((_) {
      // ignore: avoid_print
      print('⚠️ Socket disconnected');
    });

    _socket!.onConnectError((error) {
      // ignore: avoid_print
      print('❌ Socket connection error: $error');
    });

    _socket!.on('sos:alert', (data) => _dispatch('sos:alert', data));
    _socket!.on('event:fall', (data) => _dispatch('event:fall', data));
    _socket!.on('event:heart_rate', (data) => _dispatch('event:heart_rate', data));
    _socket!.on('device:location', (data) => _dispatch('device:location', data));
    _socket!.on('device:status', (data) => _dispatch('device:status', data));
  }

  /// Disconnects from the backend.
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  /// Registers a listener for all incoming events.
  void addListener(RealtimeEventCallback listener) {
    _listeners.add(listener);
  }

  /// Removes a previously registered listener.
  void removeListener(RealtimeEventCallback listener) {
    _listeners.remove(listener);
  }

  void _dispatch(String event, dynamic data) {
    // ignore: avoid_print
    print('📡 $event: $data');
    if (data is! Map) return;
    final payload = Map<String, dynamic>.from(data);
    for (final listener in _listeners) {
      listener(event, payload);
    }
  }
}
