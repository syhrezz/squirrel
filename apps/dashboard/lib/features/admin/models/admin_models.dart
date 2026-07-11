import 'package:intl/intl.dart';

final _idr = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
String _fmt(int n) => _idr.format(n);

// ---------------------------------------------------------------------------
// Organization
// ---------------------------------------------------------------------------

class OrganizationInfo {
  const OrganizationInfo({
    required this.id,
    required this.name,
    required this.slug,
    this.address,
    this.phone,
    this.email,
    this.timezone = 'Asia/Jakarta',
    this.currency = 'IDR',
    this.owner,
    this.createdAt,
  });

  final String id;
  final String name;
  final String slug;
  final String? address;
  final String? phone;
  final String? email;
  final String timezone;
  final String currency;
  final String? owner;
  final DateTime? createdAt;

  String get shortId => id.substring(0, 8).toUpperCase();
  String get formattedCreated => createdAt != null
      ? DateFormat('d MMMM yyyy').format(createdAt!)
      : '—';
}

// ---------------------------------------------------------------------------
// Users
// ---------------------------------------------------------------------------

class UserSummary {
  const UserSummary({
    required this.id,
    required this.email,
    required this.role,
    required this.isActive,
    this.displayName,
    this.lastLogin,
    this.deviceCount = 0,
  });

  final String id;
  final String email;
  final String role;
  final bool isActive;
  final String? displayName;
  final DateTime? lastLogin;
  final int deviceCount;

  String get name => displayName ?? email.split('@').first;
  String get formattedLastLogin => lastLogin != null
      ? DateFormat('d MMM yyyy HH:mm').format(lastLogin!)
      : '—';
  String get roleLabel => switch (role) {
        'administrator' => 'Administrator',
        'operator' => 'Operator',
        _ => role,
      };
}

// ---------------------------------------------------------------------------
// Devices
// ---------------------------------------------------------------------------

class DeviceSummary {
  const DeviceSummary({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    required this.appVersion,
    required this.createdAt,
    this.lastSyncAt,
    this.pendingQueue = 0,
    this.lastPullTimestamp,
  });

  final String deviceId;
  final String deviceName;
  final String platform;
  final String appVersion;
  final DateTime createdAt;
  final DateTime? lastSyncAt;
  final int pendingQueue;
  final int? lastPullTimestamp;

  String get shortId => deviceId.substring(0, 8).toUpperCase();
  String get formattedLastSeen => lastSyncAt != null
      ? DateFormat('d MMM yyyy HH:mm').format(lastSyncAt!)
      : '—';
  String get formattedCreated =>
      DateFormat('d MMM yyyy').format(createdAt);

  bool get isOnline {
    if (lastSyncAt == null) return false;
    return DateTime.now().difference(lastSyncAt!).inHours < 24;
  }

  String get syncStatus {
    if (pendingQueue > 10) return 'warning';
    if (isOnline) return 'online';
    return 'offline';
  }
}

// ---------------------------------------------------------------------------
// Sync Health
// ---------------------------------------------------------------------------

class SyncSessionSummary {
  const SyncSessionSummary({
    required this.id,
    required this.startedAt,
    required this.status,
    required this.uploadedRecords,
    required this.downloadedRecords,
    required this.failedRecords,
    this.finishedAt,
    this.durationMs,
    this.errorMessage,
  });

  final String id;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final String status;
  final int uploadedRecords;
  final int downloadedRecords;
  final int failedRecords;
  final int? durationMs;
  final String? errorMessage;

  String get formattedDate =>
      DateFormat('d MMM yyyy HH:mm').format(startedAt);
  String get formattedDuration => durationMs != null
      ? '${durationMs}ms'
      : '—';
}

class SyncHealth {
  const SyncHealth({
    required this.totalSessions,
    required this.successfulSessions,
    required this.failedSessions,
    required this.pendingRecords,
    required this.failedRecords,
    required this.avgDurationMs,
    required this.maxDurationMs,
    this.lastSuccessfulSync,
    this.lastFailedSync,
    this.lastError,
    required this.recentSessions,
    required this.dailySyncCounts,
  });

  final int totalSessions;
  final int successfulSessions;
  final int failedSessions;
  final int pendingRecords;
  final int failedRecords;
  final int avgDurationMs;
  final int maxDurationMs;
  final DateTime? lastSuccessfulSync;
  final DateTime? lastFailedSync;
  final String? lastError;
  final List<SyncSessionSummary> recentSessions;
  final List<int> dailySyncCounts; // last 30 days

  double get successRate => totalSessions > 0
      ? successfulSessions / totalSessions * 100
      : 100;
  String get formattedSuccessRate =>
      '${successRate.toStringAsFixed(1)}%';
  String get formattedAvgDuration => '${avgDurationMs}ms';
  String get formattedLastSuccess => lastSuccessfulSync != null
      ? DateFormat('d MMM HH:mm').format(lastSuccessfulSync!)
      : '—';
  String get formattedLastFailed => lastFailedSync != null
      ? DateFormat('d MMM HH:mm').format(lastFailedSync!)
      : '—';
}

// ---------------------------------------------------------------------------
// System Info
// ---------------------------------------------------------------------------

class SystemInfo {
  const SystemInfo({
    required this.dashboardVersion,
    required this.flutterVersion,
    required this.supabaseStatus,
    required this.schemaVersion,
    required this.buildMode,
    required this.organizationId,
  });

  final String dashboardVersion;
  final String flutterVersion;
  final String supabaseStatus;
  final int schemaVersion;
  final String buildMode;
  final String organizationId;
}
