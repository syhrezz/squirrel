import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/env.dart';
import 'router/app_router.dart';
import 'theme/dashboard_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppEnv.supabaseUrl,
    anonKey: AppEnv.supabaseAnonKey, // ignore: deprecated_member_use
  );

  runApp(const ProviderScope(child: DashboardApp()));
}

class DashboardApp extends ConsumerWidget {
  const DashboardApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = buildRouter(ref);
    return MaterialApp.router(
      title: 'MR SQUIRREL Dashboard',
      debugShowCheckedModeBanner: false,
      theme: DashboardTheme.light,
      routerConfig: router,
    );
  }
}
