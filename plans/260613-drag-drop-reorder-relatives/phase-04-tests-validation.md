---
title: "Phase 04 — Tests & Validation"
description: "Viết unit test cho logic reorder, chạy analyze/test, và thực hiện kiểm thử thủ công trên app."
status: completed
priority: P2
effort: "0.5h"
branch: main
tags: [flutter, testing, qa]
created: 2026-06-13
---

## Context

- Logic reorder nằm trong extension `AppStateRelatives`.
- Persistence dùng `SharedPreferences` với key `offline_elderly_v2`.
- `AppState` là singleton; cần cẩn thận khi test để tránh pollution.

## Requirements

1. Viết unit test cho `reorderRelatives`.
2. Đảm bảo `flutter analyze` pass.
3. Đảm bảo `flutter test` pass.
4. Kiểm thử thủ công: long-press, kéo, thả, restart app.

## Files

### Create

- `test/relatives_reorder_test.dart`

## Implementation Steps

1. **Tạo `test/relatives_reorder_test.dart`**:

   ```dart
   import 'dart:convert';
   import 'package:flutter_test/flutter_test.dart';
   import 'package:shared_preferences/shared_preferences.dart';
   import 'package:flutter_application_1/models/elderly_model.dart';
   import 'package:flutter_application_1/utils/app_state.dart';
   import 'package:flutter_application_1/utils/app_state_relatives_extension.dart';

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
         ..addAll([_buildElderly(1), _buildElderly(2), _buildElderly(3)]);

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

     test('reorderRelatives không làm gì khi index không hợp lệ', () {
       final state = AppState();
       state.stopSimulation();

       state.relatives
         ..clear()
         ..addAll([_buildElderly(1), _buildElderly(2)]);

       state.reorderRelatives(-1, 1);
       expect(state.relatives[0].id, 1);
       expect(state.relatives[1].id, 2);
     });
   }
   ```

2. Chạy:
   - `flutter pub get`
   - `flutter analyze`
   - `flutter test`

3. Kiểm thử thủ công trên device/emulator:
   - Mở app → HomeScreen.
   - Nhấn giữ card → kéo lên/xuống → thả.
   - Kiểm tra thứ tự mới.
   - Kill app → mở lại → kiểm tra thứ tự giữ nguyên.

## Success Criteria

- `flutter analyze` 0 issue.
- `flutter test` tất cả pass.
- Thủ công: kéo thả thành công, persistence hoạt động.

## Risk

- Singleton `AppState` có thể giữ trạng thái từ test trước. Giải pháp: mỗi test reset `state.relatives` trực tiếp.
- `SharedPreferences` mock cần được set trước khi `AppState` singleton khởi tạo. Nếu `AppState` đã được tạo trong test khác, mock có thể không áp dụng. Cân nhắc reset singleton hoặc viết helper khởi tạo mới. Hiện tại chấp nhận vì app chỉ có 1 instance runtime.
