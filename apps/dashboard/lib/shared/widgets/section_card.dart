import 'package:flutter/material.dart';
import '../../theme/dashboard_theme.dart';

/// A clean white card with a subtle border. Used for all content sections.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(DashboardTheme.sp24),
    this.title,
    this.subtitle,
    this.trailing,
  });

  final Widget child;
  final EdgeInsets padding;
  final String? title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DashboardTheme.surface,
        borderRadius: BorderRadius.circular(DashboardTheme.radius8),
        border: Border.all(color: DashboardTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  DashboardTheme.sp24,
                  DashboardTheme.sp16,
                  DashboardTheme.sp24,
                  DashboardTheme.sp16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title!,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(subtitle!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
            Divider(
                height: 1,
                thickness: 1,
                color: DashboardTheme.border),
          ],
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}
