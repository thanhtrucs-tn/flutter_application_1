import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';

/// Dialog cho phép chỉnh mã định danh của thiết bị giả lập:
/// - [deviceId]: serial thiết bị (vd `SOS-DEVICE-001`).
/// - [elderlyId]: MÃ GHÉP ĐÔI — giá trị user nhập vào ô "Mã/Tên thiết bị" khi
///   thêm người thân trong app, để `relative.deviceElderlyId` khớp với stream
///   telemetry của thiết bị này trên backend.
///
/// Validator dùng cùng regex với app (`add_relative_dialog.dart`) để đảm bảo
/// mã đặt ở đây luôn được app chấp nhận. Giá trị lưu in-memory, reset về default
/// khi restart (theo chốt scope với user).
class DeviceIdentityEditor extends ConsumerStatefulWidget {
  const DeviceIdentityEditor({super.key});

  /// Mở dialog dưới dạng hàm tiện ích — che giấu boilerplate showDialog.
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const DeviceIdentityEditor(),
    );
  }

  @override
  ConsumerState<DeviceIdentityEditor> createState() =>
      _DeviceIdentityEditorState();
}

class _DeviceIdentityEditorState extends ConsumerState<DeviceIdentityEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _deviceIdController;
  late final TextEditingController _elderlyIdController;

  @override
  void initState() {
    super.initState();
    // Prefill với mã hiện tại của thiết bị (lấy từ state Riverpod).
    final status = ref.read(deviceStatusNotifierProvider);
    _deviceIdController = TextEditingController(text: status.deviceId);
    _elderlyIdController = TextEditingController(text: status.elderlyId);
  }

  @override
  void dispose() {
    _deviceIdController.dispose();
    _elderlyIdController.dispose();
    super.dispose();
  }

  // Regex khớp validator ô "Mã thiết bị" trong app (add_relative_dialog.dart).
  String? _validate(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return 'Không được trống';
    if (t.length < 3) return 'Ít nhất 3 ký tự';
    if (t.length > 30) return 'Tối đa 30 ký tự';
    if (!RegExp(r'^[A-Za-z0-9_\-]+$').hasMatch(t)) {
      return 'Chỉ chứa chữ, số, gạch ngang hoặc gạch dưới';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    // Notifier tự trim + validate lại (đề phòng); chỉ cập nhật nếu hợp lệ.
    final notifier = ref.read(deviceStatusNotifierProvider.notifier);
    notifier.setDeviceId(_deviceIdController.text);
    notifier.setElderlyId(_elderlyIdController.text);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chỉnh mã thiết bị'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _deviceIdController,
                decoration: const InputDecoration(
                  labelText: 'Mã thiết bị (deviceId)',
                  prefixIcon: Icon(Icons.watch_outlined),
                ),
                validator: _validate,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _elderlyIdController,
                decoration: const InputDecoration(
                  labelText: 'Mã ghép đôi (elderlyId)',
                  hintText: 'Nhập mã này vào app khi thêm người thân',
                  prefixIcon: Icon(Icons.link),
                ),
                validator: _validate,
              ),
              const SizedBox(height: 8),
              Text(
                'Mã ghép đôi phải khớp với ô "Mã/Tên thiết bị" trong app, '
                'người thân mới nhận được dữ liệu realtime từ thiết bị này.',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.check, size: 18),
          label: const Text('Lưu'),
        ),
      ],
    );
  }
}