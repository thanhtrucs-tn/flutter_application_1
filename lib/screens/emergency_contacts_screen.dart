import 'package:flutter/material.dart';
import '../models/elderly_model.dart';
import '../utils/localization.dart';
import '../widgets/sos_app_header.dart';
import '../widgets/contact_list_item.dart';
import '../widgets/add_contact_dialog.dart';

/// Màn hình danh bạ khẩn cấp của một người cao tuổi.
class EmergencyContactsScreen extends StatelessWidget {
  final ElderlyModel elderly;

  const EmergencyContactsScreen({super.key, required this.elderly});

  void _makeCall(BuildContext context, String phone) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(children: [Icon(Icons.phone, color: Colors.green), SizedBox(width: 8), Text('Cuộc gọi SOS Care')]),
        content: Text('Hệ thống đang kết nối cuộc gọi thoại khẩn cấp tới số:\n$phone'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SosAppHeader(
        title: Localization.translate('emergencyContactsTitle'),
        showBackButton: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: elderly.emergencyContacts.length,
        itemBuilder: (context, index) {
          // Mỗi phần tử có dạng "Tên: SĐT" → tách để hiển thị tên riêng, SĐT riêng.
          final raw = elderly.emergencyContacts[index];
          final split = ElderlyModel.splitContact(raw);
          final name = split.$1;
          final phone = split.$2;
          // Nếu chưa có tên (chuỗi cũ chỉ chứa SĐT) thì hiển thị SĐT làm tên tạm.
          final displayName = name.isEmpty ? phone : name;
          return ContactListItem(
            name: displayName,
            relationship: 'Người giám hộ khẩn cấp',
            phone: phone,
            onCallTap: () => _makeCall(context, phone),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AddContactDialog.show(context, elderly.id),
        backgroundColor: const Color(0xFFE53935),
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
