import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/dashboard_theme.dart';

class TopBar extends ConsumerWidget {
  const TopBar({super.key, required this.title, this.breadcrumb});

  final String title;
  final String? breadcrumb;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? '';
    final initials = email.isNotEmpty
        ? email[0].toUpperCase()
        : 'A';

    return Container(
      height: DashboardTheme.topBarHeight,
      decoration: BoxDecoration(
        color: DashboardTheme.surface,
        border: Border(
          bottom: BorderSide(color: DashboardTheme.border),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Page title + breadcrumb
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (breadcrumb != null)
                  Text(
                    breadcrumb!,
                    style: TextStyle(
                      fontSize: 11,
                      color: DashboardTheme.textTertiary,
                    ),
                  ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Search placeholder
          Container(
            width: 240,
            height: 32,
            decoration: BoxDecoration(
              color: DashboardTheme.bg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: DashboardTheme.border),
            ),
            child: Row(
              children: [
                const SizedBox(width: 10),
                Icon(Icons.search_rounded,
                    size: 14,
                    color: DashboardTheme.textTertiary),
                const SizedBox(width: 6),
                Text(
                  'Search...',
                  style: TextStyle(
                    fontSize: 13,
                    color: DashboardTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Notification placeholder
          Icon(Icons.notifications_none_rounded,
              size: 20, color: DashboardTheme.textSecondary),
          const SizedBox(width: 16),

          // User avatar
          Tooltip(
            message: email,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: DashboardTheme.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
