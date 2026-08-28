import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/elderly_model.dart';
import '../models/emergency_contact_model.dart';
import '../services/api_client.dart';
import '../utils/app_state.dart';
import '../utils/localization.dart';
import '../widgets/avatar_picker.dart';
import '../widgets/sos_app_header.dart';

/// Màn hình chỉnh sửa thông tin người thân (profile + vùng an toàn + danh bạ).
///
/// Sửa toàn bộ các trường của 1 người thân và lưu 1 lần qua
/// [AppState.updateElderly] (PUT /api/relatives/:id). Ảnh đại diện được upload
/// riêng ngay khi người dùng chọn ảnh mới.
class EditRelativeScreen extends StatefulWidget {
  final int elderlyId;

  const EditRelativeScreen({super.key, required this.elderlyId});

  /// Mở màn hình dưới dạng hàm tiện ích.
  static void open(BuildContext context, int elderlyId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditRelativeScreen(elderlyId: elderlyId),
      ),
    );
  }

  @override
  State<EditRelativeScreen> createState() => _EditRelativeScreenState();
}

class _EditRelativeScreenState extends State<EditRelativeScreen> {
  final _formKey = GlobalKey<FormState>();
  late final ElderlyModel _relative;

  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _addressController;
  late final TextEditingController _deviceController;

