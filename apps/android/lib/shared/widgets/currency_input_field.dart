import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A numeric input field for IDR amounts.
///
/// Extracted from RestockScreen's purchase price field and
/// PenjualanScreen's customer payment field — both were:
///   - digits-only
///   - prefixed with "Rp "
///   - dense layout
///   - same border style
///
/// The parent provides the controller and handles `onChanged`.
class CurrencyInputField extends StatelessWidget {
  const CurrencyInputField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.label,
    this.hintText = '0',
    this.errorText,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final void Function(String) onChanged;

  /// Optional label shown above the field (e.g. 'Harga Beli (Rp)').
  final String? label;
  final String hintText;
  final String? errorText;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      autofocus: autofocus,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixText: 'Rp ',
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 10,
        ),
        border: const OutlineInputBorder(),
        errorText: errorText,
      ),
    );
  }
}
