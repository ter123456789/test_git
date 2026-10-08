import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ช่องกรอกตัวเลข ตรวจว่าเป็นตัวเลขที่อยู่ในช่วง [min]..[max]
class NumberField extends StatelessWidget {
  const NumberField({
    super.key,
    required this.controller,
    required this.label,
    this.suffix,
    this.min = 0,
    this.max = double.infinity,
    this.allowDecimal = true,
    this.allowZero = false,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String label;
  final String? suffix;
  final double min;
  final double max;
  final bool allowDecimal;
  final bool allowZero;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      autofocus: autofocus,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          allowDecimal ? RegExp(r'[0-9.]') : RegExp(r'[0-9]'),
        ),
      ],
      validator: (text) {
        final value = double.tryParse(text ?? '');
        if (value == null) return 'กรุณากรอกตัวเลข';
        if (!allowZero && value == 0) return 'ต้องมากกว่า 0';
        if (value < min || value > max) {
          return 'ต้องอยู่ระหว่าง ${_fmt(min)} ถึง ${_fmt(max)}';
        }
        return null;
      },
    );
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}
