import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final TextEditingController _birthDateController = TextEditingController();
  DateTime? _birthDate;
  final TextEditingController _contactNameController = TextEditingController();  // Tên người liên hệ khẩn cấp
  final TextEditingController _contactController = TextEditingController();      //  Số điện thoại khẩn cấp

  @override
  void dispose() {
    _nameController.dispose();
    _deviceController.dispose();
    _birthDateController.dispose();
    _contactNameController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  /// Mở DatePicker cho phép chọn ngày sinh (tính ra tuổi).
  /// - firstDate = 1900, lastDate = hôm nay (không cho chọn tương lai)
  /// - initialDate mặc định ~70 tuổi
  /// - Đặt _birthDate = ngày được chọn, đồng thời hiển thị text vào controller
  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initial = _birthDate ?? DateTime(now.year - 70, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Chọn ngày sinh',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
      fieldLabelText: 'Ngày sinh',
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
        // Hiển thị dd/MM/yyyy cho dễ đọc
        _birthDateController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  /// Tính tuổi chính xác từ ngày sinh (trừ 1 nếu chưa qua sinh nhật năm nay).
  static int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    var age = now.year - birthDate.year;
    final hasHadBirthdayThisYear = now.month > birthDate.month ||
        (now.month == birthDate.month && now.day >= birthDate.day);
    if (!hasHadBirthdayThisYear) age--;
    return age;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_birthDate == null) {
      // Validator đã xử lý, nhưng đề phòng state bị thay đổi
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ngày sinh'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final state = AppState();
    // Chuẩn hóa dữ liệu: gộp nhiều khoảng trắng thành 1, trim đầu cuối
    final name = _nameController.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    final device = _deviceController.text.trim();
    // SĐT đã được inputFormatters chuẩn hóa (chỉ còn chữ số)
    final contact = _contactController.text.trim();
    final contactName = _contactNameController.text.trim().replaceAll(RegExp(r'\s+'), ' ');

    // Liên hệ khẩn cấp là tùy chọn: chỉ gửi khi có ĐỦ cả tên + SĐT.
    // Backend createContactSchema bắt name + phone required (không chấp nhận rỗng),
    // nên không được gửi placeholder '0900000000' (parse ra phone rỗng → 400).
    // Định dạng "Tên: SĐT" để EmergencyContactModel.fromStorageString tách đúng
    // name/phone khi _parseContacts serialize lên server.
    final contactEntry = (contactName.isNotEmpty && contact.isNotEmpty)
        ? <String>['$contactName: $contact']
        : <String>[];

    // Tính tuổi từ ngày sinh đã chọn
    final age = _calculateAge(_birthDate!);

    // Thiết bị đeo ESP32 sẽ gửi GPS đầu tiên qua WebSocket/realtime.
    // Đến lúc đó, app sẽ set isOffline=false và cập nhật lat/lng/safeZoneLat/Lng.
    // Tạm thời: lat=0, lng=0, safeZoneLat=0, safeZoneLng=0, isOffline=true.
    // Bản đồ sẽ hiển thị overlay "Chờ GPS" cho tới khi có tín hiệu.
    final newElderly = ElderlyModel(
      id: 0, // placeholder — backend cấp id thật
      name: name,
      avatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
      battery: 0, // Chưa có thiết bị, pin = 0
      lastUpdated: DateTime.now(),
      status: 'safe',
      latitude: 0,
      longitude: 0,
      heartRate: 0,
      spo2: 0,
      isOffline: true, // Chờ thiết bị ESP32 gửi GPS đầu tiên
      wearableDevice: device,
      isFallen: false,
      safeZoneRadius: 300.0,
      safeZoneLat: 0, // Cập nhật khi có GPS
      safeZoneLng: 0,
      emergencyContacts: contactEntry,
      age: age,
    );

    // Lưu messenger TRƯỚC khi pop để tránh dùng context đã unmount
    final messenger = ScaffoldMessenger.of(context);
    try {
      await state.addElderly(newElderly);
      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${Localization.translate('success')}: $name ($age tuổi) — chờ GPS từ thiết bị',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Thêm người thân thất bại: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
              // Ngày sinh (mở DatePicker). Bắt buộc — dùng để tính tuổi.
              TextFormField(
                controller: _birthDateController,
                readOnly: true,
                onTap: _pickBirthDate,
                decoration: const InputDecoration(
                  labelText: 'Ngày sinh',
                  hintText: 'Bấm để chọn ngày',
                  prefixIcon: Icon(Icons.cake_outlined),
                  suffixIcon: Icon(Icons.calendar_today, size: 18),
                ),
                validator: (v) {
                  if (_birthDate == null) {
                    return 'Vui lòng chọn ngày sinh';
                  }
                  final age = _calculateAge(_birthDate!);
                  if (age < 40) {
                    return 'Tuổi quá thấp ($age). Người cao tuổi tối thiểu 40 tuổi';
                  }
                  if (age > 130) {
                    return 'Ngày sinh không hợp lệ (tuổi $age > 130)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: TextFormField(
                      controller: _contactNameController,
                      textCapitalization: TextCapitalization.words,
                      maxLength: 30,
                      decoration: const InputDecoration(
                        labelText: 'Tên liên hệ',
                        hintText: 'VD: Nguyễn Văn An',
                        prefixIcon: Icon(Icons.badge_outlined),
                        counterText: '',
                      ),
                      validator: (v) {
                        final t = v?.trim() ?? '';
                        final phone = _contactController.text.trim();
                        // Liên hệ khẩn cấp: cả tên + SĐT phải cùng có hoặc cùng trống.
                        if (phone.isNotEmpty && t.isEmpty) {
                          return 'Nhập tên liên hệ khi đã nhập SĐT';
                        }
                        if (t.isNotEmpty && t.length < 2) return 'Tên quá ngắn';
                        if (t.isNotEmpty && phone.isEmpty) {
                          return 'Nhập SĐT cho liên hệ này';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 5,
                    child: TextFormField(
                      controller: _contactController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'SĐT',
                        hintText: '10 chữ số',
                        prefixIcon: Icon(Icons.phone_outlined),
                        counterText: '',
                      ),
                      validator: (v) {
                        final t = v?.trim() ?? '';
                        final name = _contactNameController.text.trim();
                        // Liên hệ khẩn cấp: cả tên + SĐT phải cùng có hoặc cùng trống.
                        if (name.isNotEmpty && t.isEmpty) {
                          return 'Nhập SĐT khi đã nhập tên liên hệ';
                        }
                        if (t.isEmpty) return null; // không có liên hệ → OK
                        if (!RegExp(r'^[0-9]{10}$').hasMatch(t)) {
                          return 'SĐT phải đúng 10 chữ số';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
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
