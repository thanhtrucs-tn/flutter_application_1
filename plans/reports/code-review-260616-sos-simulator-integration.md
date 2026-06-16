# Code Review Report: SOS Device Simulator Integration

**Date:** 2026-06-16  
**Reviewer:** code-reviewer agent  
**Scope:** Connect SOS Device Simulator (`Project_GiaLap/sos_care_backend`) to `flutter_application_1`.

## Files Reviewed

- `lib/services/socket_io_service.dart`
- `lib/services/device_event_service.dart`
- `lib/services/notification_service.dart`
- `lib/utils/app_state.dart` (only `setRealtimeConnection` addition)
- `lib/main.dart`
- `pubspec.yaml`
- `android/app/src/main/AndroidManifest.xml`
- `android/app/build.gradle.kts`
- `android/build.gradle.kts`
- `ios/Runner/AppDelegate.swift`
- `android/app/src/main/res/drawable/sos_notification_icon.xml`

Also spot-checked supporting files:

- `lib/models/elderly_model.dart`
- `android/gradle.properties`
- `macos/Flutter/GeneratedPluginRegistrant.swift`

## Overall Assessment

All listed builds/tests pass (`flutter build apk --debug`, `flutter build windows --debug`, `flutter test`). The integration is functional and defensive parsing is reasonable. There are **no hard blockers**, but the main service file is oversized and a few notification/Socket.IO edge cases should be tightened.

## Blockers (must fix)

None.

## Non-blocking Suggestions (should fix)

### 1. `device_event_service.dart` exceeds 200 lines

**Location:** `lib/services/device_event_service.dart` (294 lines)

The file is well above the 200-line guideline. The five event handlers (`_onSosAlert`, `_onFall`, `_onHeartRateAlert`, `_onLocation`, `_onDeviceStatus`) share a common pattern:

1. `_asMap(data)`
2. `_enterRealMode()`
3. `_resolveOrCreate(...)`
4. `AppState().firstWhere(...)` / update / notify

Extract a single `_processEvent` helper that parses the payload, resolves the elderly, and returns a record `(elderlyId, payload)`, then let each handler do its business-specific work. This would shrink the file and make future event types easier to add.

### 2. Socket listener registration happens after connect

**Location:** `lib/services/socket_io_service.dart:17-47` and `lib/services/device_event_service.dart:26-39`

`_socket.connect()` creates the socket and begins connecting immediately. Listeners are attached only after `connect()` returns. In practice the tiny window is unlikely to drop events, but the safer pattern is to attach listeners before connecting. Consider changing `SocketIoService.connect()` to accept an optional `onConnecting`/`onCreate` callback, or split construction and connection so `DeviceEventService` can register listeners before `connect()` is invoked.

### 3. iOS critical alerts will not bypass Do Not Disturb

**Location:** `lib/services/notification_service.dart:105-109`

`DarwinNotificationDetails` does not set `interruptionLevel` or `criticalSound`. On iOS, a "critical" SOS/fall notification will not bypass Focus/Do Not Disturb without the critical alert entitlement and a critical sound configuration. For a safety app this is a gap.

Recommended: set `DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true, interruptionLevel: InterruptionLevel.critical)` and add the `com.apple.developer.usernotifications.critical-alerts` entitlement in Xcode. Note that this also requires a special provisioning profile from Apple.

### 4. Low-battery notification can reshow repeatedly

**Location:** `lib/services/device_event_service.dart:188-194`

Every `device:status` event with `battery <= 20` triggers a notification. The notification ID is stable per elderly (`_notificationId(elderlyId, 4000)`), so it replaces the previous one rather than spamming the shade, but it still vibrates/sounds on each event. Add a guard so the notification fires only when the battery crosses below 20% (or store/track last battery level) to avoid repeated interruptions.

### 5. `DeviceEventService` is not a singleton

**Location:** `lib/services/device_event_service.dart:12-22`

The service is instantiated once in `main.dart`, but nothing prevents a second instantiation elsewhere from opening another socket. Convert it to a singleton (factory constructor + private internal constructor) to match `NotificationService` and avoid accidental duplicate connections.

### 6. `localhost` rewrite is literal only

**Location:** `lib/services/device_event_service.dart:255-261`

`_resolveBackendUrl` only rewrites the exact string `localhost`. If a developer uses `http://127.0.0.1:8080`, the Android emulator will not reach the host. Consider also rewriting `127.0.0.1` to `10.0.2.2` for Android emulator parity.

### 7. `firstWhere` assumptions

**Location:** `lib/services/device_event_service.dart:87, 120, 152, 174`, `lib/utils/app_state.dart:473, 524`

`firstWhere` is called after `_resolveOrCreate` synchronously adds the elderly, so it is currently safe. However, `firstWhere` throws on missing elements. Consider adding an `orElse` guard or an extension helper such as `firstWhereOrNull` to make future refactors safer.

### 8. `_enterRealMode` is never reset

**Location:** `lib/services/device_event_service.dart:197-202`

Once a real event is received, the local simulation is stopped permanently for the service lifetime. If the user explicitly wants to re-enable simulation after disconnecting from the simulator, there is no path. This is acceptable for the current feature, but document the behavior or expose a reset method if product requirements change.

## What Looks Good

- `socket_io_service.dart` is small, focused, and correctly wraps `socket_io_client`.
- Dynamic payload parsing is defensive (`_asMap`, `_string`, `_double`, `_int`, `_bool`).
- Temporary elderly creation falls back to `wearableDevice` matching, so reconnecting the same simulator device maps to the same temporary relative.
- `main.dart` initialization order is correct: `WidgetsFlutterBinding.ensureInitialized()` → notifications → `AppState` → realtime connection → `runApp`.
- `NotificationService` singleton with `_initialized` guard prevents double init and silently drops notifications before init.
- Android manifest includes `POST_NOTIFICATIONS`, `VIBRATE`, `WAKE_LOCK`, `showWhenLocked`, `turnScreenOn`, and `usesCleartextTraffic` for localhost.
- Android notification channel is created with `Importance.max` and the SOS icon drawable is present.
- iOS `AppDelegate.swift` registers the plugin and sets the notification center delegate.
- Pubspec dependencies (`socket_io_client`, `flutter_local_notifications`) are declared and `GeneratedPluginRegistrant` includes `FlutterLocalNotificationsPlugin`.
- No `.claude` files were modified.

## Unresolved Questions

- Is the iOS critical-alert entitlement (`com.apple.developer.usernotifications.critical-alerts`) intended to be requested from Apple for this app?
- Should the low-battery threshold (20%) be configurable in `AppSettings`?

---

**Status:** DONE_WITH_CONCERNS

**Summary:** Integration is functional and builds pass, but `device_event_service.dart` needs modularization to stay under 200 lines, and iOS/Android notification edge cases (critical alerts, low-battery reshows, listener registration order) should be tightened before treating the feature as production-ready.
