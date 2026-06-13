import 'package:flutter/material.dart';
import '../models/elderly_model.dart';
import '../utils/app_state.dart';
import '../utils/localization.dart';

/// Hộp thoại xác nhận xóa người thân khỏi danh sách theo dõi.
///
/// Widget tái sử dụng được cho bất kỳ màn hình nào cần xóa người thân.
class DeleteRelativeConfirmationDialog extends StatefulWidget {
  final ElderlyModel elderly;

  const DeleteRelativeConfirmationDialog({
    super.key,
    required this.elderly,
  });

  /// Hiển thị dialog và trả về `true` nếu người dùng xác nhận xóa.
  static Future<bool> show(BuildContext context, ElderlyModel elderly) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DeleteRelativeConfirmationDialog(elderly: elderly),
    ).then((value) => value ?? false);
  }

  @override
  State<DeleteRelativeConfirmationDialog> createState() => _DeleteRelativeConfirmationDialogState();
}

class _DeleteRelativeConfirmationDialogState extends State<DeleteRelativeConfirmationDialog> {
  bool _isDeleting = false;

  Future<void> _confirmDelete(BuildContext context) async {
    if (_isDeleting) return;
    setState(() => _isDeleting = true);

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final deleted = await AppState().deleteElderly(widget.elderly.id);

    if (!mounted) return;
    navigator.pop(deleted);

    if (deleted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${Localization.translate('deleteRelativeSuccess')}: ${widget.elderly.name}',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${Localization.translate('deleteRelativeFailed')}: ${widget.elderly.name}',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDeleting,
      child: AlertDialog(
        title: Text(Localization.translate('deleteRelative')),
        content: Text(Localization.translate('deleteRelativeConfirm')),
        actions: [
          TextButton(
            onPressed: _isDeleting ? null : () => Navigator.of(context).pop(false),
            child: Text(Localization.translate('cancel')),
          ),
          ElevatedButton.icon(
            onPressed: _isDeleting ? null : () => _confirmDelete(context),
            icon: _isDeleting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.delete_outline, size: 18),
            label: Text(Localization.translate('delete')),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
