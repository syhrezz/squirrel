library;

/// Temporary development user.
///
/// This constant replaces authentication during the Android MVP phase.
/// It is referenced in a single place so it can be swapped out cleanly
/// when real authentication is implemented.
///
/// DO NOT use this in any production auth flow.

enum UserRole { operator, administrator }

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.role,
    required this.deviceId,
  });

  final String id;
  final String name;
  final UserRole role;
  final String deviceId;
}

/// The hardcoded development user used across all Phase 1–5 features.
const kDevUser = AppUser(
  id: 'dev-user-001',
  name: 'Dev',
  role: UserRole.administrator,
  deviceId: 'dev-device-001',
);
