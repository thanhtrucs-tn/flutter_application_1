import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/models/alert_model.dart';
import 'package:flutter_application_1/models/elderly_model.dart';
import 'package:flutter_application_1/utils/app_state.dart';

ElderlyModel _buildElderly(int id) => ElderlyModel(
      id: id,
      name: 'Elderly $id',
      avatar: '',
      battery: 80,
      lastUpdated: DateTime.now(),
      status: 'safe',
      latitude: 10.762622,
      longitude: 106.660172,
      heartRate: 75,
      spo2: 98,
      isOffline: false,
      wearableDevice: 'ESP32',
      isFallen: false,
      safeZoneRadius: 500,
      safeZoneLat: 10.762622,
      safeZoneLng: 106.660172,
      emergencyContacts: [],
      address: '',
    );

AlertModel _buildAlert(int elderlyId) => AlertModel(
      id: 'alert_$elderlyId',
      elderlyId: elderlyId,
      elderlyName: 'Elderly $elderlyId',
      time: DateTime.now(),
      locationName: 'Test location',
      urgency: 'critical',
      message: 'Test alert',
      acknowledged: false,
      latitude: 10.762622,
      longitude: 106.660172,
    );

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('reorderRelatives di chuyển item và lưu thứ tự mới', () async {
    final state = AppState();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    state.stopSimulation();

    state.relatives
      ..clear()
      ..addAll([
        _buildElderly(1),
        _buildElderly(2),
        _buildElderly(3),
      ]);

    // [1,2,3]: kéo item 0 xuống sau vị trí 2 (adjusted newIndex = 2)
    state.reorderRelatives(0, 2);

    expect(state.relatives[0].id, 2);
    expect(state.relatives[1].id, 3);
    expect(state.relatives[2].id, 1);

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('offline_elderly_v2');
    expect(raw, isNotNull);
    final saved = json.decode(raw!) as List;
    expect(saved[0]['id'], 2);
    expect(saved[1]['id'], 3);
    expect(saved[2]['id'], 1);
  });

  test('reorderRelatives kéo item cuối lên đầu', () {
    final state = AppState();
    state.stopSimulation();

    state.relatives
      ..clear()
      ..addAll([
        _buildElderly(1),
        _buildElderly(2),
        _buildElderly(3),
      ]);

    // [1,2,3]: kéo item 2 lên vị trí 0
    state.reorderRelatives(2, 0);

    expect(state.relatives[0].id, 3);
    expect(state.relatives[1].id, 1);
    expect(state.relatives[2].id, 2);
  });

  test('reorderRelatives không làm gì khi index không hợp lệ', () async {
    final state = AppState();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    state.stopSimulation();

    state.relatives
      ..clear()
      ..addAll([
        _buildElderly(1),
        _buildElderly(2),
      ]);

    state.reorderRelatives(-1, 1);
    expect(state.relatives[0].id, 1);
    expect(state.relatives[1].id, 2);
  });

  test('deleteElderly xóa người thân theo id và lưu danh sách mới', () async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    state.stopSimulation();

    state.relatives
      ..clear()
      ..addAll([
        _buildElderly(1),
        _buildElderly(2),
      ]);

    final deleted = await state.deleteElderly(1);

    expect(deleted, true);
    expect(state.relatives.length, 1);
    expect(state.relatives.any((e) => e.id == 1), false);
    expect(state.relatives.any((e) => e.id == 2), true);

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('offline_elderly_v2');
    expect(raw, isNotNull);
    final saved = json.decode(raw!) as List;
    expect(saved.length, 1);
    expect(saved.first['id'], 2);
  });

  test('deleteElderly xóa cảnh báo liên kết và active alert', () async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    state.stopSimulation();

    state.relatives
      ..clear()
      ..addAll([
        _buildElderly(1),
        _buildElderly(2),
      ]);
    state.alerts
      ..clear()
      ..addAll([
        _buildAlert(1),
        _buildAlert(2),
      ]);

    state.triggerSOS(1, 'SOS test', 'critical', 10.762622, 106.660172);
    expect(state.activeAlert, isNotNull);
    expect(state.activeAlert!.elderlyId, 1);

    await state.deleteElderly(1);

    expect(state.alerts.any((a) => a.elderlyId == 1), false);
    expect(state.alerts.length, 1);
    expect(state.alerts.first.elderlyId, 2);
    expect(state.activeAlert, isNull);
  });

  test('deleteElderly trả về false khi không tìm thấy id', () async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    state.stopSimulation();

    state.relatives
      ..clear()
      ..addAll([
        _buildElderly(1),
      ]);

    final deleted = await state.deleteElderly(999);
    expect(deleted, false);
    expect(state.relatives.length, 1);
  });
}
