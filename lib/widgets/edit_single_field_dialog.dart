import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Dialog sửa 1 trường duy nhất (tên / email / SĐT).
/// Trả về giá trị mới (đã trim) qua Navigator.pop; null nếu huỷ.
class EditSingleFieldDialog extends StatefulWidget {
  final String title;
  final String label;
  final String initialValue;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final String? hint;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;

  const EditSingleFieldDialog({
    super.key,
    required this.title,
    required this.label,
    required this.initialValue,
    this.validator,
    this.keyboardType,
    this.hint,
    this.maxLength,
    this.inputFormatters,
  });

  @override
  State<EditSingleFieldDialog> createState() => _EditSingleFieldDialogState();
}

class _EditSingleFieldDialogState extends State<EditSingleFieldDialog> {
  late final TextEditingController _ctrl;
  final _formKey = GlobalKey<FormState>();
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onSave() {
    setState(() => _hasError = true);
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, _ctrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        autovalidateMode: _hasError
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: TextFormField(
          controller: _ctrl,
          keyboardType: widget.keyboardType,
          maxLength: widget.maxLength,
          inputFormatters: widget.inputFormatters,
          autofocus: true,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            border: const OutlineInputBorder(),
            counterText: widget.maxLength != null ? null : '',
          ),
          validator: widget.validator,
          onFieldSubmitted: (_) => _onSave(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Huỷ'),
        ),
        FilledButton(
          onPressed: _onSave,
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE53935)),
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}
