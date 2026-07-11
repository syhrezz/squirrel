import 'package:flutter/material.dart';
import '../../theme/dashboard_theme.dart';

/// A metric display card — shows a label, value, and optional change indicator.
class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    this.change,
    this.changePositive,
    this.icon,
    this.iconColor,
  });

  final String label;
  final String value;
  final String? change;
  final bool? changePositive;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor =
        iconColor ?? DashboardTheme.primary;

    return Container(
      padding: const EdgeInsets.all(DashboardTheme.sp20),
      decoration: BoxDecoration(
        color: DashboardTheme.surface,
        borderRadius:
            BorderRadius.circular(DashboardTheme.radius8),
        border: Border.all(color: DashboardTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: effectiveIconColor.withAlpha(20),
                    borderRadius:
                        BorderRadius.circular(DashboardTheme.radius6),
                  ),
                  child: Icon(icon,
                      size: 16, color: effectiveIconColor),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: DashboardTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          if (change != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  (changePositive ?? true)
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  size: 14,
                  color: (changePositive ?? true)
                      ? DashboardTheme.success
                      : DashboardTheme.danger,
                ),
                const SizedBox(width: 4),
                Text(
                  change!,
                  style: TextStyle(
                    fontSize: 12,
                    color: (changePositive ?? true)
                        ? DashboardTheme.success
                        : DashboardTheme.danger,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
