import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/dashboard_theme.dart';
import '../widgets/nav_item.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key, required this.currentPath});
  final String currentPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: DashboardTheme.sidebarWidth,
      color: DashboardTheme.sidebarBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: DashboardTheme.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.storefront_rounded,
                      size: 16, color: Colors.white),
                ),
                const SizedBox(width: 10),
                const Text(
                  'MR SQUIRREL',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                NavItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Overview',
                  path: '/overview',
                  currentPath: currentPath,
                ),
                NavItem(
                  icon: Icons.inventory_2_rounded,
                  label: 'Products',
                  path: '/products',
                  currentPath: currentPath,
                ),
                NavItem(
                  icon: Icons.receipt_long_rounded,
                  label: 'Sales',
                  path: '/sales',
                  currentPath: currentPath,
                ),
                NavItem(
                  icon: Icons.shopping_bag_rounded,
                  label: 'Restocks',
                  path: '/restocks',
                  currentPath: currentPath,
                ),
                NavItem(
                  icon: Icons.people_rounded,
                  label: 'Customers',
                  path: '/customers',
                  currentPath: currentPath,
                ),
                NavItem(
                  icon: Icons.analytics_rounded,
                  label: 'Analytics',
                  path: '/analytics',
                  currentPath: currentPath,
                ),
                NavItem(
                  icon: Icons.download_rounded,
                  label: 'Exports',
                  path: '/exports',
                  currentPath: currentPath,
                ),
                NavItem(
                  icon: Icons.backup_rounded,
                  label: 'Backup',
                  path: '/backup',
                  currentPath: currentPath,
                ),
                const Divider(
                    color: Color(0xFF374151), height: 24, thickness: 1),
                NavItem(
                  icon: Icons.admin_panel_settings_rounded,
                  label: 'Admin',
                  path: '/admin',
                  currentPath: currentPath,
                ),
                NavItem(
                  icon: Icons.manage_accounts_rounded,
                  label: 'Users',
                  path: '/users',
                  currentPath: currentPath,
                ),
                NavItem(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  path: '/settings',
                  currentPath: currentPath,
                ),
              ],
            ),
          ),

          // Organization + logout footer
          const Divider(color: Color(0xFF374151), height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Warung Mr Squirrel',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => context.go('/login'),
                    icon: const Icon(Icons.logout_rounded,
                        size: 14, color: Color(0xFF9CA3AF)),
                    label: const Text(
                      'Logout',
                      style: TextStyle(
                          fontSize: 13, color: Color(0xFF9CA3AF)),
                    ),
                    style: TextButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
