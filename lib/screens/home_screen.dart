import 'package:flutter/material.dart';
import '../utils/app_state.dart';
import '../utils/localization.dart';
import '../models/elderly_model.dart';
import '../models/alert_model.dart';
import '../models/address_model.dart';
import '../services/address_service.dart';
import '../widgets/custom_map.dart';
import '../widgets/address_badge.dart';
import '../widgets/full_screen_map_modal.dart';
import '../widgets/add_relative_dialog.dart';
import 'detail_screen.dart';
import 'alert_detail_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';

/// Màn hình chính tổng quan an toàn của SOS Care
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Người thân hiện đang được chọn để định vị trên bản đồ ở trang chủ
  int _selectedElderlyId = 1;

  // Service reverse geocoding + cache
  final AddressService _addressService = AddressService();

  // State cho address của người thân đang chọn
  Address? _currentAddress;
  bool _isLoadingAddress = false;
  int? _lastFetchedElderlyId;

  @override
  void initState() {
    super.initState();
  }

  /// Đăng xuất khỏi ứng dụng
  void _logout(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  /// Thêm người thân mới — mở dialog nhập liệu.
  void _addRelativePressed() {
    AddRelativeDialog.show(context);
  }

  /// Lấy địa chỉ từ tọa độ GPS thông qua Nominatim (có cache)
  Future<void> _fetchAddressFor(ElderlyModel elderly) async {
    if (_lastFetchedElderlyId == elderly.id &&
        _currentAddress != null &&
        !_isLoadingAddress) {
      return; // Đã fetch cho người này rồi
    }

    setState(() {
      _isLoadingAddress = true;
      _lastFetchedElderlyId = elderly.id;
    });

    final address = await _addressService.getAddress(
      elderly.latitude,
      elderly.longitude,
    );

    if (!mounted) return;

    setState(() {
      _currentAddress = address;
      _isLoadingAddress = false;
    });
  }

  /// Mở modal fullscreen map khi người dùng tap vào zone map
  Future<void> _openFullScreenMap(ElderlyModel elderly) async {
    // Đảm bảo đã fetch address trước khi mở modal
    if (_currentAddress == null && !_isLoadingAddress) {
      await _fetchAddressFor(elderly);
    }
    if (!mounted) return;

    await FullScreenMapModal.show(
      context: context,
      lat: elderly.latitude,
      lng: elderly.longitude,
      safeZoneLat: elderly.safeZoneLat,
      safeZoneLng: elderly.safeZoneLng,
      safeZoneRadius: elderly.safeZoneRadius,
      relativeName: elderly.name,
      safetyStatus: elderly.status,
      address: _currentAddress,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: state,
      builder: (context, child) {
        final relatives = state.relatives;
        final alerts = state.alerts;
        final activeAlert = state.activeAlert;

        // TỰ ĐỘNG BẬT MÀN HÌNH BÁO ĐỘNG SOS NẾU CÓ ACTIVE ALERT
        if (activeAlert != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Kiểm tra tránh push đè nhiều lần cùng 1 alert
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AlertDetailScreen(alert: activeAlert),
              ),
            );
            // Xóa tạm thời để tránh lặp vô hạn
            state.acknowledgeAlert(activeAlert.id);
          });
        }

        // Xác định độ an toàn tổng hợp để đổi màu Banner chính
        bool hasCritical = relatives.any((e) => e.status == 'critical' && !e.isOffline);
        bool hasWarning = relatives.any((e) => e.status == 'warning' && !e.isOffline);
        
        Color bannerColor = Colors.green;
        String bannerTitle = Localization.translate('statusSafeText');
        String bannerDesc = 'Tất cả người thân đang trong khu vực an toàn.';
        IconData bannerIcon = Icons.check_circle;

        if (hasCritical) {
          bannerColor = Colors.red;
          bannerTitle = 'SOS KHẨN CẤP!';
          bannerDesc = 'Có người thân cần hỗ trợ ngay lập tức!';
          bannerIcon = Icons.gpp_maybe;
        } else if (hasWarning) {
          bannerColor = Colors.orange;
          bannerTitle = 'CHÚ Ý CẢNH BÁO';
          bannerDesc = 'Có chỉ số sinh hiệu sức khỏe bất thường.';
          bannerIcon = Icons.warning;
        }

        // Lấy người thân được chọn làm tâm bản đồ
        ElderlyModel? selectedElderly;
        try {
          selectedElderly = relatives.firstWhere((e) => e.id == _selectedElderlyId);
        } catch (_) {
          if (relatives.isNotEmpty) {
            selectedElderly = relatives.first;
            _selectedElderlyId = selectedElderly.id;
          }
        }

        // Fetch địa chỉ reverse geocoding cho người thân đang chọn (async, không block UI)
        if (selectedElderly != null) {
          // Schedule sau frame để không gọi setState trong build phase
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _fetchAddressFor(selectedElderly!);
          });
        }

        return Scaffold(
          appBar: AppBar(
            leading: const Icon(Icons.health_and_safety, color: Colors.teal),
            title: Text(
              Localization.translate('appName'),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            centerTitle: false, // Android-style left-aligned title
            actions: [
              // Nút Cài đặt
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: Localization.translate('settings'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                },
              ),
              // Nút Đăng xuất
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: Localization.translate('logout'),
                onPressed: () => _logout(context),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _addRelativePressed,
            backgroundColor: Colors.teal,
            child: const Icon(Icons.person_add),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Header người dùng & kết nối
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Xin chào, Người Thân',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                          Text(
                            'Tài khoản giám sát',
                            style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                    // WebSocket online badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: state.isWebSocketConnected ? Colors.teal.withOpacity(0.12) : Colors.red.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            state.isWebSocketConnected ? Icons.swap_vertical_circle : Icons.offline_bolt,
                            size: 14,
                            color: state.isWebSocketConnected ? Colors.teal : Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            state.isWebSocketConnected ? 'Realtime' : 'Disconn',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: state.isWebSocketConnected ? Colors.teal : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 2. Banner Trạng thái an toàn tổng thể
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: bannerColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: bannerColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(bannerIcon, color: Colors.white, size: 40),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bannerTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              bannerDesc,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Bản đồ vị trí ở trang chủ (Định vị người cao tuổi đang chọn)
                if (selectedElderly != null) ...[
                  Builder(
                    builder: (context) {
                      // Local non-null binding cho Dart type inference
                      final elderly = selectedElderly!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '🗺️ BẢN ĐỒ ĐỊNH VỊ NHANH',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              Text(
                                'Đang theo dõi: ${elderly.name}',
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          CustomMap(
                            lat: elderly.latitude,
                            lng: elderly.longitude,
                            safeZoneLat: elderly.safeZoneLat,
                            safeZoneLng: elderly.safeZoneLng,
                            safeZoneRadius: elderly.safeZoneRadius,
                            safetyStatus: elderly.status,
                            height: 280,
                            relativeName: elderly.name,
                            onZoneTap: () => _openFullScreenMap(elderly),
                          ),
                          const SizedBox(height: 10),

                          // Badge hiển thị địa chỉ chi tiết bên dưới map
                          AddressBadge.fromAddress(
                            address: _currentAddress,
                            isLoading: _isLoadingAddress,
                            relativeName: elderly.name,
                            onTap: () => _openFullScreenMap(elderly),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],

                // 4. Danh sách người thân
                _buildSectionHeader('👥 ' + Localization.translate('relativeList').toUpperCase()),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: relatives.length,
                  itemBuilder: (context, index) {
                    final r = relatives[index];
                    
                    // Xác định màu đường viền thẻ dựa theo trạng thái an toàn
                    Color cardBorderColor = Colors.grey.shade300;
                    Color statusDotColor = Colors.green;
                    String statusText = Localization.translate('statusSafeText');
                    
                    if (r.isOffline) {
                      cardBorderColor = Colors.grey.shade400;
                      statusDotColor = Colors.grey;
                      statusText = Localization.translate('statusOffline');
                    } else if (r.status == 'critical') {
                      cardBorderColor = Colors.red.shade400;
                      statusDotColor = Colors.red;
                      statusText = Localization.translate('statusCriticalText');
                    } else if (r.status == 'warning') {
                      cardBorderColor = Colors.orange.shade400;
                      statusDotColor = Colors.orange;
                      statusText = Localization.translate('statusWarningText');
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: cardBorderColor, width: _selectedElderlyId == r.id ? 2.5 : 1.0),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          // Tap vào thẻ để xem chi tiết
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailScreen(elderlyId: r.id),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Dòng thông tin cơ bản
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundImage: NetworkImage(r.avatar),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              r.name,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                            ),
                                            const SizedBox(width: 8),
                                            // Chấm trạng thái kết nối
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(color: statusDotColor, shape: BoxShape.circle),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          '${Localization.translate('wearableDevice')}: ${r.wearableDevice}',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Nút chọn định vị lên map chính
                                  IconButton(
                                    icon: Icon(
                                      _selectedElderlyId == r.id ? Icons.gps_fixed : Icons.gps_not_fixed,
                                      color: _selectedElderlyId == r.id ? Colors.teal : Colors.grey,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _selectedElderlyId = r.id;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              
                              // Hàng chỉ số sinh hiệu cơ bản
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Nhịp tim
                                  _buildVitalBadge(
                                    icon: Icons.favorite,
                                    color: Colors.red,
                                    value: r.isOffline ? '--' : '${r.heartRate} bpm',
                                  ),
                                  // SpO2
                                  _buildVitalBadge(
                                    icon: Icons.opacity,
                                    color: Colors.blueAccent,
                                    value: r.isOffline ? '--' : 'SpO2: ${r.spo2}%',
                                  ),
                                  // Mức Pin thiết bị đeo
                                  _buildVitalBadge(
                                    icon: Icons.battery_charging_full,
                                    color: r.battery > 30 ? Colors.green : Colors.orange,
                                    value: '${r.battery}%',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              
                              // Thời gian cập nhật gần nhất
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${Localization.translate('lastUpdate')}: ${r.lastUpdated.hour}:${r.lastUpdated.minute.toString().padLeft(2, '0')}',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: statusDotColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      statusText.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: statusDotColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // 5. Lịch sử sự cố SOS
                _buildSectionHeader('📜 ' + Localization.translate('warningHistory').toUpperCase()),
                Card(
                  elevation: 2,
                  child: alerts.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: Text('Không có lịch sử sự cố cảnh báo.'),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: alerts.length > 5 ? 5 : alerts.length, // Tối đa hiển thị 5 sự kiện gần nhất
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final a = alerts[index];
                            Color urgencyColor = a.urgency == 'critical' ? Colors.red : Colors.orange;

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: urgencyColor.withOpacity(0.12),
                                child: Icon(
                                  a.urgency == 'critical' ? Icons.gpp_maybe : Icons.warning,
                                  color: urgencyColor,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                a.message,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              subtitle: Text(
                                '${a.time.hour}:${a.time.minute.toString().padLeft(2, '0')} - ${a.locationName}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: a.acknowledged ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  a.acknowledged ? 'ĐÃ XỬ LÝ' : 'CHƯA XỬ LÝ',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: a.acknowledged ? Colors.green : Colors.red,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVitalBadge({required IconData icon, required Color color, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, top: 24.0, bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.teal,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
