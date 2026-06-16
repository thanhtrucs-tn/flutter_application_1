import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Wrapper nhỏ quanh `socket_io_client` để kết nối tới SOS Care backend.
///
/// Chỉ giữ kết nối và forward event; toàn bộ business logic nằm ở
/// [DeviceEventService].
class SocketIoService {
  io.Socket? _socket;
  String? _url;

  /// Lưu các listener đã đăng ký để tái gắn khi kết nối lại.
  final Map<String, List<dynamic Function(dynamic)>> _listeners = {};

  bool get isConnected => _socket?.connected ?? false;

  /// Kết nối tới [url].
  ///
  /// Sử dụng websocket transport, tự động reconnect tối đa 10 lần,
  /// delay giữa các lần reconnect 1 giây.
  void connect(String url) {
    if (_socket?.connected == true && _url == url) return;

    dispose();
    _url = url;

    _socket = io.io(
      url,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(1000)
          .setTimeout(5000)
          .build(),
    );

    // Tái gắn listener đã đăng ký trước connect.
    _listeners.forEach((event, handlers) {
      for (final handler in handlers) {
        _socket!.on(event, handler);
      }
    });

    _socket!.onConnect((_) {
      debugPrint('✅ Socket connected: $url');
    });

    _socket!.onDisconnect((_) {
      debugPrint('⚠️ Socket disconnected');
    });

    _socket!.onConnectError((error) {
      debugPrint('❌ Socket connection error: $error');
    });

    _socket!.onError((error) {
      debugPrint('❌ Socket error: $error');
    });
  }

  /// Đăng ký listener cho một event.
  ///
  /// Listener được lưu lại để tự động gắn lại nếu socket kết nối lại.
  void on(String event, dynamic Function(dynamic) handler) {
    _listeners.putIfAbsent(event, () => []).add(handler);
    _socket?.on(event, handler);
  }

  /// Hủy toàn bộ listener của một event.
  void off(String event) {
    _listeners.remove(event);
    _socket?.off(event);
  }

  /// Ngắt kết nối và dọn dẹp.
  void dispose() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _url = null;
    }
  }
}
