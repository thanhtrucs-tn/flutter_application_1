import 'package:flutter/material.dart';

/// AppBar dùng chung với nền sáng/tối cho SOS Care.
/// Tự động hiển thị nút quay lại khi có thể pop (Navigator.canPop == true).
class SosAppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;

  /// Bắt buộc hiển thị nút quay lại (override mọi logic tự động).
  final bool showBackButton;

  /// Ẩn nút quay lại ngay cả khi có thể pop.
  final bool hideBackButton;

  /// Custom widget thay cho nút quay lại mặc định.
  final Widget? leading;

  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  const SosAppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBackButton = false,
    this.hideBackButton = false,
    this.leading,
    this.actions,
    this.bottom,
  });

  @override
  Size get preferredSize {
    final bottomHeight = bottom?.preferredSize.height ?? 0.0;
    return Size.fromHeight(kToolbarHeight + bottomHeight + (subtitle != null ? 8 : 0));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foregroundColor = isDark ? Colors.white : const Color(0xFF1E293B);

    // Tự động hiển thị nút quay lại khi có thể pop.
    final canPop = Navigator.canPop(context);
    final shouldShowBack = !hideBackButton && (showBackButton || canPop);

    Widget? leadingWidget;
    if (leading != null) {
      leadingWidget = leading;
    } else if (shouldShowBack) {
      leadingWidget = IconButton(
        icon: Icon(Icons.arrow_back_ios_new, color: foregroundColor),
        onPressed: () => Navigator.of(context).pop(),
        tooltip: 'Quay lại',
      );
    }

    return AppBar(
      automaticallyImplyLeading: false,
      leading: leadingWidget,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: foregroundColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.normal,
              ),
            ),
        ],
      ),
      actions: actions,
      bottom: bottom,
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        side: BorderSide(
          color: Color(0xFFE2E8F0),
          width: 1.0,
        ),
      ),
    );
  }
}
