import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/dashboard_theme.dart';
import 'sidebar.dart';
import 'top_bar.dart';

/// The main desktop shell — sidebar + top bar + scrollable content.
/// All authenticated pages are wrapped in this scaffold.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.child,
    required this.title,
    this.breadcrumb,
  });

  final Widget child;
  final String title;
  final String? breadcrumb;

  @override
  Widget build(BuildContext context) {
    final currentPath =
        GoRouterState.of(context).matchedLocation;

    return Scaffold(
      backgroundColor: DashboardTheme.bg,
      body: Row(
        children: [
          // Fixed sidebar
          Sidebar(currentPath: currentPath),

          // Main content area
          Expanded(
            child: Column(
              children: [
                TopBar(title: title, breadcrumb: breadcrumb),
                Expanded(
                  child: child,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
