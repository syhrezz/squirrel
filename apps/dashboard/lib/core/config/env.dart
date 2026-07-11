/// Supabase credentials for the MR SQUIRREL Web Dashboard.
/// Read from --dart-define flags. Fallbacks match the Android app.
class AppEnv {
  AppEnv._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://yjhlhscecotqyeviwzxn.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
        '.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlqaGxoc2NlY290cXlldml3enhuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM2NTkzMTAsImV4cCI6MjA5OTIzNTMxMH0'
        '.4F3A0v2bK_WB4HEeqc-OlBQa44W7plZ4odQHM1yHRCc',
  );

  static const String organizationId = String.fromEnvironment(
    'ORG_ID',
    defaultValue: '00000000-0000-0000-0000-000000000001',
  );

  static bool get isValid =>
      supabaseUrl.isNotEmpty && supabaseUrl.startsWith('https://');
}
