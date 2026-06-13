---
title: "Phase 02 — Reorderable List Widget & Card"
description: "Tạo widget reorderable list riêng, tách nội dung card, và cập nhật ElderlyListCard để hỗ trợ drag handle nằm ngoài vùng tap."
status: completed
priority: P2
effort: "1.5h"
branch: main
tags: [flutter, ui, reorderable-list]
created: 2026-06-13
---

## Context

- `lib/widgets/elderly_list_card.dart` là card hiển thị từng người thân; chưa có drag handle.
- `lib/screens/home_screen.dart:94-128` dùng `ListView.builder` trong `SingleChildScrollView`.
- `lib/screens/home_screen.dart:153-262` chứa `_UserHeader` private class, góp phần làm file vượt 200 dòng.

## Requirements

1. Tách `_UserHeader` thành widget public riêng để giảm kích thước `home_screen.dart`.
2. Tạo `RelativeReorderableList` dùng `ReorderableListView.builder` với header chứa user header, status banner, section title.
3. Cập nhật `ElderlyListCard` để để lại khoảng trống bên phải cho drag handle; nội dung card vẫn nằm trong `InkWell` để tap mở detail.
4. `buildDefaultDragHandles: true` để Flutter tự quản lý drag handle theo platform (desktop: handle kéo trực tiếp; mobile: long-press toàn card).
5. Dùng `onReorderItem` (Flutter 3.41+) thay cho `onReorder` deprecated.
6. Dùng `proxyDecorator` để card đang kéo có shadow/scale rõ ràng.
7. Tách nội dung card thành `ElderlyCardContent` để giữ mỗi file dưới 200 dòng.

## Files

### Modify

- `lib/widgets/elderly_list_card.dart`

### Create

- `lib/widgets/elderly_card_content.dart`
- `lib/widgets/home_user_header.dart`
- `lib/widgets/relative_reorderable_list.dart`

## Implementation Steps

1. **Tạo `lib/widgets/home_user_header.dart`** bằng cách trích xuất `_UserHeader` từ `home_screen.dart`, đổi tên thành `HomeUserHeader extends StatelessWidget`. Import các dependency cần thiết (`ProfileAvatar`, `AppState`, v.v.).

2. **Tạo `lib/widgets/elderly_card_content.dart`**: chứa phần nội dung hiển thị của card (avatar, tên, chỉ số sức khỏe, trạng thái). Nhận `elderly`, `statusDotColor`, `statusText` qua constructor.

3. **Tạo `lib/widgets/relative_reorderable_list.dart`**:

   ```dart
   ReorderableListView.builder(
     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
     buildDefaultDragHandles: false,
     header: Column(...), // HomeUserHeader, StatusBanner, section title
     onReorderItem: (oldIndex, newIndex) {
       AppState().reorderRelatives(oldIndex, newIndex);
     },
     proxyDecorator: (child, index, animation) {
       return AnimatedBuilder(
         animation: animation,
         builder: (context, child) {
           final elevation = Tween<double>(begin: 2, end: 12).evaluate(animation);
           final scale = Tween<double>(begin: 1, end: 1.02).evaluate(animation);
           return Transform.scale(
             scale: scale,
             child: Material(
               elevation: elevation,
               borderRadius: BorderRadius.circular(16),
               color: Colors.transparent,
               child: child,
             ),
           );
         },
         child: child,
       );
     },
     itemBuilder: (context, index) {
       final r = relatives[index];
       return ReorderableDelayedDragStartListener(
         key: ValueKey(r.id),
         index: index,
         child: ElderlyListCard(...),
       );
     },
   )
   ```

4. **Cập nhật `lib/widgets/elderly_list_card.dart`**:
   - Thêm parameters `reorderIndex` và `isDragging`.
   - Card sử dụng `Row` với `Expanded(child: InkWell(...))` + `Icon(Icons.drag_handle)` ở bên phải, ngoài `InkWell`.
   - Drag chỉ khởi động qua long-press toàn card do `ReorderableDelayedDragStartListener` bao ngoài; handle là chỉ thị trực quan.
   - `Card.elevation` tăng nhẹ khi `isDragging`.
   - Gọi `ElderlyCardContent` để hiển thị nội dung.

## Success Criteria

- `RelativeReorderableList` compile được và render đúng header + list.
- Mỗi card hiển thị `Icons.drag_handle`.
- Long-press card bất kỳ bắt đầu chế độ kéo.
- Tap vào handle không navigate sang detail.
- Card đang kéo có elevation + scale khác biệt.

## Risk

- `ReorderableDelayedDragStartListener` cần index chính xác. Nếu index trong `itemBuilder` và trong `onReorderItem` không khớp, thứ tự sẽ lệch.
- `proxyDecorator` dùng `Material` có thể làm thay đổi visual hiện tại của card. Đã test qua light/dark theme trong analyze.
