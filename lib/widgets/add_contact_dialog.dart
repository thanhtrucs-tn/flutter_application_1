import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/emergency_contact_model.dart';
import '../utils/app_state.dart';
import '../utils/localization.dart';

/// Dialog "Thêm liên hệ mới" cho 1 người cao tuổi.
///
/// Form gồm 3 trường:
///  - Tên người liên hệ (bắt buộc)
///  - Số điện thoại (bắt buộc, 10 chữ số)
///  - Quan hệ (tùy chọn, VD: Con trai, Con gái, Bạn bè, Hàng xóm...)
///
/// Khi lưu sẽ nối chuỗi "Tên (Quan hệ): SĐT" vào `ElderlyModel.emergencyContacts`
/// để giữ tương thích ngược với cách lưu trữ hiện tại.
class AddContactDialog extends StatefulWidget {
  final int elderlyId;

  const AddContactDialog({super.key, required this.elderlyId});

  /// Mở dialog dưới dạng hàm tiện ích.
  static Future<void> show(BuildContext context, int elderlyId) {
    return showDialog<void>(
      context: context,
      builder: (_) => AddContactDialog(elderlyId: elderlyId),
    );
  }

  @override
  State<AddContactDialog> createState() => _AddContactDialogState();
}

class _AddContactDialogState extends State<AddContactDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _relationshipController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final state = AppState();
    final relative = state.relatives.firstWhere((e) => e.id == widget.elderlyId);
    final newContact = EmergencyContactModel(
      name: _nameController.text.trim().replaceAll(RegExp(r'\s+'), ' '),
      phone: _phoneController.text.trim(),
      relationship: _relationshipController.text.trim(),
    );

    final updatedList = [...relative.emergencyContacts, newContact.toStorageString()];
    state.updateElderly(relative.copyWith(emergencyContacts: updatedList));

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã thêm liên hệ: ${newContact.name}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(Localization.translate('addContact')),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                maxLength: 30,
                decoration: const InputDecoration(
                  labelText: 'Tên người liên hệ',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (v) {
                  final t = v?.trim() ?? '';
                  if (t.isEmpty) return 'Vui lòng nhập tên';
                  if (t.length < 2) return 'Tên phải có ít nhất 2 ký tự';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (v) {
                  final t = v?.trim() ?? '';
                  if (t.isEmpty) return 'Vui lòng nhập SĐT';
                  if (!RegExp(r'^[0-9]{10}$').hasMatch(t)) {
                    return 'SĐT phải đúng 10 chữ số';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _relationshipController,
                textCapitalization: TextCapitalization.words,
                maxLength: 20,
                decoration: const InputDecoration(
                  labelText: 'Quan hệ (tùy chọn)',
                  hintText: 'VD: Con trai, Con gái, Bạn bè...',
                  prefixIcon: Icon(Icons.people_outline),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null; // optional
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(Localization.translate('cancel')),
        ),
        ElevatedButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.check, size: 18),
          label: Text(Localization.translate('save')),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
        ),
      ],
    );
  }
}
