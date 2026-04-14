import 'package:flutter/material.dart';

class DatePickerDropdown extends StatelessWidget {
  final String label;
  final List<int> items;
  final int? selectedValue;
  final Function(int?) onChanged;
  final bool enabled;

  const DatePickerDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.selectedValue,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: enabled ? Colors.grey.shade400 : Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          hint: Text(label, style: TextStyle(color: Colors.grey.shade500)),
          value: selectedValue,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down,
              color: enabled ? Colors.grey.shade600 : Colors.grey.shade300),
          items: items.map((int value) {
            return DropdownMenuItem<int>(
              value: value,
              child: Text(value.toString()),
            );
          }).toList(),
          onChanged: enabled ? onChanged : null,
        ),
      ),
    );
  }
}
