import 'package:flutter/material.dart';
import '../utils/app_state.dart';
import '../utils/localization.dart';
import '../widgets/sos_app_header.dart';
import '../widgets/avatar_picker.dart';
import '../widgets/user_profile_dialogs.dart';
import 'settings_screen.dart';
import 'login_screen.dart';

/// Màn hình Thông tin cá nhân của người giám sát.
/// Mỗi mục (avatar / tên / email / SĐT) sửa riêng qua dialog single-field.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _logout(BuildContext context) {
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
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.edit, size: 18, color: Color(0xFFE53935)),
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
                color: const Color(0xFFE53935).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                profile.role,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE53935),
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
          // Email — bấm để sửa email
          _EditableInfoTile(
            icon: Icons.email,
            color: Colors.purple,
            label: 'Email',
            value: profile.email,
            onEdit: () => runEditEmail(context, state),
          ),
          const Divider(height: 1),
          // SĐT — bấm để sửa SĐT (hiển thị kèm tên tài khoản để biết SĐT này của ai)
          _EditableInfoTile(
            icon: Icons.phone,
            color: Colors.green,
            label: 'Số điện thoại',
            value: '${profile.name} • ${profile.phone}',
            onEdit: () => runEditPhone(context, state),
          ),
          const Divider(height: 1),
          // Dòng cố định — không cho sửa
          _ReadOnlyInfoTile(
            icon: Icons.monitor_heart,
            color: Colors.red,
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
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.settings, color: Colors.blue, size: 22),
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
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.logout, color: Colors.red, size: 22),
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
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E293B),
        ),
      ),
      trailing: const Icon(Icons.edit, size: 18, color: Color(0xFFE53935)),
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
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E293B),
        ),
      ),
    );
  }
}
