import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/admin/models/admin_models.dart';

abstract class AdministrationRepository {
  Future<OrganizationInfo> getOrganization();
  Future<List<UserSummary>> getUsers();
  Future<List<DeviceSummary>> getDevices();
  Future<SyncHealth> getSyncHealth(String period);
  Future<SystemInfo> getSystemInfo();
}

class SupabaseAdministrationRepository
    implements AdministrationRepository {
  SupabaseAdministrationRepository(this._client, this._orgId);

  final SupabaseClient _client;
  final String _orgId;

  @override
  Future<OrganizationInfo> getOrganization() async {
    try {
      final row = await _client
          .from('organizations')
          .select()
          .eq('id', _orgId)
          .maybeSingle();

      if (row == null) {
        return OrganizationInfo(
          id: _orgId,
          name: 'Warung Mr Squirrel',
          slug: 'warung-mr-squirrel',
          createdAt: DateTime.now(),
        );
      }

      final crTs = row['created_at'];
      DateTime? created;
      if (crTs is int) {
        created = DateTime.fromMillisecondsSinceEpoch(crTs);
      } else if (crTs is String) {
        created = DateTime.tryParse(crTs);
      }

      return OrganizationInfo(
        id: row['id'] as String? ?? _orgId,
        name: row['name'] as String? ?? 'Warung Mr Squirrel',
        slug: row['slug'] as String? ?? 'warung-mr-squirrel',
        createdAt: created,
      );
    } catch (_) {
      return OrganizationInfo(
        id: _orgId,
        name: 'Warung Mr Squirrel',
        slug: 'warung-mr-squirrel',
        createdAt: DateTime.now(),
      );
    }
  }

  @override
  Future<List<UserSummary>> getUsers() async {
    try {
      final rows = await _client
          .from('organization_members')
          .select('user_id, role, created_at')
          .eq('organization_id', _orgId);

      return (rows as List).map((r) {
        final ts = r['created_at'];
        DateTime? dt;
        if (ts is int) dt = DateTime.fromMillisecondsSinceEpoch(ts);
        else if (ts is String) dt = DateTime.tryParse(ts);

        return UserSummary(
          id: r['user_id'] as String,
          email: '${r['user_id'].toString().substring(0, 8)}@user',
          role: r['role'] as String? ?? 'operator',
          isActive: true,
          lastLogin: dt,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<DeviceSummary>> getDevices() async {
    try {
      final rows = await _client
          .from('device_info')
          .select('device_id, device_name, platform, app_version, created_at, last_sync_at, last_pull_timestamp')
          .eq('organization_id', _orgId)
          .order('last_sync_at', ascending: false);

      return (rows as List).map((r) {
        int? parseTs(dynamic v) {
          if (v is int) return v;
          if (v is String) return int.tryParse(v);
          return null;
        }

        final crTs = parseTs(r['created_at']) ?? DateTime.now().millisecondsSinceEpoch;
        final syncTs = parseTs(r['last_sync_at']);

        return DeviceSummary(
          deviceId: r['device_id'] as String,
          deviceName: r['device_name'] as String? ?? 'Unknown Device',
          platform: r['platform'] as String? ?? 'android',
          appVersion: r['app_version'] as String? ?? '—',
          createdAt: DateTime.fromMillisecondsSinceEpoch(crTs),
          lastSyncAt: syncTs != null
              ? DateTime.fromMillisecondsSinceEpoch(syncTs)
              : null,
          lastPullTimestamp: parseTs(r['last_pull_timestamp']),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<SyncHealth> getSyncHealth(String period) async {
    try {
      final now = DateTime.now();
      final since = switch (period) {
        '7d' => DateTime(now.year, now.month, now.day - 7).millisecondsSinceEpoch,
        '30d' => DateTime(now.year, now.month, now.day - 30).millisecondsSinceEpoch,
        _ => DateTime(now.year, now.month, now.day).millisecondsSinceEpoch,
      };

      final logRows = await _client
          .from('sync_log')
          .select()
          .gte('started_at', since)
          .order('started_at', ascending: false);

      final logs = logRows as List;
      final successful = logs.where((l) => l['status'] == 'success').length;
      final failed = logs.where((l) => l['status'] == 'failed').length;

      final durations = logs
          .where((l) => l['duration_ms'] != null)
          .map((l) => l['duration_ms'] as int)
          .toList();
      final avgDur = durations.isEmpty ? 0 : durations.fold(0, (s, d) => s + d) ~/ durations.length;
      final maxDur = durations.isEmpty ? 0 : durations.fold(0, (a, b) => a > b ? a : b);

      DateTime? lastSuccess;
      DateTime? lastFailed;
      String? lastError;
      for (final l in logs) {
        final ts = l['started_at'] as int? ?? 0;
        final dt = DateTime.fromMillisecondsSinceEpoch(ts);
        if (l['status'] == 'success' && lastSuccess == null) lastSuccess = dt;
        if (l['status'] == 'failed' && lastFailed == null) {
          lastFailed = dt;
          lastError = l['error_message'] as String?;
        }
      }

      // Daily counts
      final dayCounts = List.filled(30, 0);
      for (final l in logs) {
        final ts = l['started_at'] as int? ?? 0;
        final dt = DateTime.fromMillisecondsSinceEpoch(ts);
        final daysAgo = now.difference(dt).inDays;
        if (daysAgo >= 0 && daysAgo < 30) {
          dayCounts[29 - daysAgo]++;
        }
      }

      // Queue stats from all devices
      final devices = await getDevices();
      final pendingTotal = devices.fold(0, (s, d) => s + d.pendingQueue);

      final sessions = logs.take(20).map((l) {
        final ts = l['started_at'] as int? ?? 0;
        final finTs = l['finished_at'] as int?;
        return SyncSessionSummary(
          id: l['id'] as String,
          startedAt: DateTime.fromMillisecondsSinceEpoch(ts),
          finishedAt: finTs != null
              ? DateTime.fromMillisecondsSinceEpoch(finTs)
              : null,
          status: l['status'] as String? ?? 'unknown',
          uploadedRecords: l['uploaded_records'] as int? ?? 0,
          downloadedRecords: l['downloaded_records'] as int? ?? 0,
          failedRecords: l['failed_records'] as int? ?? 0,
          durationMs: l['duration_ms'] as int?,
          errorMessage: l['error_message'] as String?,
        );
      }).toList();

      return SyncHealth(
        totalSessions: logs.length,
        successfulSessions: successful,
        failedSessions: failed,
        pendingRecords: pendingTotal,
        failedRecords: 0,
        avgDurationMs: avgDur,
        maxDurationMs: maxDur,
        lastSuccessfulSync: lastSuccess,
        lastFailedSync: lastFailed,
        lastError: lastError,
        recentSessions: sessions,
        dailySyncCounts: dayCounts,
      );
    } catch (_) {
      return const SyncHealth(
        totalSessions: 0,
        successfulSessions: 0,
        failedSessions: 0,
        pendingRecords: 0,
        failedRecords: 0,
        avgDurationMs: 0,
        maxDurationMs: 0,
        recentSessions: [],
        dailySyncCounts: [],
      );
    }
  }

  @override
  Future<SystemInfo> getSystemInfo() async {
    return SystemInfo(
      dashboardVersion: '1.0.0',
      flutterVersion: '3.44.5',
      supabaseStatus: 'Connected',
      schemaVersion: 7,
      buildMode: 'Release',
      organizationId: _orgId,
    );
  }
}
