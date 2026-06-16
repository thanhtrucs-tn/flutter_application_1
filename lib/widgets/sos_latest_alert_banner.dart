import 'package:flutter/material.dart';
import '../models/alert_model.dart';
import 'alert_list_item.dart';

/// Banner thông báo SOS khẩn cấp mới nhất trên trang chủ.
///
/// - Chỉ hiển thị tối đa 1 thông báo chưa xử lý mới nhất.
/// - Khi có thông báo mới hơn, banner cũ trượt xuống và biến mất,
///   banner mới trượt xuống từ trên vào vị trí.
/// - Nhấn vào banner mở màn hình chi tiết cảnh báo.
class SosLatestAlertBanner extends StatelessWidget {
  final AlertModel? alert;
  final ValueChanged<AlertModel> onTap;

  const SosLatestAlertBanner({
    super.key,
    required this.alert,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final child = alert == null
        ? const SizedBox.shrink(key: ValueKey('sos_banner_empty'))
        : AlertListItem(
            key: ValueKey('sos_banner_${alert!.id}'),
            alert: alert!,
            isLatest: true,
            onTap: () => onTap(alert!),
          );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (Widget childWidget, Animation<double> animation) {
        final isLeaving = animation.status == AnimationStatus.reverse;
        final tween = isLeaving
            ? Tween<Offset>(begin: Offset.zero, end: const Offset(0, 1))
            : Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero);
        final offsetAnimation = tween.animate(
          CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        );
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: offsetAnimation,
            child: childWidget,
          ),
        );
      },
      child: child,
    );
  }
}
