import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/dashboard_theme.dart';

class NavItem extends StatelessWidget {
  const NavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.path,
    required this.currentPath,
  });

  final IconData icon;
  final String label;
  final String path;
  final String currentPath;

  bool get isActive =>
      currentPath == path || currentPath.startsWith('$path/');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: isActive
            ? DashboardTheme.sidebarActive
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => context.go(path),
          hoverColor: const Color(0xFF1F2937),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isActive
                      ? DashboardTheme.sidebarTextActive
                      : DashboardTheme.sidebarText,
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive
                        ? FontWeight.w500
                        : FontWeight.w400,
                    color: isActive
                        ? DashboardTheme.sidebarTextActive
                        : DashboardTheme.sidebarText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
