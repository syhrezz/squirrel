import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/database/app_database.dart';
import 'core/database/seed_data_service.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/sync/providers/sync_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Insert sample data on first launch (no-op if data already exists)
  final db = AppDatabase();
  await SeedDataService(db).seedIfEmpty();
  await db.close();

  runApp(
    const ProviderScope(
      child: MrSquirrelApp(),
    ),
  );
}

class MrSquirrelApp extends ConsumerStatefulWidget {
  const MrSquirrelApp({super.key});

  @override
  ConsumerState<MrSquirrelApp> createState() => _MrSquirrelAppState();
}

class _MrSquirrelAppState extends ConsumerState<MrSquirrelApp> {
  @override
  void initState() {
    super.initState();
    // Start the sync manager after first frame so providers are ready.
    // The manager triggers an initial sync after a 3-second delay,
    // then runs a periodic sync every 30 minutes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncManagerProvider).start();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Mr Squirrel',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
