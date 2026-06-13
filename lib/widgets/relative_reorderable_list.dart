import 'package:flutter/material.dart';
import '../models/elderly_model.dart';
import '../utils/app_state.dart';
import '../utils/localization.dart';
import '../widgets/add_relative_dialog.dart';
import '../widgets/elderly_list_card.dart';
import '../widgets/home_user_header.dart';
import '../widgets/status_banner.dart';

/// Danh sách người thân có hỗ trợ kéo thả sắp xếp lại thứ tự.
///
/// Widget này sử dụng [ReorderableListView] với header cố định (user header,
/// status banner, section title). Mỗi item là một card người thân.
///
/// Toàn bộ thẻ người thân (Family Card) là vùng kéo thả:
/// - Trên mobile: nhấn giữ (~300-500ms) vào bất kỳ vị trí nào bên trong card
///   (avatar, tên, thông tin thiết bị, vùng trống...) để bắt đầu kéo thả.
/// - Trên desktop/web: nhấn và kéo card để sắp xếp lại.
///
/// Card được nâng lên với hiệu ứng elevation/shadow trong khi kéo. Thứ tự mới
/// được lưu qua [AppState] ngay sau khi thả.
class RelativeReorderableList extends StatelessWidget {
  final List<ElderlyModel> relatives;
  final String overallStatus;
  final int selectedElderlyId;
  final ValueChanged<int> onTap;

  const RelativeReorderableList({
    super.key,
    required this.relatives,
    required this.overallStatus,
    required this.selectedElderlyId,
    required this.onTap,
  });

  bool _isMobile(BuildContext context) {
    final platform = Theme.of(context).platform;
    return platform == TargetPlatform.android ||
        platform == TargetPlatform.iOS ||
        platform == TargetPlatform.fuchsia;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);

    if (relatives.isEmpty) {
      return _buildEmptyState(context);
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      buildDefaultDragHandles: false,
      onReorderItem: (oldIndex, newIndex) {
        AppState().reorderRelatives(oldIndex, newIndex);
      },
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final elevation = Tween<double>(begin: 2, end: 24).evaluate(animation);
            final scale = Tween<double>(begin: 1, end: 1.03).evaluate(animation);
            return Transform.scale(
              scale: scale,
              child: Material(
                elevation: elevation,
                borderRadius: BorderRadius.circular(16),
                color: Colors.transparent,
                shadowColor: Colors.black.withValues(alpha: 0.35),
                clipBehavior: Clip.none,
                child: child,
              ),
            );
          },
          child: child,
        );
      },
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const HomeUserHeader(),
          const SizedBox(height: 18),
          StatusBanner(status: overallStatus),
          const SizedBox(height: 24),
          _buildSectionHeader(context),
        ],
      ),
      itemCount: relatives.length,
      itemBuilder: (context, index) {
        final r = relatives[index];
        final card = ElderlyListCard(
          key: ValueKey(r.id),
          elderly: r,
          isSelected: selectedElderlyId == r.id,
          onTap: () => onTap(r.id),
        );

        // Toàn bộ card là vùng kéo thả, không cần drag handle.
        // Mobile dùng nhấn giữ; desktop dùng kéo ngay để phù hợp chuột.
        if (isMobile) {
          return ReorderableDelayedDragStartListener(
            key: ValueKey('drag_listener_${r.id}'),
            index: index,
            child: card,
          );
        }
        return ReorderableDragStartListener(
          key: ValueKey('drag_listener_${r.id}'),
          index: index,
          child: card,
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        Localization.translate('relativeList').toUpperCase(),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF64748B),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const HomeUserHeader(),
          const SizedBox(height: 18),
          StatusBanner(status: overallStatus),
          const SizedBox(height: 48),
          Center(
            child: Icon(
              Icons.people_outline,
              size: 80,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            Localization.translate('noRelatives'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            Localization.translate('noRelativesHint'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => AddRelativeDialog.show(context),
            icon: const Icon(Icons.person_add_alt_1),
            label: Text(Localization.translate('addFirstRelative')),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
