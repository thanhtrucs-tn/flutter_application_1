import 'package:flutter/material.dart';
import '../models/elderly_model.dart';
import '../utils/app_state.dart';
import '../utils/localization.dart';
import 'add_relative_dialog.dart';
import 'avatar_picker.dart';
import 'delete_relative_confirmation_dialog.dart';
import 'elderly_avatar.dart';
import 'settings_section_card.dart';

/// Section "Quản lý người thân" dùng chung trong SettingsScreen.
///
/// Hiển thị danh sách người thân đang giám sát, cho phép thêm mới và
/// xóa (nếu có quyền) qua icon thùng rác bên phải mỗi người thân.
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
      leading: Stack(
        alignment: Alignment.bottomRight,
        children: [
          ElderlyAvatar(
            elderly: r,
            radius: 20,
            onTap: () => _showAvatarPicker(context, r),
          ),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Color(0xFFE53935),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.camera_alt, color: Colors.white, size: 10),
          ),
        ],
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
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Color(0xFFE53935)),
              tooltip: Localization.translate('deleteRelative'),
              onPressed: () => DeleteRelativeConfirmationDialog.show(context, r),
            ),
        ],
      ),
    );
  }

  /// Mở dialog cho phép chọn ảnh đại diện mới cho người thân.
  Future<void> _showAvatarPicker(BuildContext context, ElderlyModel r) async {
    final newPath = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${Localization.translate('changeAvatar')} ${r.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AvatarPicker(
              avatarUrl: r.avatar,
              avatarLocalPath: r.avatarLocalPath,
              radius: 56,
              onPicked: (path) => Navigator.of(context).pop(path),
            ),
            const SizedBox(height: 12),
            Text(
              Localization.translate('tapAvatarToPickFromGallery'),
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(Localization.translate('cancel')),
          ),
        ],
      ),
    );

    if (newPath != null && newPath.isNotEmpty) {
      await AppState().patchElderlyLocalAvatar(r.id, newPath);
    }
  }
}
