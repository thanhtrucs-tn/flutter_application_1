# Phase 04 — Local Notification Service & main.dart Wiring

## Context Links

- `lib/main.dart`
- `lib/services/device_event_service.dart`
- Report: `reports/researcher-260616-local-notifications.md`

## Overview

Add a thin wrapper around `flutter_local_notifications` so SOS, fall, heart-rate, and low-battery events also surface as heads-up notifications outside the app.

## Key Insights

- Initialize the plugin before `runApp` and request runtime permission on Android 13+ / iOS.
- Use a single high-importance channel `sos_alerts` for all urgent events.
- Windows desktop shows Action Center toasts, not Android-style banners; this is acceptable for development.

## Requirements

- Functional: SOS, fall, heart-rate warning, and low-battery events show a notification.
- Non-functional: no widget code changes required; the service is invoked from `DeviceEventService`.

## Architecture

- `lib/services/notification_service.dart`: singleton with `initialize()` and `showSosNotification({id, title, body, bool critical})`.
- `lib/main.dart`: call `NotificationService().initialize()` after `WidgetsFlutterBinding.ensureInitialized()` and before `runApp`.
- `DeviceEventService` calls the notification service when it creates or receives urgent alerts.

## Related Code Files

- Create: `lib/services/notification_service.dart`.
- Modify: `lib/main.dart`.

## Implementation Steps

1. `notification_service.dart`:
   - Hold a `FlutterLocalNotificationsPlugin _plugin`.
   - `initialize()`:
     - `const AndroidInitializationSettings('sos_notification_icon')`
     - `const DarwinInitializationSettings()`
     - `WindowsInitializationSettings(appName: 'SOS Care', appUserModelId: 'Com.Example.SosCare', guid: '<generated-guid-here>')`
     - Call `_plugin.initialize(...)`.
     - Create Android channel `sos_alerts` with `Importance.max`.
     - Request Android permission via `resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission()`.
     - Request iOS permission via `resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(...)`.
   - `show({required int id, required String title, required String body, bool critical = false})`:
     - Build `AndroidNotificationDetails('sos_alerts', 'SOS / Fall / Heart-rate alerts', importance: Importance.max, priority: Priority.high)`.
     - Build `NotificationDetails(android: ..., iOS: const DarwinNotificationDetails(), windows: const WindowsNotificationDetails())`.
     - `_plugin.show(id, title, body, details)`.
2. `main.dart`:
   - `WidgetsFlutterBinding.ensureInitialized();`
   - `await NotificationService().initialize();`
   - Keep existing `AppState();` and `runApp(const MyApp());`.
   - Start `DeviceEventService` after notification initialization.
3. In `DeviceEventService`, call `NotificationService().show(...)` when handling `sos:alert`, `event:fall`, `event:heart_rate`, and low-battery `device:status`.

## TODO

- [ ] Create `NotificationService`.
- [ ] Add `sos_notification_icon.png` to Android drawable folders (phase 01).
- [ ] Update `main.dart` init order: binding → notification → AppState → device event service → runApp.
- [ ] Call notification service from `DeviceEventService` for SOS / fall / heart-rate / low-battery.

## Success Criteria

- Simulator SOS / fall triggers a heads-up notification on Android and a toast on Windows.
- Heart-rate warning and battery `<= 20` events also notify.
- App still builds and existing tests pass.

## Risk Assessment

- Notification permission may be denied on Android 13+. Mitigation: gracefully skip `show()` when permission is missing; the in-app alert still works.
- Windows MSIX is not configured, so `cancel()` / `getActiveNotifications()` are limited; `show()` still works for development.

## Security Considerations

- Notification content should not expose precise GPS coordinates or medical values beyond what the in-app alert already shows.
- No notification history is persisted.

## Next Steps

- Phase 05 for end-to-end testing.
