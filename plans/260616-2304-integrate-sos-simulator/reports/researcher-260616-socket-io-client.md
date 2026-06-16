# Research: Integrating `socket_io_client` for SOS Simulator Events

## 1. Recommended package version

- Use `socket_io_client: ^2.0.0` (stable) for Socket.IO server v4.8.1 compatibility.
- `2.0.0` implements the Socket.IO v4 client protocol and works with Dart `^3.12.0` / Flutter `>=3.41.0`.
- `3.0.0-beta.2` exists but is pre-release; adopt only if you need specific beta fixes and can tolerate breaking changes.
- Add to `pubspec.yaml` under `dependencies`, then run `flutter pub get`.

## 2. Connecting and subscribing to events

Create a thin service that owns the Socket.IO client and forwards parsed events to `AppState`.

```dart
import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketIoService {
  io.Socket? _socket;

  void connect(String url) {
    _socket?.disconnect();
    _socket = io.io(url, io.OptionBuilder()
        .setTransports(['websocket'])
        .enableAutoConnect()
        .enableReconnection()
        .setReconnectionAttempts(10)
        .setReconnectionDelay(1000)
        .build());

    _socket!
      ..onConnect((_) => print('Socket connected: ${_socket?.id}'))
      ..onDisconnect((_) => print('Socket disconnected'))
      ..onReconnect((_) => print('Socket reconnected'))
      ..onReconnectError((e) => print('Reconnect error: $e'))
      ..onReconnectFailed((_) => print('Reconnect failed'))
      ..onConnectError((e) => print('Connect error: $e'))
      ..onError((e) => print('Socket error: $e'));
  }

  void on(String event, void Function(dynamic) handler) {
    _socket?.on(event, handler);
  }

  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
```

Subscribe after creating `AppState` (e.g. in `main.dart` before `runApp` or from a provider init):

```dart
final socketService = SocketIoService();
socketService.connect('http://localhost:8080');
socketService.on('sos:alert', (data) => _handleSos(data));
socketService.on('event:fall', (data) => _handleFall(data));
socketService.on('event:heart_rate', (data) => _handleHeartRate(data));
socketService.on('device:location', (data) => _handleLocation(data));
socketService.on('device:status', (data) => _handleStatus(data));
```

## 3. Safe payload parsing

Socket.IO payloads arrive as dynamic JSON. Cast to `Map<String, dynamic>` and parse defensively.

```dart
Map<String, dynamic> _asMap(dynamic data) {
  if (data is Map) {
    return data.map((k, v) => MapEntry(k.toString(), v));
  }
  return {};
}

String? _string(Map<String, dynamic> map, String key) {
  final v = map[key];
  return v is String ? v : null;
}

double? _double(Map<String, dynamic> map, String key) {
  final v = map[key];
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

int? _int(Map<String, dynamic> map, String key) {
  final v = map[key];
  if (v is int) return v;
  if (v is String) return int.tryParse(v);
  return null;
}

DateTime? _timestamp(Map<String, dynamic> map, String key) {
  final v = _string(map, key);
  if (v == null) return null;
  return DateTime.tryParse(v);
}
```

Example handler forwarding to `AppState`:

```dart
void _handleSos(dynamic data) {
  final map = _asMap(data);
  final elderlyIdStr = _string(map, 'elderlyId');
  final lat = _double(map, 'latitude');
  final lng = _double(map, 'longitude');
  final ts = _timestamp(map, 'timestamp') ?? DateTime.now();
  if (elderlyIdStr == null || lat == null || lng == null) return;

  final elderlyId = _resolveElderlyId(elderlyIdStr);
  if (elderlyId == null) return; // or create temp relative

  AppState().triggerSOS(
    elderlyId,
    'SOS từ thiết bị ${_string(map, 'deviceId') ?? 'không xác định'}',
    'critical',
    lat,
    lng,
  );
}
```

## 4. Mapping string `elderlyId` to `ElderlyModel.id`

