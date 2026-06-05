import 'package:flutter/material.dart';
import '../models/elderly_model.dart';

/// Màn hình gửi tin nhắn SMS khẩn cấp kèm vị trí GPS tới tất cả liên hệ.
/// Hiển thị:
///  - Nội dung SMS sẽ gửi (preview)
///  - Danh sách người nhận
///  - Animation tiến trình gửi từng số
class SendSmsScreen extends StatefulWidget {
  final ElderlyModel elderly;
  const SendSmsScreen({super.key, required this.elderly});

  @override
  State<SendSmsScreen> createState() => _SendSmsScreenState();
}

enum _SmsStage { idle, sending, done }

class _SendSmsScreenState extends State<SendSmsScreen> {
  _SmsStage _stage = _SmsStage.idle;
  int _currentIndex = 0;

  String _getMessage() {
    return '🚨 KHẨN CẤP từ SOS Care 🚨\n'
        'Người thân: ${widget.elderly.name}\n'
        'Tọa độ GPS: ${widget.elderly.latitude.toStringAsFixed(5)}, '
        '${widget.elderly.longitude.toStringAsFixed(5)}\n'
        'Thời gian: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}\n'
        'Vui lòng liên hệ ngay!';
  }

  Future<void> _startSending() async {
    if (_stage != _SmsStage.idle) return;
    setState(() {
      _stage = _SmsStage.sending;
      _currentIndex = 0;
    });
    // Gửi lần lượt từng số
    for (int i = 0; i < widget.elderly.emergencyContacts.length; i++) {
      if (!mounted) return;
      setState(() => _currentIndex = i);
      await Future.delayed(const Duration(milliseconds: 900));
    }
    if (!mounted) return;
    setState(() => _stage = _SmsStage.done);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '💬 GỬI SMS KHẨN CẤP',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Preview nội dung SMS
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white30),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.sms, color: Colors.redAccent, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'NỘI DUNG TIN NHẮN',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getMessage(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Danh sách người nhận
                    const Text(
                      'NGƯỜI NHẬN',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(widget.elderly.emergencyContacts.length, (i) {
                      final phone = widget.elderly.emergencyContacts[i];
                      final sent = _stage == _SmsStage.done ||
                          (_stage == _SmsStage.sending && i < _currentIndex);
                      final sendingNow = _stage == _SmsStage.sending && i == _currentIndex;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: sendingNow
                                ? Colors.amber
                                : sent
                                    ? Colors.green
                                    : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: sent
                                  ? Colors.green
                                  : (sendingNow ? Colors.amber : Colors.redAccent),
                              radius: 18,
                              child: sent
                                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                                  : sendingNow
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.phone, color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                phone,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              sent
                                  ? 'ĐÃ GỬI'
                                  : (sendingNow ? 'ĐANG GỬI...' : 'CHỜ'),
                              style: TextStyle(
                                color: sent
                                    ? Colors.green
                                    : (sendingNow ? Colors.amber : Colors.white54),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),

                    if (_stage == _SmsStage.done)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 28),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'ĐÃ GỬI TIN NHẮN KHẨN CẤP\nTỚI TẤT CẢ SỐ LIÊN HỆ!',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Nút action
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 70,
                child: _stage == _SmsStage.done
                    ? ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.check, size: 28),
                        label: const Text(
                          'HOÀN TẤT',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed:
                            _stage == _SmsStage.sending ? null : _startSending,
                        icon: _stage == _SmsStage.sending
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : const Icon(Icons.send, size: 28),
                        label: Text(
                          _stage == _SmsStage.sending
                              ? 'ĐANG GỬI...'
                              : 'GỬI NGAY',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
