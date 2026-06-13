---
title: "Phase 03 — HomeScreen Wiring"
description: "Thay thế ListView.builder và SingleChildScrollView cũ bằng RelativeReorderableList."
status: completed
priority: P2
effort: "1h"
branch: main
tags: [flutter, ui, screen]
created: 2026-06-13
---

## Context

- `lib/screens/home_screen.dart:94-128` hiện dùng `SingleChildScrollView` → `Column` → `ListView.builder`.
- `lib/screens/home_screen.dart:153-262` chứa `_UserHeader`, cần xóa sau khi đã tách sang `home_user_header.dart`.

## Requirements

1. Giữ nguyên logic auto-push alert (`lib/screens/home_screen.dart:38-72`) và tính toán `overallStatus`.
2. Thay body của `Scaffold` bằng `RelativeReorderableList`.
3. Loại bỏ `_UserHeader`, `_buildSectionHeader`, `SingleChildScrollView`, `ListView.builder` khỏi `home_screen.dart`.
4. Cập nhật import: thêm `relative_reorderable_list.dart`; xóa import không còn dùng (`elderly_list_card`, `profile_avatar`, `status_banner` nếu đã chuyển sang widget mới).
5. File `home_screen.dart` phải dưới 200 dòng sau refactor.

## Files

### Modify

- `lib/screens/home_screen.dart`

## Implementation Steps

1. Mở `lib/screens/home_screen.dart`.
2. Thay toàn bộ block `Scaffold.body` từ dòng 94–131 thành:

   ```dart
   body: RelativeReorderableList(
     relatives: relatives,
     overallStatus: overallStatus,
     selectedElderlyId: _selectedElderlyId,
     onTap: (id) {
       Navigator.push(
         context,
         MaterialPageRoute(builder: (_) => DetailScreen(elderlyId: id)),
       );
     },
     onLocateTap: (id) {
       setState(() {
         _selectedElderlyId = id;
       });
     },
   ),
   ```

3. Xóa method `_buildSectionHeader` và class `_UserHeader` khỏi file.
4. Cập nhật imports:
   - Thêm: `import '../widgets/relative_reorderable_list.dart';`
   - Xóa: `elderly_list_card.dart`, `profile_avatar.dart`, `status_banner.dart` nếu không còn dùng trực tiếp.
   - Giữ lại `sos_app_header.dart`, `add_relative_dialog.dart`, `detail_screen.dart`, `alert_detail_screen.dart`, `profile_screen.dart`, `app_state.dart`, `localization.dart`.

## Success Criteria

- `home_screen.dart` < 200 dòng.
- `flutter analyze` không báo unused import.
- Màn hình chính hiển thị đúng và có thể kéo thả.
- Tap card vẫn navigate đến `DetailScreen`.
- Tap locate vẫn cập nhật `_selectedElderlyId`.

## Risk

- `ReorderableListView` tự quản lý scroll. Nếu header quá cao có thể gây scroll jump khi drag. Test trên thiết bị thật.
- Xóa import nhầm có thể gây lỗi compile. Sau refactor chạy `flutter analyze` ngay.
