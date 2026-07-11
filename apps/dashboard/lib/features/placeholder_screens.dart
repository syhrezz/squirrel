import 'package:flutter/material.dart';
import '../../../shared/widgets/shared_widgets.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../theme/dashboard_theme.dart';

/// Reusable placeholder screen for features not yet built.
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.description,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String description;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DashboardTheme.sp32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(title: title, subtitle: subtitle),
          const SizedBox(height: 24),
          SectionCard(
            child: EmptyState(
              title: 'Coming in a future phase',
              description: description,
              icon: icon,
            ),
          ),
        ],
      ),
    );
  }
}

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});
  @override
  Widget build(BuildContext context) => const _PlaceholderScreen(
        title: 'Products',
        subtitle: 'Manage your product catalog.',
        icon: Icons.inventory_2_rounded,
        description:
            'Product management — create, edit, and deactivate products. '
            'Configure selling options and unit conversions. '
            'Coming in Phase 10.',
      );
}

class SalesScreen extends StatelessWidget {
  const SalesScreen({super.key});
  @override
  Widget build(BuildContext context) => const _PlaceholderScreen(
        title: 'Sales',
        subtitle: 'View all sales transactions.',
        icon: Icons.receipt_long_rounded,
        description:
            'Sales history, transaction details, and revenue analytics. '
            'Coming in Phase 10.',
      );
}

class RestocksScreen extends StatelessWidget {
  const RestocksScreen({super.key});
  @override
  Widget build(BuildContext context) => const _PlaceholderScreen(
        title: 'Restocks',
        subtitle: 'View all restock trips.',
        icon: Icons.shopping_bag_rounded,
        description:
            'Restock history, purchase analysis, and inventory tracking. '
            'Coming in Phase 10.',
      );
}

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});
  @override
  Widget build(BuildContext context) => const _PlaceholderScreen(
        title: 'Customers',
        subtitle: 'Manage customer accounts and kasbon.',
        icon: Icons.people_rounded,
        description:
            'Customer profiles, kasbon balances, and transaction history. '
            'Coming in Phase 10.',
      );
}

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});
  @override
  Widget build(BuildContext context) => const _PlaceholderScreen(
        title: 'Users',
        subtitle: 'Manage dashboard administrator accounts.',
        icon: Icons.manage_accounts_rounded,
        description:
            'Invite administrators, manage roles and permissions. '
            'Coming in Phase 11.',
      );
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => const _PlaceholderScreen(
        title: 'Settings',
        subtitle: 'Configure your organization.',
        icon: Icons.settings_rounded,
        description:
            'Organization settings, Supabase connection, sync configuration. '
            'Coming in Phase 11.',
      );
}
