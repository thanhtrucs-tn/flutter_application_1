import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service hiển thị thông báo nội bộ (local push) cho các sự kiện khẩn cấp
/// từ thiết bị đeo SOS.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Khởi tạo plugin, tạo kênh thông báo và xin quyền trên Android 13+ / iOS.
  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('sos_notification_icon');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const windowsSettings = WindowsInitializationSettings(
      appName: 'SOS Care',
      appUserModelId: 'Com.Example.SosCare',
      guid: 'd1c8f5a0-9e4b-4c3a-8f1e-7d2b6c9a5e1f',
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
      windows: windowsSettings,
    );

    await _plugin.initialize(settings: initSettings);

    const channel = AndroidNotificationChannel(
      'sos_alerts',
      'SOS / Fall / Heart-rate alerts',
      description: 'Thông báo khẩn cấp từ thiết bị đeo SOS',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Xin quyền thông báo trên Android 13+.
    if (!kIsWeb && Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    // Xin quyền trên iOS/macOS.
    if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      await _plugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    _initialized = true;
  }

  /// Hiển thị một thông báo.
  ///
  /// [id] nên là số ổn định theo loại để tránh spam nhiều thông báo.
  Future<void> show({
    required int id,
    required String title,
    required String body,
    bool critical = false,
  }) async {
    if (!_initialized) return;

    final androidDetails = AndroidNotificationDetails(
      'sos_alerts',
      'SOS / Fall / Heart-rate alerts',
      channelDescription: 'Thông báo khẩn cấp từ thiết bị đeo SOS',
      importance: Importance.max,
      priority: Priority.high,
      color: const Color.fromARGB(255, 255, 0, 0),
      showWhen: true,
      autoCancel: true,
      // Bật màn hình và rung mạnh khi critical.
      fullScreenIntent: critical,
      visibility: NotificationVisibility.public,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const windowsDetails = WindowsNotificationDetails();

    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
      windows: windowsDetails,
    );

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }
}
