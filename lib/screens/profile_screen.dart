import 'package:flutter/material.dart';
import '../services/device_event_service.dart';
import '../utils/app_state.dart';
import '../utils/localization.dart';
import '../widgets/sos_app_header.dart';
import '../widgets/avatar_picker.dart';
import '../widgets/user_profile_dialogs.dart';
import 'settings_screen.dart';
import 'login_screen.dart';

/// Màu đơn sắc cho mọi biểu tượng trên màn Thông tin cá nhân (sáng hơn ở chế
/// độ tối để vẫn nhìn rõ trên nền thẻ tối).
Color _iconColorOf(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

/// Màu chữ chính: gần đen ở chế độ sáng, trắng ở chế độ tối.
Color _textColorOf(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : const Color(0xFF1E293B);

/// Màn hình Thông tin cá nhân của người giám sát.
/// Mỗi mục (avatar / tên / email / SĐT) sửa riêng qua dialog single-field.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await AppState().logout();
    DeviceEventService().reauthenticate(null);
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _onAvatarPicked(BuildContext context, AppState state, String path) async {
    final ok = await state.updateUserAvatarLocalPath(path);
    if (!context.mounted) return;
    showProfileUpdateResult(context, ok, successMessage: 'Đã cập nhật ảnh đại diện');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = AppState();

    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final profile = state.userProfile;
        return Scaffold(
          appBar: SosAppHeader(
            title: Localization.translate('profile'),
            showBackButton: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header: avatar (bấm để sửa ảnh) + tên + email + role
                _buildHeaderCard(context, state, profile, isDark),
                const SizedBox(height: 16),

                // Thông tin chi tiết — 3 dòng có thể sửa
                _buildInfoSection(context, state, profile, isDark),
                const SizedBox(height: 16),

                // Tài khoản & đăng xuất
                _buildAccountSection(context, isDark),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderCard(
    BuildContext context,
    AppState state,
    profile, // UserProfile - inferred
    bool isDark,
  ) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
      ),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar có icon camera nhỏ → bấm để chọn ảnh từ thư viện
            AvatarPicker(
              avatarUrl: profile.avatarUrl,
              avatarLocalPath: profile.avatarLocalPath,
              onPicked: (path) => _onAvatarPicked(context, state, path),
            ),
            const SizedBox(height: 12),
            // Tên — bấm để sửa tên
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => runEditName(context, state),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        profile.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _textColorOf(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.edit, size: 18, color: _iconColorOf(context)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              profile.email,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _iconColorOf(context).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Người giám sát',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _iconColorOf(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(
    BuildContext context,
    AppState state,
    profile,
    bool isDark,
  ) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
      ),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Column(
        children: [
          // Email — khóa đăng nhập, không sửa được
          _ReadOnlyInfoTile(
            icon: Icons.email,
            color: _iconColorOf(context),
            label: 'Email',
            value: profile.email,
          ),
          const Divider(height: 1),
          // SĐT — bấm để sửa SĐT (hiển thị kèm tên tài khoản để biết SĐT này của ai)
          _EditableInfoTile(
            icon: Icons.phone,
            color: _iconColorOf(context),
            label: 'Số điện thoại',
            value: '${profile.name} • ${profile.phone}',
            onEdit: () => runEditPhone(context, state),
          ),
          const Divider(height: 1),
          // Dòng cố định — không cho sửa
          _ReadOnlyInfoTile(
            icon: Icons.monitor_heart,
            color: _iconColorOf(context),
            label: 'Đang giám sát',
            value: '${state.relatives.length} người thân',
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context, bool isDark) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
      ),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Column(
        children: [
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _iconColorOf(context).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.settings, color: _iconColorOf(context), size: 22),
            ),
            title: const Text(
              'Cài đặt',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _iconColorOf(context).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.logout, color: _iconColorOf(context), size: 22),
            ),
            title: Text(
              Localization.translate('logout'),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}

/// Tile hiển thị 1 dòng thông tin có thể sửa: bấm vào → mở dialog sửa trường đó.
class _EditableInfoTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final Future<void> Function() onEdit;

  const _EditableInfoTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onEdit,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade400
              : Colors.grey.shade600,
        ),
      ),
      subtitle: Text(
        value,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: _textColorOf(context),
        ),
      ),
      trailing: Icon(Icons.edit, size: 18, color: _iconColorOf(context)),
    );
  }
}

/// Tile hiển thị 1 dòng thông tin cố định (không sửa được).
class _ReadOnlyInfoTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _ReadOnlyInfoTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade400
              : Colors.grey.shade600,
        ),
      ),
      subtitle: Text(
        value,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: _textColorOf(context),
        ),
      ),
    );
  }
}
