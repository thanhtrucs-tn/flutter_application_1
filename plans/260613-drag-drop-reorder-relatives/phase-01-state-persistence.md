---
title: "Phase 01 — State & Persistence"
description: "Thêm khả năng reorder vào AppState và đảm bảo thứ tự mới được lưu xuống SharedPreferences."
status: completed
priority: P2
effort: "1h"
branch: main
tags: [flutter, state-management, shared-preferences]
created: 2026-06-13
---

## Context

- `lib/utils/app_state.dart:156-223` quản lý danh sách `_relatives` và đã có `_saveElderlyData()`, `addElderly()`, `updateElderly()`.
- Dữ liệu lưu tại key `offline_elderly_v2` (`lib/utils/app_state.dart:160`).
- Thứ tự ngầm định là thứ tự phần tử trong JSON array; không cần thêm trường mới.

## Requirements

1. Thêm phương thức công khai để UI gọi reorder.
2. Thứ tự mới phải được lưu xuống `SharedPreferences` ngay sau khi reorder.
3. Xử lý đúng index từ `ReorderableListView.onReorderItem` (Flutter 3.41+ đã tự điều chỉnh `newIndex`).
4. Không phá vỡ các hàm hiện có (`addElderly`, `updateElderly`, `simulateDeviceOnline`).

## Files

### Modify

- `lib/utils/app_state.dart`

## Implementation Steps

1. Mở `lib/utils/app_state.dart`.
2. Sau `_saveElderlyData()`, thêm wrapper công khai:

   ```dart
   /// Public entry để lưu danh sách người thân hiện tại xuống SharedPreferences.
   Future<void> persistRelatives() => _saveElderlyData();
   ```

3. Thêm phương thức `reorderRelatives` trực tiếp trong `AppState`:

   ```dart
   void reorderRelatives(int oldIndex, int newIndex) {
     if (oldIndex < 0 || oldIndex >= _relatives.length) return;
     if (newIndex < 0 || newIndex > _relatives.length) return;
     if (oldIndex == newIndex) return;

     final moved = _relatives.removeAt(oldIndex);
     _relatives.insert(newIndex, moved);

     notifyListeners();
     persistRelatives().catchError((e) {
       debugPrint('Lỗi lưu thứ tự người thân: $e');
     });
   }
   ```

4. Đảm bảo `home_screen.dart` import `app_state.dart` để gọi `AppState().reorderRelatives(...)`.

## Success Criteria

- `AppState().reorderRelatives(0, 2)` trên list `[1,2,3]` cho ra `[2,3,1]` (newIndex đã được điều chỉnh bởi `onReorderItem`).
- `AppState().reorderRelatives(2, 0)` trên list `[1,2,3]` cho ra `[3,1,2]`.
- Sau reorder, `SharedPreferences.getString('offline_elderly_v2')` JSON thứ tự khớp với `_relatives`.

## Risk

- **Race với `_saveElderlyData()` async**: `reorderRelatives` gọi `persistRelatives()` không `await`. Đã thêm `.catchError(...)` để ghi log khi lưu thất bại. Dart single-threaded đảm bảo mutation trên list không xảy ra race.
