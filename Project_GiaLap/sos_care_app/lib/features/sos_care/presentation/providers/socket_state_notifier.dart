import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Simple connection state used by the UI to show connected/disconnected
/// indicator.
enum SocketConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}

class SocketStateNotifier extends StateNotifier<SocketConnectionState> {
  SocketStateNotifier() : super(SocketConnectionState.disconnected);

  void setConnected() => state = SocketConnectionState.connected;
  void setConnecting() => state = SocketConnectionState.connecting;
  void setDisconnected() => state = SocketConnectionState.disconnected;
  void setError() => state = SocketConnectionState.error;
}
