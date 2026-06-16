import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/care_alert.dart';
import '../../domain/entities/care_device.dart';
import '../providers/providers.dart';
import '../widgets/alert_card.dart';
import '../widgets/connection_status_bar.dart';
import '../widgets/device_card.dart';
import 'alerts_screen.dart';

/// Main dashboard of the SOS Care app.
///
/// Shows connection status, monitored devices, and recent critical alerts.
/// All data updates automatically as Socket.IO events arrive.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Timer? _connectionTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectSocket();
    });
  }

  @override
  void dispose() {
    _connectionTimer?.cancel();
    super.dispose();
  }

  void _connectSocket() {
    final socketService = ref.read(socketIOServiceProvider);
    final socketStateNotifier = ref.read(socketStateNotifierProvider.notifier);
    final alertsNotifier = ref.read(careAlertsNotifierProvider.notifier);
    final devicesNotifier = ref.read(careDevicesNotifierProvider.notifier);

    socketService.addListener((event, payload) {
      switch (event) {
        case 'sos:alert':
        case 'event:fall':
        case 'event:heart_rate':
          alertsNotifier.handleRealtimeEvent(event, payload);
          devicesNotifier.handleAlertEvent(payload);
          break;
        case 'device:location':
          devicesNotifier.handleLocationEvent(payload);
          break;
        case 'device:status':
          devicesNotifier.handleStatusEvent(payload);
          break;
      }
    });

    socketService.connect();
    socketStateNotifier.setConnecting();

    _connectionTimer = Timer(const Duration(seconds: 1), () {
      if (socketService.isConnected) {
        socketStateNotifier.setConnected();
      } else {
        socketStateNotifier.setError();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final devices = ref.watch(careDevicesNotifierProvider);
    final alerts = ref.watch(careAlertsNotifierProvider);
    final criticalAlerts = alerts.where((a) => a.isCritical).take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS Care'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => _openAlertsScreen(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ConnectionStatusBar(),
            if (criticalAlerts.isNotEmpty) _buildCriticalAlertsSection(criticalAlerts),
            Expanded(
              child: _buildDevicesSection(devices),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCriticalAlertsSection(List<CareAlert> alerts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Cảnh báo gần đây',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        ...alerts.map((alert) => AlertCard(alert: alert, onTap: () {})),
      ],
    );
  }

  Widget _buildDevicesSection(List<CareDevice> devices) {
    if (devices.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Chưa có thiết bị nào kết nối.\nHãy khởi động SOS Device Simulator và gửi dữ liệu.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: devices.length,
      itemBuilder: (context, index) {
        final device = devices[index];
        return DeviceCard(
          device: device,
          onTap: () {
            ref.read(selectedDeviceProvider.notifier).state = device;
            _openDeviceDetail(context, device);
          },
        );
      },
    );
  }

  void _openAlertsScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AlertsScreen()),
    );
  }

  void _openDeviceDetail(BuildContext context, CareDevice device) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Mở chi tiết thiết bị ${device.elderlyId}')),
    );
  }
}
