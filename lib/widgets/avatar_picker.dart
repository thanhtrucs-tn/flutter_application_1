import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Widget hiển thị avatar lớn, bấm vào sẽ mở image_picker để chọn ảnh.
/// Trả về đường dẫn file local (String) qua callback `onPicked`;
/// hoặc null nếu người dùng huỷ / không có ảnh khả dụng.
class AvatarPicker extends StatefulWidget {
  final String avatarUrl;
  final String avatarLocalPath;
  final ValueChanged<String> onPicked;
  final double radius;

  const AvatarPicker({
    super.key,
    required this.avatarUrl,
    required this.avatarLocalPath,
    required this.onPicked,
    this.radius = 48,
  });

  @override
  State<AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<AvatarPicker> {
  final ImagePicker _picker = ImagePicker();
  bool _picking = false;

  ImageProvider? _buildImageProvider() {
    // Ưu tiên ảnh local nếu có
    if (widget.avatarLocalPath.isNotEmpty) {
      final file = File(widget.avatarLocalPath);
      if (file.existsSync()) {
        return FileImage(file);
      }
    }
    // Fallback về URL
    if (widget.avatarUrl.isNotEmpty) {
      return NetworkImage(widget.avatarUrl);
    }
    return null;
  }

  Future<void> _pickImage() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (file != null && mounted) {
        widget.onPicked(file.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể mở thư viện ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = _buildImageProvider();
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        GestureDetector(
          onTap: _picking ? null : _pickImage,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: widget.radius,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: image,
              child: _picking
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : image == null
                      ? const Icon(Icons.person, size: 48, color: Colors.grey)
                      : null,
            ),
          ),
        ),
        Material(
          color: const Color(0xFFE53935),
          shape: const CircleBorder(),
          elevation: 2,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _picking ? null : _pickImage,
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.camera_alt, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }
}
