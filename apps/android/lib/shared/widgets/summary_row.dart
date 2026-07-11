import 'package:flutter/material.dart';

/// A label/value row used in summary sections.
///
/// Visual redesign: increased total value size to 24sp,
/// label uses onSurfaceVariant for visual hierarchy.
class SummaryRow extends StatelessWidget {
  const SummaryRow({
    super.key,
    required this.label,
    required this.value,
    this.isTotal = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool isTotal;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 15,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            color: isTotal
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 24 : 15,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal
                ? colorScheme.primary
                : valueColor ?? colorScheme.onSurface,
            letterSpacing: isTotal ? -0.5 : 0,
          ),
        ),
      ],
    );
  }
}
