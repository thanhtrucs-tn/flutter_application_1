import 'package:flutter/material.dart';
import '../models/alert_model.dart';
import '../utils/app_state.dart';
import '../utils/localization.dart';
import '../widgets/sos_app_header.dart';
import '../widgets/big_button.dart';

/// Màn hình thêm cảnh báo mới thủ công.
class AddAlertScreen extends StatefulWidget {
  const AddAlertScreen({super.key});

  @override
  State<AddAlertScreen> createState() => _AddAlertScreenState();
}

class _AddAlertScreenState extends State<AddAlertScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  String _level = 'critical';
  int? _relatedId;

  @override
  void initState() {
    super.initState();
    final relatives = AppState().relatives;
    if (relatives.isNotEmpty) _relatedId = relatives.first.id;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _relatedId == null) return;
    final state = AppState();
    final elderly = state.relatives.firstWhere((e) => e.id == _relatedId);
    final alert = AlertModel(
      id: 'alert_${DateTime.now().millisecondsSinceEpoch}',
      elderlyId: elderly.id,
      elderlyName: elderly.name,
      time: DateTime.now(),
      locationName: 'Khu vực nhà ở (Vùng An Toàn)',
      urgency: _level,
      message: _titleCtrl.text.trim(),
      acknowledged: false,
      latitude: elderly.latitude,
      longitude: elderly.longitude,
    );
    final messenger = ScaffoldMessenger.of(context);
    try {
      await state.addAlert(alert);
      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Đã lưu cảnh báo mới'), backgroundColor: Colors.green),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Lưu cảnh báo thất bại'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState();
    return AnimatedBuilder(
      animation: state,
      builder: (context, child) {
        final relatives = state.relatives;
        return Scaffold(
          appBar: SosAppHeader(
            title: 'Thêm cảnh báo mới',
            showBackButton: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _titleCtrl,
                    maxLength: 100,
                    maxLines: 1,
                    decoration: InputDecoration(
                      labelText: Localization.translate('title'),
                      counterText: '',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Nhập tiêu đề' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _contentCtrl,
                    maxLength: 500,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: Localization.translate('content'),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: Localization.translate('level')),
                    initialValue: _level,
                    items: const [
                      DropdownMenuItem(value: 'critical', child: Text('Khẩn cấp')),
                      DropdownMenuItem(value: 'warning', child: Text('Cảnh báo')),
                    ],
                    onChanged: (v) => setState(() => _level = v ?? 'critical'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    decoration: InputDecoration(labelText: Localization.translate('relatedPerson')),
                    initialValue: _relatedId,
                    items: relatives.map((r) => DropdownMenuItem(
                      value: r.id,
                      child: Text(r.name),
                    )).toList(),
                    onChanged: (v) => setState(() => _relatedId = v),
                  ),
                  const SizedBox(height: 24),
                  BigButton(
                    label: Localization.translate('saveAlert'),
                    icon: Icons.save,
                    color: const Color(0xFFE53935),
                    height: 56,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
