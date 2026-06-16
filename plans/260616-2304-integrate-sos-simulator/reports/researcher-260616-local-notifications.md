# Research: `flutter_local_notifications` for SOS/fall/heart-rate alerts

## 1. Version and dependencies

Use `flutter_local_notifications: ^22.0.1` (latest). Requires Flutter SDK `>= 3.38.1`, so it satisfies this project’s `flutter: ">=3.41.0"`. The main package automatically pulls in `flutter_local_notifications_windows`; no extra Windows dependency is needed.

Android build requirements:
- `compileSdk >= 35` (example uses 36). This project currently uses `flutter.compileSdkVersion` in `android/app/build.gradle.kts`; verify it is >= 35.
- AGP `>= 8.11.1`.
- Java 17 (already configured).
- `coreLibraryDesugaringEnabled true` plus `com.android.tools:desugar_jdk_libs:2.1.4`, even without scheduled notifications.

## 2. Android manifest

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.VIBRATE" />
```

For high-urgency, on-lock-screen takeover, also add to `MainActivity`:

```xml
android:showWhenLocked="true"
android:turnScreenOn="true"
```

No scheduled-notification receivers are needed because events are realtime.

## 3. iOS setup

No `Info.plist` entries are required. In `ios/Runner/AppDelegate.swift`:

```swift
import flutter_local_notifications

UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
    GeneratedPluginRegistrant.register(with: registry)
}
```

iOS suppresses notifications while the app is in the foreground unless the delegate is set. For iOS 15+ time-sensitive alerts, enable the Time Sensitive Notifications capability in Xcode.

## 4. Windows setup and limitations

Add `WindowsInitializationSettings` in Dart only. No native manifest changes.

Limitations:
- Repeating notifications are unsupported (`UnsupportedError`).
- `cancel()` / `getActiveNotifications()` only work for MSIX-packaged apps.
- Actions run on the main isolate.
- Windows toast notifications appear in Action Center, not as Android-style heads-up banners.

## 5. Initialization and showing notifications

In `lib/main.dart`, before `runApp`:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final plugin = FlutterLocalNotificationsPlugin();

  await plugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('sos_notification_icon'),
      iOS: DarwinInitializationSettings(),
      macOS: DarwinInitializationSettings(),
      windows: WindowsInitializationSettings(
        appName: 'SOS Care',
        appUserModelId: 'Com.Example.SosCare',
        guid: 'your-generated-guid-here',
      ),
    ),
  );

  await plugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();

  await plugin
      .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(alert: true, badge: true, sound: true);

  runApp(const MyApp());
}
```

Show from any service class by keeping the plugin instance:

```dart
const androidDetails = AndroidNotificationDetails(
  'sos_alerts',
  'SOS / Fall / Heart-rate alerts',
  channelDescription: 'Urgent caregiver alerts',
  importance: Importance.max,
  priority: Priority.high,
  icon: 'sos_notification_icon',
);

await plugin.show(id, title, body, const NotificationDetails(android: androidDetails));
```

## 6. Recommended channel, importance, and icon

- Channel id: `sos_alerts`.
- Channel name: `SOS / Fall / Heart-rate alerts`.
- Importance: `Importance.max`; priority: `Priority.high` — required for Android heads-up banners.
- Small icon: place a dedicated white/transparent PNG at `android/app/src/main/res/drawable/sos_notification_icon.png` and reference it as `'sos_notification_icon'` (no extension or path).
- Create the channel explicitly once:

```dart
await plugin
    .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
    ?.createNotificationChannel(
      const AndroidNotificationChannel(
        'sos_alerts',
        'SOS / Fall / Heart-rate alerts',
        description: 'Urgent caregiver alerts',
        importance: Importance.max,
      ),
    );
```

Channel settings are immutable after first creation; change the channel id to update importance.

## 7. Foreground service?

No. For this milestone, the backend pushes events over the existing Socket.IO connection and the app does not need to keep a connection alive while backgrounded. A foreground service is only necessary later if the app itself must maintain the socket in the background.

## Sources

- https://pub.dev/packages/flutter_local_notifications
- https://pub.dev/packages/flutter_local_notifications/changelog
- https://pub.dev/packages/flutter_local_notifications_windows
- https://github.com/MaikuB/flutter_local_notifications/blob/master/flutter_local_notifications/example/lib/main.dart

## Unanswered questions

None.
