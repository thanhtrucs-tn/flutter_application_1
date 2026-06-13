import 'package:flutter/material.dart';
import '../models/elderly_model.dart';
import '../utils/localization.dart';
import 'add_relative_dialog.dart';
import 'delete_relative_confirmation_dialog.dart';
import 'settings_section_card.dart';

/// Section "Quản lý người thân" dùng chung trong SettingsScreen.
///
/// Hiển thị danh sách người thân đang giám sát, cho phép thêm mới và
/// xóa (chỉ admin) qua popup menu `⋮`.
class ManageRelativesSection extends StatelessWidget {
  final List<ElderlyModel> relatives;
  final bool canDelete;

  const ManageRelativesSection({
    super.key,
    required this.relatives,
    required this.canDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsSectionCard(
      title: Localization.translate('manageRelatives'),
      children: [
        ...relatives.map((r) => _buildRelativeTile(context, r)),
        if (relatives.isNotEmpty) const Divider(height: 1),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE53935).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_add_alt_1, color: Color(0xFFE53935), size: 22),
          ),
          title: Text(
            Localization.translate('add'),
            style: const TextStyle(
              color: Color(0xFFE53935),
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          trailing: const Icon(Icons.add, color: Color(0xFFE53935)),
          onTap: () => AddRelativeDialog.show(context),
        ),
      ],
    );
  }

  Widget _buildRelativeTile(BuildContext context, ElderlyModel r) {
    final statusColor = r.isOffline
        ? Colors.grey
        : (r.status == 'critical'
            ? const Color(0xFFEF4444)
            : (r.status == 'warning' ? const Color(0xFFF59E0B) : const Color(0xFF10B981)));

    return ListTile(
      contentPadding: const EdgeInsets.only(left: 16, right: 4, top: 4, bottom: 4),
      leading: CircleAvatar(
        backgroundImage: NetworkImage(r.avatar),
        radius: 20,
      ),
      title: Text(
        r.name,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      subtitle: Text(
        '${r.wearableDevice} • Pin ${r.battery}%',
        style: const TextStyle(fontSize: 13),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          if (canDelete)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              tooltip: Localization.translate('manageRelatives'),
              onSelected: (_) => DeleteRelativeConfirmationDialog.show(context, r),
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
            ),
        ],
      ),
    );
  }
}
