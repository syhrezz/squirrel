/// Single source of truth for all environment configuration.
///
/// Values are read from --dart-define flags at build time.
/// Hardcoded fallbacks are the values already configured for this project.
///
/// Usage:
///   flutter run \
///     --dart-define=SUPABASE_URL=https://xxx.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=eyJ... \
///     --dart-define=ORG_ID=00000000-0000-0000-0000-000000000001
///
/// If no --dart-define is provided, the fallback values below are used.
/// This means the app works in development without any extra flags.
class AppEnv {
  AppEnv._();

  /// Supabase project URL.
  /// Override with: --dart-define=SUPABASE_URL=https://xxx.supabase.co
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://yjhlhscecotqyeviwzxn.supabase.co',
  );

  /// Supabase anon / public key.
  /// Override with: --dart-define=SUPABASE_ANON_KEY=eyJ...
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
        '.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlqaGxoc2NlY290cXlldml3enhuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM2NTkzMTAsImV4cCI6MjA5OTIzNTMxMH0'
        '.4F3A0v2bK_WB4HEeqc-OlBQa44W7plZ4odQHM1yHRCc',
  );

  /// Organization UUID — identifies which warung this device belongs to.
  /// Override with: --dart-define=ORG_ID=00000000-0000-0000-0000-000000000001
  static const String organizationId = String.fromEnvironment(
    'ORG_ID',
    defaultValue: '00000000-0000-0000-0000-000000000001',
  );

  /// Returns true if all required environment values are present and valid.
  static bool get isValid =>
      supabaseUrl.isNotEmpty &&
      supabaseUrl.startsWith('https://') &&
      supabaseAnonKey.isNotEmpty &&
      organizationId.isNotEmpty &&
      organizationId != '00000000-0000-0000-0000-000000000000';
}
