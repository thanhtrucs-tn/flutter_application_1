import 'package:flutter/material.dart';

/// Dãy chip lọc ngang cho danh sách.
class FilterChipBar extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  const FilterChipBar({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: options.map((opt) {
          final isSelected = selected == opt;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(opt),
              selected: isSelected,
              onSelected: (_) => onSelected(opt),
              selectedColor: const Color(0xFFE53935),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: Colors.grey.shade100,
            ),
          );
        }).toList(),
      ),
    );
  }
}
