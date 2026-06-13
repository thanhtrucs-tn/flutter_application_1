import 'package:flutter/material.dart';
import '../models/elderly_model.dart';
import '../utils/localization.dart';
import 'delete_relative_confirmation_dialog.dart';
import 'elderly_card_content.dart';

/// Card hiển thị thông tin người cao tuổi trong danh sách Home.
///
/// Trên mobile, card được bọc trong [ReorderableDelayedDragStartListener] ở
/// ngoài, nên người dùng có thể nhấn giữ bất kỳ đâu trên thẻ để kéo thả.
/// Trên desktop/web, handle kéo ([ReorderableDragStartListener]) hiển thị bên
/// phải thẻ vì chuột không có UX nhấn giữ toàn card như mobile.
///
/// Phần nội dung dùng [GestureDetector] với [HitTestBehavior.translucent] để
/// tap mở chi tiết mà không cạnh tranh gesture nhấn giữ của listener cha.
class ElderlyListCard extends StatelessWidget {
  final ElderlyModel elderly;
  final bool isSelected;
  final bool isAdmin;
  final VoidCallback onTap;
  final int? reorderIndex;
  final bool showDragHandle;

  const ElderlyListCard({
    super.key,
    required this.elderly,
    required this.isSelected,
    this.isAdmin = false,
    required this.onTap,
    this.reorderIndex,
    this.showDragHandle = false,
  });

  @override
  Widget build(BuildContext context) {
    final (cardBorderColor, statusDotColor, statusText) = _resolveStatus();

    final content = Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? statusDotColor : cardBorderColor,
          width: isSelected ? 2.5 : 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 14, showDragHandle ? 48 : 16, 14),
            child: Stack(
              children: [
                ElderlyCardContent(
                  elderly: elderly,
                  statusDotColor: statusDotColor,
                  statusText: statusText,
                ),
                if (isAdmin)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: _buildPopupMenu(context),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!showDragHandle || reorderIndex == null) {
      return content;
    }

    return Stack(
      key: key,
      children: [
        content,
        Positioned.fill(
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ReorderableDragStartListener(
                index: reorderIndex!,
                child: const Icon(Icons.drag_handle, color: Colors.grey),
              ),
            ),
          ),
        ),
      ],
    );
  }

  (Color, Color, String) _resolveStatus() {
    if (elderly.isOffline) {
      return (
        Colors.grey.shade400,
        Colors.grey,
        Localization.translate('statusOffline'),
      );
    }
    if (elderly.status == 'critical') {
      return (
        const Color(0xFFEF4444),
        const Color(0xFFEF4444),
        Localization.translate('statusCriticalText'),
      );
    }
    if (elderly.status == 'warning') {
      return (
        const Color(0xFFF59E0B),
        const Color(0xFFF59E0B),
        Localization.translate('statusWarningText'),
      );
    }
    return (
      Colors.grey.shade300,
      const Color(0xFF10B981),
      Localization.translate('statusSafeText'),
    );
  }

  Widget _buildPopupMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.grey),
      tooltip: Localization.translate('manageRelatives'),
      onSelected: (_) => DeleteRelativeConfirmationDialog.show(context, elderly),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete_outline, color: Color(0xFFE53935), size: 20),
              const SizedBox(width: 12),
              Text(
                Localization.translate('deleteRelative'),
                style: const TextStyle(color: Color(0xFFE53935)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