`ElderlyModel.id` is `int`. The backend sends `elderlyId` as a string such as `"ELDERLY-001"`. Decide a deterministic mapping strategy.

Recommended approaches, in order:

1. **Match by a stored external ID.** If `ElderlyModel` later adds a `deviceId`/`externalId` field, match on that. Cleanest long-term solution.
2. **Parse the numeric suffix.** If the simulator always sends `"ELDERLY-NNN"`, extract `NNN` with `int.tryParse(elderlyId.replaceFirst('ELDERLY-', ''))`. Fragile if the prefix changes.
3. **Match by name / device serial.** If `deviceId` is a wearable serial already recorded on the elderly card, match `deviceId` to `wearableDevice`.
4. **Create a temporary relative** when no match exists. Useful for demos: insert an `ElderlyModel` with a generated negative id (`-timestamp`) so the alert still renders, then flag it as temporary in the UI.

Short-term helper using suffix parsing:

```dart
int? _resolveElderlyId(String elderlyId) {
  final appState = AppState();
  // Try matching a numeric suffix first.
  final numeric = int.tryParse(elderlyId.replaceFirst(RegExp(r'^ELDERLY-'), ''));
  if (numeric != null && appState.relatives.any((e) => e.id == numeric)) {
    return numeric;
  }
  // Fallback: match by wearableDevice / deviceId if available.
  // final match = appState.relatives.firstWhereOrNull((e) => e.wearableDevice == deviceId);
  return null;
}
```

Forward unmatched events to `AppState` as a temporary relative only if the product team accepts demo-only records polluting the relative list.

## 5. Key pitfalls

| Pitfall | Mitigation |
|---|---|
| Android emulator cannot reach `localhost` | Use `http://10.0.2.2:8080` for Android emulator. |
| iOS simulator / desktop / web | `http://localhost:8080` works. |
| Windows desktop loopback with firewall | Ensure Node.js is allowed through Windows Defender Firewall; test with `curl http://localhost:8080`. |
| CORS / transport negotiation failures | Force `transports: ['websocket']` (shown above) unless the server explicitly supports polling. |
| Server namespace | If the backend uses a namespace (e.g. `/sos`), append it to the URL: `http://localhost:8080/sos`. Verify with backend code. |
| Background disconnect | Socket.IO disconnects when the app is backgrounded. Reconnection is automatic by default; avoid critical logic that assumes an always-open socket. |
| Hot reload leaves old sockets | Keep a single `SocketIoService` instance (singleton or provided via `ChangeNotifier`/`Provider`) and dispose the old socket before creating a new one. |
| Payload shape drift | The simulator models (`SosPayloadModel`, `EventPayloadModel`, etc.) confirm fields. If the Node backend adds/renames fields, the `_string` / `_double` helpers return null rather than crash. |
| No network security config for cleartext HTTP | Android requires `android:usesCleartextTraffic="true"` in `AndroidManifest.xml` for `http://` (not `https`). |

## 6. Code style / architecture notes

- `AppState` is already a `ChangeNotifier` singleton. The Socket.IO service should not hold UI state or call `notifyListeners()` directly.
- Service responsibilities only: connect, subscribe, parse, call `AppState` mutation methods (`triggerSOS`, `updateElderly`, `addElderly`, etc.).
- Let widgets continue to watch `AppState` via existing `AnimatedBuilder` / `ListenableBuilder` / `Provider` setup.
- Wrap platform-specific host resolution in a small helper so `localhost` is replaced by `10.0.2.2` only on Android emulator builds.
- Avoid passing `BuildContext` into the service.

## Unanswered questions

- Does the Node.js backend use the default namespace or a custom namespace such as `/sos`?
- Is `elderlyId` always formatted as `ELDERLY-NNN`, or can it be an arbitrary string / UUID?
- Should unmatched `elderlyId` values create a temporary relative record, or should those events be silently ignored?
- Is the Node backend currently emitting `event:heart_rate` with heart-rate-specific fields, or is it reusing the generic `EventPayloadModel` schema shown in the simulator?
