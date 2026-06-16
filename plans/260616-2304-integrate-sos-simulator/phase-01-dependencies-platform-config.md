# Phase 01 — Dependencies & Platform Configuration

## Context Links

- `pubspec.yaml`
- `android/app/src/main/AndroidManifest.xml`
- `android/app/build.gradle.kts`
- `ios/Runner/AppDelegate.swift`
- Report: `reports/researcher-260616-local-notifications.md`

## Overview

Add the Dart packages required for Socket.IO and local notifications, then apply the minimum native platform configuration so the app can connect to the backend and display heads-up alerts.

## Key Insights

- `socket_io_client: ^2.0.0` is compatible with the Socket.IO v4.8.1 server and the project’s Flutter SDK (`^3.12.0` / `>=3.41.0`).
- `flutter_local_notifications: ^22.0.1` requires `compileSdk >= 35`, AGP `>= 8.11.1`, Java 17, and `coreLibraryDesugaringEnabled`.
- Android 13+ needs `POST_NOTIFICATIONS`; lock-screen takeover needs `showWhenLocked` + `turnScreenOn` on `MainActivity`.
- The notification small icon must be a white / transparent PNG in `android/app/src/main/res/drawable/sos_notification_icon.png`.

## Requirements

- Functional: `flutter pub get` completes; app can connect over Socket.IO; notifications can be shown.
- Non-functional: native changes must not break existing map / camera / database flows; keep every file under 200 lines.

## Architecture

- `pubspec.yaml` adds two dependencies under `dependencies:`.
- Android native config adds permissions, lock-screen flags, and the notification icon.
- iOS `AppDelegate.swift` sets the notification center delegate.
- Windows uses Dart-only initialization settings in `main.dart` (phase 04).

## Related Code Files

- Modify: `pubspec.yaml`, `android/app/src/main/AndroidManifest.xml`, `android/app/build.gradle.kts`, `ios/Runner/AppDelegate.swift`, `lib/main.dart`.
- Create: `android/app/src/main/res/drawable/sos_notification_icon.png` (and `drawable-*dpi` variants if desired).

## Implementation Steps

1. Add to `pubspec.yaml` under `dependencies:`:
   ```yaml
   socket_io_client: ^2.0.0
   flutter_local_notifications: ^22.0.1
   ```
2. Run `flutter pub get`. Resolve any version conflicts before continuing.
3. In `AndroidManifest.xml` add:
   ```xml
   <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
   <uses-permission android:name="android.permission.VIBRATE" />
   ```
   On `<activity android:name=".MainActivity" ...>` add:
   ```xml
   android:showWhenLocked="true"
   android:turnScreenOn="true"
   ```
4. Add a white/transparent PNG named `sos_notification_icon.png` to `android/app/src/main/res/drawable/` (and density folders).
5. In `android/app/build.gradle.kts`, verify `compileSdk` resolves to `>= 35`; if not set `compileSdk = 35`. Add inside `compileOptions { isCoreLibraryDesugaringEnabled = true }` and the dependency `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")`.
6. In `ios/Runner/AppDelegate.swift` add:
   ```swift
   import flutter_local_notifications
   UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
   FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
       GeneratedPluginRegistrant.register(with: registry)
   }
   ```

## TODO

- [ ] Add packages and run `flutter pub get`.
- [ ] Update Android manifest permissions and `MainActivity` flags.
- [ ] Add `sos_notification_icon.png` to drawable folders.
- [ ] Verify / set `compileSdk` and desugaring in `build.gradle.kts`.
- [ ] Update iOS `AppDelegate.swift`.

## Success Criteria

- `flutter pub get` completes without errors.
- `flutter build apk --debug` succeeds (or `flutter run -d windows` for desktop).
- No compile / build errors introduced by the new packages.

## Risk Assessment

- `flutter_local_notifications` v22 may require a newer Android Gradle Plugin than currently pinned. Mitigation: upgrade AGP to a compatible version or temporarily pin a lower package version if build breaks.
- Desugaring increases build time slightly; acceptable for local development.

## Security Considerations

- `android:usesCleartextTraffic="true"` is already enabled in the manifest; keep it for local HTTP only and do not ship to production.
- No API keys, tokens, or credentials are added to the manifest.

## Next Steps

- Phase 02 to finalize the backend event contract and elderly-id mapping strategy.
