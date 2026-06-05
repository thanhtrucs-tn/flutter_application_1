import 'package:flutter/material.dart';
import '../models/elderly_model.dart';
import '../utils/localization.dart';
import '../widgets/sos_app_header.dart';
import '../widgets/contact_list_item.dart';

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
          final phone = elderly.emergencyContacts[index];
          return ContactListItem(
            name: phone,
            relationship: 'Người giám hộ khẩn cấp',
            phone: phone,
            onCallTap: () => _makeCall(context, phone),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: const Color(0xFFE53935),
        icon: const Icon(Icons.person_add),
        label: Text(Localization.translate('addContact')),
      ),
    );
  }
}
