import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_state.dart';
import 'edit_single_field_dialog.dart';

/// Helper nội bộ: mở dialog edit single-field và hiển thị SnackBar kết quả.
/// Tự kiểm tra `context.mounted` sau `await` để tránh cảnh báo use_build_context_synchronously.
Future<void> _runEdit(
  BuildContext context,
  AppState state,
  Future<bool> Function() editAction,
  String successMessage,
) async {
  final ok = await editAction();
  if (!context.mounted) return;
  showProfileUpdateResult(context, ok, successMessage: successMessage);
}

/// Mở dialog sửa tên. Trả về `true` nếu cập nhật thành công.
Future<bool> editUserName(BuildContext context, AppState state) async {
  final newName = await showDialog<String>(
    context: context,
    builder: (_) => EditSingleFieldDialog(
      title: 'Sửa họ và tên',
      label: 'Họ và tên',
      initialValue: state.userProfile.name,
      maxLength: 60,
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Vui lòng nhập họ và tên';
        if (v.trim().length < 2) return 'Họ và tên quá ngắn';
        return null;
      },
    ),
  );
  if (newName == null) return false;
  return state.updateUserProfile(state.userProfile.copyWith(name: newName));
}

Future<bool> editUserPhone(BuildContext context, AppState state) async {
  final newPhone = await showDialog<String>(
    context: context,
    builder: (_) => EditSingleFieldDialog(
      title: 'Sửa số điện thoại',
      label: 'Số điện thoại',
      initialValue: state.userProfile.phone,
      keyboardType: TextInputType.phone,
      hint: 'VD: 0901234567',
      maxLength: 10,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Vui lòng nhập số điện thoại';
        if (!RegExp(r'^[0-9]{10}$').hasMatch(v.trim())) {
          return 'SĐT phải đúng 10 chữ số';
        }
        return null;
      },
    ),
  );
  if (newPhone == null) return false;
  return state.updateUserProfile(state.userProfile.copyWith(phone: newPhone));
}

/// Hiển thị SnackBar kết quả (gọi chung cho cả 4 hành động edit).
void showProfileUpdateResult(
  BuildContext context,
  bool ok, {
  String successMessage = 'Đã cập nhật',
}) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(ok ? successMessage : 'Cập nhật thất bại'),
      backgroundColor: ok ? const Color(0xFF10B981) : Colors.red,
      duration: const Duration(seconds: 2),
    ),
  );
}

/// Combo: sửa tên + SnackBar (an toàn context).
Future<void> runEditName(BuildContext context, AppState state) {
  return _runEdit(context, state,
      () => editUserName(context, state), 'Đã cập nhật họ tên');
}

Future<void> runEditPhone(BuildContext context, AppState state) {
  return _runEdit(context, state,
      () => editUserPhone(context, state), 'Đã cập nhật số điện thoại');
}
