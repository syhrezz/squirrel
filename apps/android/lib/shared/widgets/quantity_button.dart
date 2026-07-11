import 'package:flutter/material.dart';

/// A circular +/- quantity button.
///
/// Visual redesign: neutral grey container instead of saturated green,
/// reducing visual noise in dense transaction lists.
class QuantityButton extends StatelessWidget {
  const QuantityButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 36,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFEEEEEE),
        ),
        child: Icon(
          icon,
          size: size * 0.50,
          color: const Color(0xFF424242),
        ),
      ),
    );
  }
}
