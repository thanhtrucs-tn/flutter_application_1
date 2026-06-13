---
title: "Chức năng sắp xếp người thân bằng kéo thả (Drag & Drop)"
description: "Cho phép Admin nhấn giữ và kéo thả card người thân trên HomeScreen để thay đổi thứ tự danh sách. Thứ tự mới được lưu vào SharedPreferences và khôi phục sau khi khởi động lại ứng dụng."
status: completed
priority: P2
effort: "4h"
branch: main
tags: [flutter, ui, state-management, shared-preferences, reorderable-list, drag-drop]
created: 2026-06-13
---

## Mục tiêu

Thay thế `ListView.builder` hiện tại trên `HomeScreen` bằng widget kéo thả có sẵn của Flutter. Admin có thể nhấn giữ card người thân, di chuyển lên/xuống, và thứ tự mới được lưu lại qua `SharedPreferences`.

## Phases

| # | Phase | Trạng thái | Owner | File chính |
|---|---|---|---|---|
| 1 | State & persistence | completed | Dev B | `lib/utils/app_state.dart` |
| 2 | Reorderable list widget & card | completed | Dev A | `lib/widgets/relative_reorderable_list.dart` + `lib/widgets/elderly_list_card.dart` + `lib/widgets/elderly_card_content.dart` + `lib/widgets/home_user_header.dart` |
| 3 | HomeScreen wiring | completed | Dev A | `lib/screens/home_screen.dart` |
| 4 | Tests & validation | completed | QA | `test/relatives_reorder_test.dart` |

## Dependencies

Không thêm package mới. Dùng widget có sẵn:

- `ReorderableListView`
- `ReorderableDelayedDragStartListener`
- `ReorderableDragStartListener`

## Success Criteria (đo lường được)

1. `flutter analyze` pass 0 issue.
2. `flutter test` pass (bao gồm test mới).
3. Toàn bộ `ElderlyListCard` nhấn giữ được (không cần handle riêng).
4. Nhấn giữ card → card nổi lên → kéo lên/xuống được.
5. Thả tay → danh sách render theo thứ tự mới.
6. `SharedPreferences` key `offline_elderly_v2` lưu đúng thứ tự mới.
7. Kill app → mở lại → thứ tự không đổi.
8. Không file nào vượt 200 dòng; `pubspec.yaml` không đổi.

## Notes

- Implementation dùng `ReorderableListView.builder` với `buildDefaultDragHandles: false`
  và bọc mỗi item trong `ReorderableDelayedDragStartListener`, giúp nhấn giữ
  bất kỳ đâu trên thẻ cũng bắt đầu kéo thả.
- Card không còn drag handle riêng; nội dung card vẫn nằm trong `InkWell` để tap
  mở detail.

## Risk Assessment

| Risk | Khả năng | Tác động | Giảm thiểu |
|---|---|---|---|
| Gesture long-press xung đột với `InkWell.onTap` | Trung bình | Trung bình | Dùng `ReorderableDelayedDragStartListener`; giữ `InkWell.onTap` để navigate. Test tap vẫn hoạt động. |
| Timer simulation cập nhật state khi đang kéo | Thấp | Thấp | Simulation chỉ sửa giá trị chứ không đổi thứ tự; nếu cần thì pause simulation trong `onReorderStart`. |
| Drag handle icon chặn tap navigate | Thấp | Thấp | Handle chỉ chiếm vùng nhỏ ở cuối; tap phần còn lại vẫn navigate. |
| Singleton `AppState` gây pollution giữa các test | Thấp | Thấp | Mỗi test gọi `SharedPreferences.setMockInitialValues({})` và set list ban đầu rõ ràng. |
| Thứ tự xấu được lưu vào SharedPreferences | Thấp | Cao | Rollback bằng cách xóa storage hoặc reload từ `MockData.initialElderly`. |

## Rollback Plan

1. Xóa các file mới:
   - `lib/utils/app_state_relatives_extension.dart`
   - `lib/widgets/relative_reorderable_list.dart`
   - `lib/widgets/home_user_header.dart`
   - `test/relatives_reorder_test.dart`
2. Khôi phục `home_screen.dart`, `elderly_list_card.dart`, `app_state.dart` từ commit trước.
3. Nếu dữ liệu `offline_elderly_v2` bị lỗi thứ tự: xóa app storage hoặc dùng `prefs.remove('offline_elderly_v2')` để load lại từ `MockData.initialElderly`.

## File Ownership

- Dev B: `lib/utils/app_state.dart`, `lib/utils/app_state_relatives_extension.dart`
- Dev A: `lib/widgets/relative_reorderable_list.dart`, `lib/widgets/elderly_list_card.dart`, `lib/widgets/home_user_header.dart`, `lib/screens/home_screen.dart`
- QA: `test/relatives_reorder_test.dart`

Phase A và B có thể chạy song song vì UI chỉ phụ thuộc vào tên phương thức công khai `reorderRelatives`. Phase C phải chờ A và B xong.
