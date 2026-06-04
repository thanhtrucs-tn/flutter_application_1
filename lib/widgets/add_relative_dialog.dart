import 'package:flutter/material.dart';
import '../models/elderly_model.dart';
import '../utils/app_state.dart';
import '../utils/localization.dart';

/// Dialog thêm người cao tuổi mới vào hệ thống giám sát.
///
/// Tái sử dụng được cho HomeScreen (FAB) và SettingsScreen (Quản lý người thân).
class AddRelativeDialog extends StatefulWidget {
  const AddRelativeDialog({super.key});

  /// Mở dialog dưới dạng hàm tiện ích — che giấu boilerplate của showDialog/builder.
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const AddRelativeDialog(),
    );
  }

  @override
  State<AddRelativeDialog> createState() => _AddRelativeDialogState();
}

class _AddRelativeDialogState extends State<AddRelativeDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _deviceController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();     //  Thêm controller cho số điện thoại khẩn cấp

  @override
  void dispose() {
    _nameController.dispose();
    _deviceController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final state = AppState();
    // Chuẩn hóa dữ liệu: gộp nhiều khoảng trắng thành 1, trim đầu cuối
    final name = _nameController.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    final device = _deviceController.text.trim();
    // Chuẩn hóa số điện thoại: bỏ khoảng trắng, chỉ giữ chữ số và dấu +
    final contactRaw = _contactController.text.trim();
    final contact = contactRaw.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Tính ID mới an toàn — lấy max(id) + 1 để không bị trùng khi đã xóa người thân trước đó.
    final newId = state.relatives.isEmpty
        ? 1
        : state.relatives.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;

    final newElderly = ElderlyModel(
      id: newId,
      name: name,
      avatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
      battery: 100,
      lastUpdated: DateTime.now(),
      status: 'safe',
      latitude: 10.762622,
      longitude: 106.660172,
      heartRate: 72,
      spo2: 98,
      isOffline: false,
      wearableDevice: device,
      isFallen: false,
      safeZoneRadius: 300.0,
      safeZoneLat: 10.762622,
      safeZoneLng: 106.660172,
      emergencyContacts: contact.isEmpty ? <String>['0900000000'] : <String>[contact],
    );

    // Lưu messenger TRƯỚC khi pop để tránh dùng context đã unmount
    final messenger = ScaffoldMessenger.of(context);
    state.addElderly(newElderly);
    Navigator.pop(context);

    messenger.showSnackBar(
      SnackBar(
        content: Text('${Localization.translate('success')}: $name'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(Localization.translate('add')),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                maxLength: 50,
                decoration: const InputDecoration(
                  labelText: 'Tên người cao tuổi',
                  prefixIcon: Icon(Icons.person_outline),
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
                controller: _deviceController,
                maxLength: 30,
                decoration: const InputDecoration(
                  labelText: 'Mã/Tên thiết bị đeo ESP32',
                  prefixIcon: Icon(Icons.watch_outlined),
                ),
                validator: (v) {
                  final t = v?.trim() ?? '';
                  if (t.isEmpty) return 'Vui lòng nhập mã thiết bị';
                  if (t.length < 3) return 'Mã thiết bị phải có ít nhất 3 ký tự';
                  if (!RegExp(r'^[A-Za-z0-9_\-]+$').hasMatch(t)) {
                    return 'Mã thiết bị chỉ chứa chữ, số, gạch ngang hoặc gạch dưới';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contactController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại khẩn cấp (tùy chọn)',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null; // optional
                  // Chuẩn hóa: bỏ khoảng trắng, dấu gạch, dấu ngoặc
                  final digits = v.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
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
