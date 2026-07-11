import 'package:flutter/material.dart';

/// A floating panel pinned to the bottom of transaction screens.
///
/// Visual redesign:
/// - Rounded top corners (20dp) for the "floating panel" feel
/// - Stronger but softer shadow spread
/// - White surface matching card language
class TransactionFooter extends StatelessWidget {
  const TransactionFooter({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: child,
    );
  }
}

/// Full-width primary action button for transaction footers.
///
/// Visual redesign: taller (56dp), rounded (14dp), brand green,
/// no elevation — flat modern style matching Google apps.
class FooterActionButton extends StatelessWidget {
  const FooterActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.isSaving,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isSaving;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: (enabled && !isSaving) ? onPressed : null,
        // Style inherited from global ElevatedButtonTheme (green, rounded 14)
        child: isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(label),
      ),
    );
  }
}
