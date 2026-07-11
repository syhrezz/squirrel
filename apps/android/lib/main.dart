import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/env.dart';
import 'core/database/app_database.dart';
import 'core/database/seed_data_service.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/sync/data/repositories/sync_repository.dart';
import 'features/sync/providers/sync_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fail fast in debug builds if environment is not configured.
  if (!AppEnv.isValid) {
    if (kDebugMode) {
      debugPrint(
        '[AppEnv] WARNING: Supabase credentials are missing or invalid.\n'
        '  SUPABASE_URL   = ${AppEnv.supabaseUrl}\n'
        '  ORG_ID         = ${AppEnv.organizationId}\n'
        'Sync will be disabled. Pass credentials via --dart-define.',
      );
    }
  }

  // Initialise Supabase once before runApp().
  await Supabase.initialize(
    url: AppEnv.supabaseUrl,
    anonKey: AppEnv.supabaseAnonKey, // ignore: deprecated_member_use
  );

  // Scenario 4: Crash recovery.
  // If the app was killed while records were in 'syncing' state,
  // reset them back to 'pending' so they are retried on next sync.
  // This runs synchronously before the UI starts — no race condition.
  final db = AppDatabase();
  final syncRepo = DriftSyncRepository(db);
  await syncRepo.resetSyncingToPending();

  // Insert sample data on first launch (no-op if data already exists).
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
