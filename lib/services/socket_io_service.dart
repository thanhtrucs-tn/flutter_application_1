import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Wrapper nhỏ quanh `socket_io_client` để kết nối tới SOS Care backend.
///
/// Chỉ giữ kết nối và forward event; toàn bộ business logic nằm ở
/// [DeviceEventService]. Hỗ trợ JWT handshake auth (scope event theo
/// `user:<id>` room phía backend): truyền [token] khi [connect].
class SocketIoService {
  io.Socket? _socket;
  String? _url;
  String? _token;

  /// Lưu các listener đã đăng ký để tái gắn khi kết nối lại.
  final Map<String, List<dynamic Function(dynamic)>> _listeners = {};

  bool get isConnected => _socket?.connected ?? false;

  /// Kết nối tới [url], kèm JWT [token] (nếu có) để backend join room `user:<id>`.
  ///
  /// Token được gửi qua **hai kênh** để tối đa khả năng backend xác thực được:
  /// - `auth` object trong CONNECT packet (chuẩn socket.io).
  /// - `?token=` query param (fallback; backend `socket.handler.js` đọc cả
  ///   `handshake.auth.token` lẫn `handshake.query.token`). Tránh việc socket
  ///   kết nối nhưng không join room → mất event scoped (`user:<id>`) khi thiết
  ///   bị đã pair, dẫn tới "không realtime, phải re-login mới thấy".
  ///
  /// Websocket transport, tự động reconnect (nhiều lần, delay 1s) để hồi phục
  /// sau lỗi mạng tạm thời mà không cần re-login.
  void connect(String url, {String? token}) {
    if (_socket?.connected == true && _url == url && _token == token) return;

    dispose();
    _url = url;
    _token = token;

    final hasToken = token != null && token.isNotEmpty;
    final builder = io.OptionBuilder()
        .setTransports(['websocket'])
        // forceNew: mỗi connect() tạo Manager mới, không tái dùng Manager đã
        // dispose (đóng, skipReconnect=true) trong cache nội bộ socket_io_client.
        // Không có flag này, socket tạo sau reauthenticate(relogin) không kết nối
        // lại backend → mất realtime cho đến khi app cold-start.
        .enableForceNew()
        .enableAutoConnect()
        .enableReconnection()
        .setReconnectionAttempts(60)
        .setReconnectionDelay(1000)
        .setTimeout(5000);
    if (hasToken) {
      builder.setAuth({'token': token}).setQuery({'token': token});
    }
    _socket = io.io(url, builder.build());

    // Tái gắn listener đã đăng ký trước connect.
    _listeners.forEach((event, handlers) {
      for (final handler in handlers) {
        _socket!.on(event, handler);
      }
    });

    // Log chẩn đoán: có token = mong đợi backend log "joined room user:<id>";
    // không token = backend sẽ log "unauthenticated" (không nhận event scoped).
    _socket!.onConnect((_) => debugPrint(
        '✅ Socket connected: $url (auth=${hasToken ? "token" : "anonymous"})'));
    _socket!.onDisconnect((_) => debugPrint('⚠️ Socket disconnected'));
    _socket!.onConnectError((error) =>
        debugPrint('❌ Socket connection error: $error'));
    _socket!.onError((error) => debugPrint('❌ Socket error: $error'));
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