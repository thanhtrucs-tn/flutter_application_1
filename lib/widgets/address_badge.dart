import 'package:flutter/material.dart';

import '../models/address_model.dart';

/// Trạng thái của badge địa chỉ
enum AddressBadgeStatus { loading, success, error }

/// Widget hiển thị địa chỉ dạng badge đặt bên dưới map.
///
/// - loading: shimmer + icon loading
/// - success: icon location_on + text địa chỉ ngắn gọn + icon expand
/// - error: icon error_outline + "Không thể tải địa chỉ"
class AddressBadge extends StatelessWidget {
  final AddressBadgeStatus status;
  final String? addressText;
  final VoidCallback? onTap;
  final String relativeName;

  const AddressBadge({
    super.key,
    required this.status,
    this.addressText,
    this.onTap,
    this.relativeName = '',
  });

  factory AddressBadge.loading() => const AddressBadge(
        status: AddressBadgeStatus.loading,
      );

  factory AddressBadge.success(String address, {String? relativeName, VoidCallback? onTap}) =>
      AddressBadge(
        status: AddressBadgeStatus.success,
        addressText: address,
        relativeName: relativeName ?? '',
        onTap: onTap,
      );

  factory AddressBadge.error({VoidCallback? onTap}) => AddressBadge(
        status: AddressBadgeStatus.error,
        onTap: onTap,
      );

  /// Build dựa trên Address (success/error tự suy ra)
  factory AddressBadge.fromAddress({
    required Address? address,
    required bool isLoading,
    String relativeName = '',
    VoidCallback? onTap,
  }) {
    if (isLoading) return AddressBadge.loading();
    if (address == null || address.displayName.isEmpty) {
      return AddressBadge.error(onTap: onTap);
    }
    return AddressBadge.success(
      address.shortAddress,
      relativeName: relativeName,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _backgroundColor(isDark),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _borderColor(isDark),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildLeadingIcon(isDark),
              const SizedBox(width: 10),
              Expanded(
                child: _buildContent(isDark),
              ),
              if (onTap != null && status == AddressBadgeStatus.success)
                Icon(
                  Icons.open_in_full,
                  size: 16,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingIcon(bool isDark) {
    switch (status) {
      case AddressBadgeStatus.loading:
        return SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            valueColor: AlwaysStoppedAnimation<Color>(
              isDark ? Colors.tealAccent : Colors.teal,
            ),
          ),
        );
      case AddressBadgeStatus.success:
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.teal.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.location_on,
            color: Colors.teal,
            size: 18,
          ),
        );
      case AddressBadgeStatus.error:
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.error_outline,
            color: Colors.orange,
            size: 18,
          ),
        );
    }
  }

  Widget _buildContent(bool isDark) {
    switch (status) {
      case AddressBadgeStatus.loading:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Vị trí: $relativeName',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            _shimmerBar(isDark, width: 200),
            const SizedBox(height: 4),
            _shimmerBar(isDark, width: 140),
          ],
        );
      case AddressBadgeStatus.success:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (relativeName.isNotEmpty)
              Text(
                'Vị trí: $relativeName',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.tealAccent : Colors.teal,
                ),
              ),
            if (relativeName.isNotEmpty) const SizedBox(height: 2),
            Text(
              addressText ?? '',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Nhấn để mở rộng bản đồ',
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.white54 : Colors.black45,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        );
      case AddressBadgeStatus.error:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Không thể tải địa chỉ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              onTap != null ? 'Nhấn để thử lại' : 'Kiểm tra kết nối mạng',
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ],
        );
    }
  }

  Widget _shimmerBar(bool isDark, {required double width}) {
    return Container(
      width: width,
      height: 8,
      decoration: BoxDecoration(
        color: isDark ? Colors.white12 : Colors.black12,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Color _backgroundColor(bool isDark) =>
      isDark ? const Color(0xFF1E293B) : Colors.white;

  Color _borderColor(bool isDark) =>
      isDark ? Colors.white12 : Colors.grey.shade300;
}
