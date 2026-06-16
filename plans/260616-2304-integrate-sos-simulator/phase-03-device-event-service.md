# Phase 03 — Device Event Service (Socket.IO + AppState)

## Context Links

- `lib/main.dart`
- `lib/utils/app_state.dart`
- `lib/services/notification_service.dart` (phase 04)
- Report: `reports/researcher-260616-socket-io-client.md`

## Overview

Build a thin Socket.IO wrapper and a higher-level service that converts backend events into `ElderlyModel` / `AlertModel` mutations via the existing `AppState` singleton.

## Key Insights

- Keep Socket.IO code in a stateless `SocketIoService`; all business logic lives in `DeviceEventService`.
- `AppState` is already a `ChangeNotifier` singleton; services call its mutation methods and never call `notifyListeners()` directly.
- Stop the existing local simulation when the first real event arrives so fake data does not overwrite real values.
- Do not pass `BuildContext` into services.

## Requirements

- Functional: connect to the backend, subscribe to all five events, and update the UI in real time.
- Non-functional: reconnect automatically, handle malformed payloads gracefully, keep each service file under 200 lines.

## Architecture

- `lib/services/socket_io_service.dart`: owns `io.Socket`, exposes `connect(url)`, `on(event, handler)`, `dispose()`.
- `lib/services/device_event_service.dart`: uses `SocketIoService`, parses payloads, resolves elderly, applies mutations, and asks `NotificationService` to show alerts.
- `lib/utils/app_state.dart`: add small public methods `setRealtimeConnection(bool)` and a simulation toggle.
- `lib/main.dart`: initialize and start the service before `runApp`.

## Related Code Files

- Create: `lib/services/socket_io_service.dart`, `lib/services/device_event_service.dart`.
- Modify: `lib/utils/app_state.dart`, `lib/main.dart`.

## Implementation Steps

1. `socket_io_service.dart`:
   - Import `package:socket_io_client/socket_io_client.dart' as io`.
   - Build options with `setTransports(['websocket'])`, `enableAutoConnect()`, `enableReconnection()`, `setReconnectionAttempts(10)`, `setReconnectionDelay(1000)`.
   - Forward lifecycle logs to `debugPrint`.
2. `device_event_service.dart`:
   - Inject `SocketIoService` and `NotificationService`.
   - In `start(String url)`:
     - Resolve host: replace `localhost` with `10.0.2.2` when running on Android emulator.
     - Connect and subscribe to all five events.
     - On any event, call `AppState().setRealtimeConnection(true)` and stop the local simulation.
   - Implement handlers:
     - `sos:alert` → resolve elderly, `AppState().triggerSOS(id, 'SOS khẩn cấp từ thiết bị $deviceId', 'critical', lat, lng)`.
     - `event:fall` → `triggerSOS(..., 'Phát hiện TÉ NGÃ từ thiết bị $deviceId', 'critical', lat, lng)`.
     - `event:heart_rate` → resolve elderly, set status `warning`, create a warning alert via `triggerSOS(..., 'Cảnh báo nhịp tim bất thường', 'warning', lat, lng)`.
     - `device:location` → resolve elderly, `copyWith(latitude: lat, longitude: lng, lastUpdated: now)` and `updateElderly`.
     - `device:status` → resolve elderly, `copyWith(battery: batteryPercent, heartRate: heartRateBpm ?? old, isOffline: !isOnline, lastUpdated: now)` and `updateElderly`; if `batteryPercent <= 20` show low-battery notification.
   - On disconnect / connect error, call `AppState().setRealtimeConnection(false)`.
3. `AppState` additions:
   - `void setRealtimeConnection(bool connected) { _isWebSocketConnected = connected; notifyListeners(); }`
   - Reuse public `stopSimulation()` / `startSimulation()`; add a small helper `setSimulationEnabled(bool)` if convenient.
4. `main.dart`:
   - Keep `WidgetsFlutterBinding.ensureInitialized();` and `AppState();`.
   - After `NotificationService().initialize()` (phase 04), call `DeviceEventService(...).start('http://localhost:8080');`.

## TODO

- [ ] Create `SocketIoService`.
- [ ] Create `DeviceEventService` with five event handlers and mapping helpers.
- [ ] Add `setRealtimeConnection` and simulation toggle to `AppState`.
- [ ] Wire services in `main.dart`.
- [ ] Run app and confirm socket connects via logs.

## Success Criteria

- App logs "Socket connected" shortly after launch.
- Pressing the simulator SOS button creates an active alert and pushes `AlertDetailScreen`.
- Fall button creates a critical alert.
- Battery / location / status events update the elderly card on `HomeScreen` within seconds.

## Risk Assessment

- Hot reload can leak old sockets. Mitigation: keep a single `SocketIoService` instance and dispose the old socket before reconnecting.
- Android emulator cannot reach desktop `localhost`. Mitigation: host helper returns `10.0.2.2:8080`.
- If the backend is not running, the app retries forever; acceptable for local development.

## Security Considerations

- Force `transports: ['websocket']` to avoid unexpected long-polling behavior.
- Do not log raw payloads in release builds; use `debugPrint` only.

## Next Steps

- Phase 04 to add the local notification service.
