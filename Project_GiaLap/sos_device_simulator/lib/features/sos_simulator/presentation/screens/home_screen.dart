import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/operation_result.dart';
import '../providers/device_status_notifier.dart';
import '../providers/providers.dart';
import '../widgets/battery_slider_card.dart';
import '../widgets/device_info_card.dart';
import '../widgets/function_button_grid.dart';
import '../widgets/heart_rate_slider_card.dart';
import '../widgets/online_switch_tile.dart';
import '../widgets/sos_button.dart';

/// Main screen of the SOS Device Simulator.
///
/// Displays the device info card, the large SOS button, simulator
/// controls, sliders, and the online/offline switch. Shows Snackbar
/// feedback for every backend operation.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _booted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    if (_booted) return;
    _booted = true;
    await ref.read(deviceStatusNotifierProvider.notifier).bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(deviceStatusNotifierProvider);
    final notifier = ref.read(deviceStatusNotifierProvider.notifier);

    _listenForOperationResult(context, ref);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS Device Simulator'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DeviceInfoCard(status: status),
                    const SizedBox(height: 16),
                    Builder(
                      builder: (context) => _buildSosSection(context, notifier),
                    ),
                    const SizedBox(height: 16),
                    FunctionButtonGrid(
                      onFallSimulated: notifier.sendFallEvent,
                      onHeartRateAlert: () => notifier.sendEvent('HEART_RATE_ALERT'),
                      onOfflineSimulated: notifier.simulateOffline,
                      onSendLocation: notifier.sendCurrentLocation,
                    ),
                    const SizedBox(height: 16),
                    BatterySliderCard(
                      batteryPercent: status.batteryPercent,
                      onChanged: (value) => notifier.setBattery(value.toInt()),
                    ),
                    const SizedBox(height: 12),
                    HeartRateSliderCard(
                      heartRateBpm: status.heartRateBpm,
                      onChanged: (value) => notifier.setHeartRate(value.toInt()),
                    ),
                    const SizedBox(height: 12),
                    OnlineSwitchTile(
                      isOnline: status.isOnline,
                      onChanged: notifier.setOnline,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSosSection(BuildContext context, DeviceStatusNotifier notifier) {
    return SizedBox(
      height: 240,
      child: Center(
        child: SosButton(
          onPressed: () => _showSosConfirmation(context, notifier),
        ),
      ),
    );
  }

  void _showSosConfirmation(
    BuildContext context,
    DeviceStatusNotifier notifier,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.emergency, color: Colors.red, size: 48),
        title: const Text('Xác nhận gửi SOS'),
        content: const Text(
          'Bạn có chắc chắn muốn gửi cảnh báo khẩn cấp SOS?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              notifier.sendSosAlert();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Gửi SOS'),
          ),
        ],
      ),
    );
  }

  void _listenForOperationResult(BuildContext context, WidgetRef ref) {
    ref.listen(
      deviceStatusNotifierProvider.select(
        (status) => status.lastOperationResult,
      ),
      (previous, next) {
        if (next == null || previous == next) return;
        final result = next;
        final message = switch (result) {
          OperationSuccess success => success.message,
          OperationFailure failure => failure.failure.message,
        };
        final color = switch (result) {
          OperationSuccess() => Colors.green,
          OperationFailure() => Colors.red,
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: color,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }
}
