import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../application/services/notification_service.dart';
import '../../data/models/care_alert_model.dart';
import '../../domain/entities/care_alert.dart';

/// Holds the list of realtime alerts received from Socket.IO.
///
/// Newest alerts appear first. Critical alerts trigger a local
/// push notification.
class CareAlertsNotifier extends StateNotifier<List<CareAlert>> {
  final NotificationService _notificationService;

  CareAlertsNotifier({required NotificationService notificationService})
      : _notificationService = notificationService,
        super([]);

  void handleRealtimeEvent(String event, Map<String, dynamic> payload) {
    final type = _mapEventType(event, payload);
    final alert = CareAlertModel.fromJson({...payload, 'type': type}).toEntity();
    _addAlert(alert);
  }

  void loadFromHistory(List<CareAlert> history) {
    final merged = [...history, ...state];
    merged.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    _trimAndSet(merged);
  }

  void markAsRead(String id) {
    state = state.map((alert) {
      return alert.id == id ? alert.copyWith(isRead: true) : alert;
    }).toList();
  }

  void clear() {
    state = [];
  }

  void _addAlert(CareAlert alert) {
    if (state.any((a) => a.id == alert.id)) return;

    final newState = [alert, ...state];
    _trimAndSet(newState);

    if (alert.isCritical) {
      _showNotification(alert);
    }
  }

  void _trimAndSet(List<CareAlert> alerts) {
    final trimmed = alerts.take(AppConstants.maxAlertsInMemory).toList();
    state = UnmodifiableListView(trimmed);
  }

  String _mapEventType(String event, Map<String, dynamic> payload) {
    if (event == 'sos:alert') return 'SOS';
    if (event == 'event:fall') return 'FALL_DETECTED';
    if (event == 'event:heart_rate') return 'HEART_RATE_ALERT';
    return payload['type'] as String? ?? event;
  }

  void _showNotification(CareAlert alert) {
    String title;
    switch (alert.type) {
      case 'SOS':
        title = '🆘 Cảnh báo SOS';
        break;
      case 'FALL_DETECTED':
        title = '⚠️ Phát hiện té ngã';
        break;
      case 'HEART_RATE_ALERT':
        title = '❤️ Nhịp tim bất thường';
        break;
      default:
        title = 'SOS Care Alert';
    }

    _notificationService.showAlertNotification(
      title: title,
      body:
          'Thiết bị ${alert.elderlyId} tại ${alert.latitude.toStringAsFixed(5)}, ${alert.longitude.toStringAsFixed(5)}',
      payload: alert.id,
    );
  }
}
