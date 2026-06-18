import 'package:flutter/material.dart';

/// Slider điều chỉnh bán kính vùng an toàn.
class SafeZoneSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  /// Callback khi người dùng thả tay (kết thúc kéo) — dùng để persist lên server
  /// (tránh spam API trên mỗi tick kéo).
  final ValueChanged<double>? onChangeEnd;

  const SafeZoneSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.gpp_maybe, color: Color(0xFFE53935)),
        const SizedBox(width: 8),
        Expanded(
          child: Slider(
            value: value,
            min: 100,
            max: 800,
            divisions: 7,
            activeColor: const Color(0xFFE53935),
            inactiveColor: Colors.grey.shade300,
            label: '${value.toStringAsFixed(0)}m',
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ),
        Text(
          '${value.toStringAsFixed(0)}m',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFE53935)),
        ),
      ],
    );
  }
}
