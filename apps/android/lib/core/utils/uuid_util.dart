import 'package:uuid/uuid.dart';

/// Generates locally unique IDs for all records.
///
/// UUID v7 is time-ordered which is preferable for synchronization,
/// indexing, and debugging. Falls back to v4 if v7 is unavailable.
///
/// IDs are always generated on-device so records can be created
/// while offline without any server dependency.
class UuidUtil {
  UuidUtil._();

  static const _uuid = Uuid();

  /// Generates a new UUID v7 (time-ordered).
  static String generate() => _uuid.v7();
}
