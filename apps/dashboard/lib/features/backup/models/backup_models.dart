import 'package:intl/intl.dart';

enum BackupType { manual, automatic, cloud }
enum BackupStatus { healthy, warning, failed, unknown }
enum IntegrityStatus { pass, fail, checking, notRun }

class BackupSummary {
  const BackupSummary({
    required this.lastBackupDate,
    required this.backupStatus,
    required this.cloudSyncStatus,
    required this.databaseSize,
    required this.storageUsed,
    required this.connectedDevices,
    this.lastBackupType,
  });

  final DateTime? lastBackupDate;
  final BackupStatus backupStatus;
  final BackupStatus cloudSyncStatus;
  final String databaseSize;
  final String storageUsed;
  final int connectedDevices;
  final BackupType? lastBackupType;

  String get formattedLastBackup => lastBackupDate != null
      ? DateFormat('d MMM yyyy HH:mm').format(lastBackupDate!)
      : 'Belum pernah';

  String get statusLabel => switch (backupStatus) {
        BackupStatus.healthy => 'Sehat',
        BackupStatus.warning => 'Peringatan',
        BackupStatus.failed => 'Gagal',
        BackupStatus.unknown => 'Tidak Diketahui',
      };
}

class BackupHistoryItem {
  const BackupHistoryItem({
    required this.id,
    required this.date,
    required this.type,
    required this.status,
    required this.size,
    required this.durationMs,
    this.notes,
  });

  final String id;
  final DateTime date;
  final BackupType type;
  final BackupStatus status;
  final String size;
  final int durationMs;
  final String? notes;

  String get formattedDate =>
      DateFormat('d MMM yyyy HH:mm').format(date);
  String get formattedDuration => '${durationMs}ms';
  String get typeLabel => switch (type) {
        BackupType.manual => 'Manual',
        BackupType.automatic => 'Otomatis',
        BackupType.cloud => 'Cloud',
      };
  String get statusLabel => switch (status) {
        BackupStatus.healthy => 'Berhasil',
        BackupStatus.warning => 'Peringatan',
        BackupStatus.failed => 'Gagal',
        BackupStatus.unknown => 'Tidak Diketahui',
      };
}

class IntegrityCheckResult {
  const IntegrityCheckResult({
    required this.status,
    required this.schemaVersion,
    required this.tableCounts,
    required this.checkedAt,
    this.issues = const [],
  });

  final IntegrityStatus status;
  final int schemaVersion;
  final Map<String, int> tableCounts;
  final DateTime checkedAt;
  final List<String> issues;

  bool get passed => status == IntegrityStatus.pass;
  String get formattedDate =>
      DateFormat('d MMM yyyy HH:mm').format(checkedAt);
}
