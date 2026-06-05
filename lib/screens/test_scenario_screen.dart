import 'package:flutter/material.dart';
import '../models/elderly_model.dart';
import '../utils/app_state.dart';

/// Màn hình chọn 1 trong 3 kịch bản kiểm thử (mô phỏng).
/// Mỗi kịch bản:
///  - Hiển thị icon & mô tả chi tiết
///  - Khi chọn → gọi AppState để kích hoạt
class TestScenarioScreen extends StatefulWidget {
  final ElderlyModel elderly;
  const TestScenarioScreen({super.key, required this.elderly});

  @override
  State<TestScenarioScreen> createState() => _TestScenarioScreenState();
}

enum _Scenario { fall, exit, vital }

class _TestScenarioScreenState extends State<TestScenarioScreen> {
  bool _isRunning = false;
  _Scenario? _running;

  Future<void> _runScenario(_Scenario scenario) async {
    if (_isRunning) return;
    setState(() {
      _isRunning = true;
      _running = scenario;
    });

    final state = AppState();
    switch (scenario) {
      case _Scenario.fall:
        state.simulateFall(widget.elderly.id);
        break;
      case _Scenario.exit:
        state.simulateExitSafeZone(widget.elderly.id);
        break;
      case _Scenario.vital:
        state.simulateHeartRateSpike(widget.elderly.id);
        break;
    }

    // Delay nhỏ để user thấy hiệu ứng loading
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _isRunning = false;
      _running = null;
    });

    // Nếu là critical (fall/exit) thì đóng màn hình này để về Home
    // → Home sẽ tự push AlertDetailScreen
    if (scenario != _Scenario.vital) {
      if (!mounted) return;
      // Pop về Home (pop cả DetailScreen và TestScenarioScreen)
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      // Warning: chỉ snackbar, ở lại màn hình
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Kịch bản "Nhịp tim" đã kích hoạt — xem chỉ số trên Home'),
          backgroundColor: Colors.teal,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1400),
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
                    '🧪 KỊCH BẢN KIỂM THỬ',
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

            // Banner cảnh báo
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade700),
              ),
              child: Row(
                children: [
                  Icon(Icons.science, color: Colors.amber.shade700, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Đây là chế độ MÔ PHỎNG — dùng để demo và kiểm thử hệ thống trước khi triển khai thực tế.',
                      style: TextStyle(
                        color: Colors.amber.shade100,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Đối tượng test
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(widget.elderly.avatar),
                    backgroundColor: Colors.teal.shade100,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.elderly.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.elderly.wearableDevice,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 3 scenario cards
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildScenarioCard(
                    scenario: _Scenario.fall,
                    icon: Icons.accessible_forward,
                    title: 'TÉ NGÃ',
                    description:
                        'Giả lập cảm biến gia tốc trên thiết bị đeo phát hiện người thân bị ngã. '
                        'Vị trí sẽ dịch chuyển ~80m để mô phỏng điểm té ngã.\n\n'
                        '→ Tạo cảnh báo mức CRITICAL\n'
                        '→ Tự mở màn hình SOS đỏ',
                    color: Colors.deepOrange,
                    isCritical: true,
                  ),
                  const SizedBox(height: 12),
                  _buildScenarioCard(
                    scenario: _Scenario.exit,
                    icon: Icons.location_off,
                    title: 'RA NGOÀI VÙNG AN TOÀN',
                    description:
                        'Đẩy tọa độ người thân ra xa 400m so với tâm vùng an toàn. '
                        'Mô phỏng người thân đi lạc ra khỏi khu vực quen thuộc.\n\n'
                        '→ Tạo cảnh báo mức CRITICAL\n'
                        '→ Tự mở màn hình SOS đỏ',
                    color: Colors.red,
                    isCritical: true,
                  ),
                  const SizedBox(height: 12),
                  _buildScenarioCard(
                    scenario: _Scenario.vital,
                    icon: Icons.favorite,
                    title: 'NHỊP TIM & SpO2 BẤT THƯỜNG',
                    description:
                        'Đặt nhịp tim 118 bpm (cao) và SpO2 91% (thấp). '
                        'Mô phỏng chỉ số sinh tồn bất thường cần theo dõi.\n\n'
                        '→ Tạo cảnh báo mức WARNING\n'
                        '→ Cập nhật banner cảnh báo vàng trên Home',
                    color: Colors.pink,
                    isCritical: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScenarioCard({
    required _Scenario scenario,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required bool isCritical,
  }) {
    final isThisRunning = _running == scenario;
    return Material(
      color: color.withValues(alpha: (_running != null && !isThisRunning) ? 0.3 : 1.0),
      borderRadius: BorderRadius.circular(12),
      elevation: 3,
      child: InkWell(
        onTap: _isRunning ? null : () => _runScenario(scenario),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  if (isCritical)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'CRITICAL',
                        style: TextStyle(
                          color: color,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isThisRunning) ...[
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'ĐANG KÍCH HOẠT...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ] else
                    Row(
                      children: const [
                        Text(
                          'BẤM ĐỂ CHẠY',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