  late double _safeRadius;
  late List<String> _contacts;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _relative = AppState().relatives.firstWhere((e) => e.id == widget.elderlyId);
    _nameController = TextEditingController(text: _relative.name);
    _ageController = TextEditingController(
      text: _relative.age != null ? '${_relative.age}' : '',
    );
    _addressController = TextEditingController(text: _relative.address);
    _deviceController = TextEditingController(text: _relative.wearableDevice);
    _safeRadius = _relative.safeZoneRadius.clamp(100.0, 5000.0);
    _contacts = List<String>.from(_relative.emergencyContacts);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _deviceController.dispose();
    super.dispose();
  }

  // --- Ảnh đại diện ---

  Future<void> _uploadAvatar(String path) async {
    if (_uploadingAvatar) return;
    _uploadingAvatar = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Flexible(child: Text(Localization.translate('uploadingAvatar'))),
            ],
          ),
        ),
      ),
    );

    var ok = false;
    String? error;
    try {
      ok = await AppState().updateElderlyAvatar(_relative.id, path);
      if (ok) {
        _relative = AppState().relatives.firstWhere((e) => e.id == widget.elderlyId);
      }
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Không kết nối được tới máy chủ';
    }

    if (!mounted) return;
    _uploadingAvatar = false;
    Navigator.of(context, rootNavigator: true).pop();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? Localization.translate('avatarUpdated')),
        backgroundColor: error != null ? Colors.red : Colors.green,
      ),
    );
  }

  bool _uploadingAvatar = false;

  // --- Danh bạ khẩn cấp ---

  Future<void> _addContact() async {
    final model = await showDialog<EmergencyContactModel>(
      context: context,
      builder: (_) => _ContactDialog(),
    );
    if (model == null) return;
    setState(() => _contacts.add(model.toStorageString()));
  }

  Future<void> _editContact(int index) async {
    final current = EmergencyContactModel.fromStorageString(_contacts[index]);
    final model = await showDialog<EmergencyContactModel>(
      context: context,
      builder: (_) => _ContactDialog(initial: current),
    );
    if (model == null) return;
    setState(() => _contacts[index] = model.toStorageString());
  }

  Future<void> _removeContact(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xóa liên hệ khẩn cấp?'),
        content: Text(
          EmergencyContactModel.fromStorageString(_contacts[index]).name,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(Localization.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _contacts.removeAt(index));
  }

  // --- Lưu ---

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final state = AppState();
    final base = state.relatives.firstWhere((e) => e.id == widget.elderlyId);
    final name = _nameController.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    final device = _deviceController.text.trim();
    final address = _addressController.text.trim();
    final age = int.tryParse(_ageController.text.trim());

    final updated = base.copyWith(
      name: name,
      age: age,
      address: address,
      wearableDevice: device,
      safeZoneRadius: _safeRadius,
      emergencyContacts: List<String>.from(_contacts),
    );

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await state.updateElderly(updated);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Đã lưu thông tin người thân: $name'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Lưu thất bại, vui lòng thử lại'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return Scaffold(
      appBar: SosAppHeader(
        title: _relative.name,
        subtitle: Localization.translate('editRelativeInfo'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Ảnh đại diện
            Card(
              elevation: 1,
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    AvatarPicker(
                      avatarUrl: _relative.avatar,
                      avatarLocalPath: _relative.avatarLocalPath,
                      radius: 56,
                      onPicked: _uploadAvatar,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      Localization.translate('tapAvatarToPickFromGallery'),
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Thông tin cơ bản
            Card(
              elevation: 1,
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                        labelText: 'Mã/Tên thiết bị đeo',
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
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      maxLength: 3,
                      decoration: InputDecoration(
                        labelText: '${Localization.translate('age')} (tùy chọn)',
                        prefixIcon: const Icon(Icons.cake_outlined),
                      ),
                      validator: (v) {
                        final t = v?.trim() ?? '';
                        if (t.isEmpty) return null;
                        final age = int.tryParse(t);
                        if (age == null || age < 40 || age > 130) {
                          return 'Tuổi phải từ 40 đến 130';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressController,
                      maxLength: 255,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: '${Localization.translate('address')} (tùy chọn)',
                        prefixIcon: const Icon(Icons.home_outlined),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Vùng an toàn
            Card(
              elevation: 1,
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.gpp_maybe, color: Color(0xFFE53935)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${Localization.translate('safeZone')}: ${_safeRadius.round()}m',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _safeRadius,
                      min: 100,
                      max: 5000,
                      divisions: 49,
                      label: '${_safeRadius.round()}m',
                      activeColor: const Color(0xFF10B981),
                      inactiveColor: Colors.grey.shade300,
                      onChanged: (v) => setState(() => _safeRadius = v),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Danh bạ khẩn cấp
            Card(
              elevation: 1,
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                      child: Row(
                        children: [
                          const Icon(Icons.contact_phone,
                              color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              Localization.translate('emergencyContactsTitle'),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: textColor,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _addContact,
                            icon: const Icon(Icons.person_add, size: 18),
                            label: Text(Localization.translate('addContactHint')),
                          ),
                        ],
                      ),
                    ),
                    if (_contacts.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Chưa có liên hệ khẩn cấp',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                        ),
                      )
                    else
                      ...List.generate(_contacts.length, (i) {
                        final c = EmergencyContactModel.fromStorageString(_contacts[i]);
                        return ListTile(
                          dense: true,
                          leading: const CircleAvatar(
                            radius: 18,
                            backgroundColor: Color(0xFFE53935),
                            child: Icon(Icons.person, color: Colors.white, size: 18),
                          ),
                          title: Text(
                            c.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            [if (c.relationship.isNotEmpty) c.relationship]
                                .join(', '),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                tooltip: Localization.translate('editInfo'),
                                onPressed: () => _editContact(i),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red, size: 20),
                                tooltip: Localization.translate('deleteRelative'),
                                onPressed: () => _removeContact(i),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                c.phone,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Lưu
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  _saving ? 'Đang lưu...' : Localization.translate('save'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

/// Dialog thêm/sửa 1 liên hệ khẩn cấp. Trả về [EmergencyContactModel] qua pop;
/// null nếu huỷ.
class _ContactDialog extends StatefulWidget {
  final EmergencyContactModel? initial;

  const _ContactDialog({this.initial});

  @override
  State<_ContactDialog> createState() => _ContactDialogState();
}

class _ContactDialogState extends State<_ContactDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _relationshipController;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial?.name ?? '');
    _phoneController = TextEditingController(text: widget.initial?.phone ?? '');
    _relationshipController =
        TextEditingController(text: widget.initial?.relationship ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      EmergencyContactModel(
        name: _nameController.text.trim().replaceAll(RegExp(r'\s+'), ' '),
        phone: _phoneController.text.trim(),
        relationship: _relationshipController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit
          ? Localization.translate('editInfo')
          : Localization.translate('addContactHint')),
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
                autofocus: true,
                decoration: InputDecoration(
                  labelText: Localization.translate('contactName'),
                  prefixIcon: const Icon(Icons.badge_outlined),
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
                    return Localization.translate('invalidPhone');
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
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}