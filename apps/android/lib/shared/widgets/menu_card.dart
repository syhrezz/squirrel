import 'package:flutter/material.dart';

/// A large tappable menu card for the Home screen.
///
/// Visual redesign: white card, subtle shadow, no hard border,
/// larger radius, softer icon container (low-opacity green background).
/// Layout and behavior unchanged.
class MenuCard extends StatelessWidget {
  const MenuCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
    this.comingSoon = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;
  final bool comingSoon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEnabled = !comingSoon && onTap != null;

    return Material(
      color: isEnabled ? Colors.white : const Color(0xFFF7F7F7),
      borderRadius: BorderRadius.circular(16),
      elevation: isEnabled ? 2 : 0,
      shadowColor: Colors.black.withAlpha(18),
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        splashColor: colorScheme.primary.withAlpha(20),
        highlightColor: colorScheme.primary.withAlpha(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              // Icon container — low-saturation green, rounded square
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isEnabled
                      ? colorScheme.primary.withAlpha(18)
                      : const Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  size: 26,
                  color: isEnabled
                      ? colorScheme.primary
                      : const Color(0xFFBDBDBD),
                ),
              ),
              const SizedBox(width: 16),

              // Title + description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: isEnabled
                                  ? const Color(0xFF1A1A1A)
                                  : const Color(0xFF9E9E9E),
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        if (comingSoon) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F0F0),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Segera Hadir',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF9E9E9E),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF757575),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              if (isEnabled) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  color: const Color(0xFFBDBDBD),
                  size: 22,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
