/// Supabase connection configuration.
///
/// Populated from environment/build config at app startup.
/// Keep actual values out of version control — use a secrets manager or
/// a gitignored `lib/core/config/env.dart` that is not committed.
class SupabaseConfig {
  const SupabaseConfig({
    required this.url,
    required this.anonKey,
    required this.organizationId,
  });

  final String url;
  final String anonKey;

  /// The organization this device belongs to.
  /// For the family shop this is always the single default organization.
  final String organizationId;

  /// Returns true if the config looks usable.
  /// Both url and anonKey must be non-empty and url must start with https.
  bool get isConfigured =>
      url.isNotEmpty &&
      anonKey.isNotEmpty &&
      url.startsWith('https://') &&
      organizationId.isNotEmpty;
}
