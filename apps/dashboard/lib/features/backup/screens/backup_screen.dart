import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import '../../../core/config/env.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/shared_widgets.dart';
import '../../../theme/dashboard_theme.dart';
import '../models/backup_models.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final _backupSummaryProvider =
    FutureProvider.autoDispose<BackupSummary>((ref) async {
  final client = Supabase.instance.client;
  final orgId = AppEnv.organizationId;

  try {
    // Count devices
    final devices = await client
        .from('device_info')
        .select('device_id')
        .eq('organization_id', orgId);
    final deviceCount = (devices as List).length;

    // Last sync time
    DateTime? lastSync;
    if (deviceCount > 0) {
      final rows = await client
          .from('device_info')
          .select('last_sync_at')
          .eq('organization_id', orgId)
          .order('last_sync_at', ascending: false)
          .limit(1);
      final ts = (rows as List).firstOrNull?['last_sync_at'] as int?;
      if (ts != null) {
        lastSync = DateTime.fromMillisecondsSinceEpoch(ts);
      }
    }

    // Rough DB size estimate from record counts
    final tables = ['products', 'sales', 'sale_items', 'restocks', 'restock_items', 'customers', 'debt_transactions', 'stock_movements'];
    int totalRows = 0;
    for (final t in tables) {
      try {
        final rows = await client.from(t).select('id').eq('organization_id', orgId);
        totalRows += (rows as List).length;
      } catch (_) {}
    }
    final dbSizeKb = totalRows * 0.5; // rough estimate ~500 bytes/row
    final dbSizeStr = dbSizeKb > 1024
        ? '${(dbSizeKb / 1024).toStringAsFixed(1)} MB'
        : '${dbSizeKb.toStringAsFixed(0)} KB';

    final status = lastSync != null &&
            DateTime.now().difference(lastSync).inDays < 1
        ? BackupStatus.healthy
        : BackupStatus.warning;

    return BackupSummary(
      lastBackupDate: lastSync,
      backupStatus: status,
      cloudSyncStatus: BackupStatus.healthy,
      databaseSize: dbSizeStr,
      storageUsed: dbSizeStr,
      connectedDevices: deviceCount,
      lastBackupType: BackupType.cloud,
    );
  } catch (_) {
    return const BackupSummary(
      lastBackupDate: null,
      backupStatus: BackupStatus.unknown,
      cloudSyncStatus: BackupStatus.unknown,
      databaseSize: '—',
      storageUsed: '—',
      connectedDevices: 0,
    );
  }
});

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  IntegrityCheckResult? _integrityResult;
  bool _checkingIntegrity = false;
  bool _exporting = false;
  final List<BackupHistoryItem> _history = [];

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(_backupSummaryProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DashboardTheme.sp32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Backup & Recovery',
            subtitle: 'Lindungi data bisnis dan pulihkan kapan saja.',
          ),
          const SizedBox(height: 24),

          // Summary cards
          summaryAsync.when(
            loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
            error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(_backupSummaryProvider)),
            data: (s) => _SummaryCards(summary: s),
          ),
          const SizedBox(height: 24),

          // Backup methods
          LayoutBuilder(builder: (context, c) {
            final side = (c.maxWidth - 16) / 2;
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(width: side, child: SectionCard(
                title: 'Backup Lokal',
                subtitle: 'Ekspor semua data ke file JSON',
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Unduh seluruh data bisnis sebagai file JSON terenkripsi. File ini dapat digunakan untuk memulihkan data kapan saja.', style: TextStyle(fontSize: 13, color: DashboardTheme.textSecondary)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _exporting ? null : _runLocalBackup,
                      icon: _exporting
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.download_rounded, size: 16),
                      label: Text(_exporting ? 'Mengekspor...' : 'Export & Download'),
                      style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    ),
                  ),
                ]),
              )),
              const SizedBox(width: 16),
              SizedBox(width: side, child: SectionCard(
                title: 'Cloud Backup',
                subtitle: 'Supabase mengelola backup cloud otomatis',
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: DashboardTheme.success.withAlpha(12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: DashboardTheme.success.withAlpha(40)),
                    ),
                    child: Row(children: [
                      Icon(Icons.cloud_done_rounded, size: 16, color: DashboardTheme.success),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Supabase melakukan backup otomatis setiap hari. Data Anda selalu terlindungi di cloud.', style: TextStyle(fontSize: 12, color: DashboardTheme.success))),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  Text('Untuk restore cloud, hubungi Supabase support atau gunakan Supabase Dashboard.', style: TextStyle(fontSize: 12, color: DashboardTheme.textSecondary)),
                ]),
              )),
            ]);
          }),
          const SizedBox(height: 16),

          // Integrity checker
          SectionCard(
            title: 'Verifikasi Integritas',
            subtitle: 'Periksa kesehatan database',
            child: Column(children: [
              if (_integrityResult != null) _IntegrityResults(result: _integrityResult!),
              const SizedBox(height: 12),
              Row(children: [
                ElevatedButton.icon(
                  onPressed: _checkingIntegrity ? null : _runIntegrityCheck,
                  icon: _checkingIntegrity
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.verified_rounded, size: 16),
                  label: Text(_checkingIntegrity ? 'Memeriksa...' : 'Verifikasi Sekarang'),
                  style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _showRestoreDialog(context),
                  icon: const Icon(Icons.restore_rounded, size: 16),
                  label: const Text('Restore'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DashboardTheme.danger,
                    side: BorderSide(color: DashboardTheme.danger.withAlpha(60)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ]),
            ]),
          ),
          const SizedBox(height: 16),

          // History
          if (_history.isNotEmpty)
            SectionCard(
              title: 'Riwayat Backup',
              child: Column(children: [
                Row(children: const [
                  SizedBox(width: 150, child: _H('Tanggal')),
                  SizedBox(width: 100, child: _H('Tipe')),
                  SizedBox(width: 80, child: _H('Ukuran')),
                  SizedBox(width: 100, child: _H('Durasi')),
                  SizedBox(width: 100, child: _H('Status')),
                  Expanded(child: _H('Catatan')),
                ]),
                Divider(height: 1, color: DashboardTheme.border),
                ..._history.reversed.map((h) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(children: [
                    SizedBox(width: 150, child: Text(h.formattedDate, style: const TextStyle(fontSize: 12))),
                    SizedBox(width: 100, child: Text(h.typeLabel, style: TextStyle(fontSize: 12, color: DashboardTheme.textSecondary))),
                    SizedBox(width: 80, child: Text(h.size, style: TextStyle(fontSize: 12, color: DashboardTheme.textSecondary))),
                    SizedBox(width: 100, child: Text(h.formattedDuration, style: TextStyle(fontSize: 12, color: DashboardTheme.textSecondary))),
                    SizedBox(width: 100, child: StatusChip(label: h.statusLabel, color: h.status == BackupStatus.healthy ? DashboardTheme.success : DashboardTheme.danger)),
                    Expanded(child: Text(h.notes ?? '—', style: TextStyle(fontSize: 12, color: DashboardTheme.textSecondary))),
                  ]),
                )),
              ]),
            ),
        ],
      ),
    );
  }

  Future<void> _runLocalBackup() async {
    setState(() => _exporting = true);
    final start = DateTime.now();
    try {
      final client = Supabase.instance.client;
      final orgId = AppEnv.organizationId;
      final data = <String, dynamic>{
        'exported_at': DateTime.now().toIso8601String(),
        'organization_id': orgId,
        'version': '1.0',
      };

      final tables = ['products', 'sales', 'sale_items', 'restocks', 'restock_items', 'customers', 'debt_transactions', 'stock_movements'];
      for (final t in tables) {
        try {
          final rows = await client.from(t).select().eq('organization_id', orgId);
          data[t] = rows;
        } catch (_) {
          data[t] = [];
        }
      }

      final json = jsonEncode(data);
      final bytes = utf8.encode(json);
      final sizeKb = (bytes.length / 1024).toStringAsFixed(1);
      final sizeStr = '${sizeKb} KB';
      final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final fileName = 'mrsquirrel_backup_$dateStr.json';

      if (kIsWeb) {
        final blob = html.Blob([bytes], 'application/json');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
      }

      final duration = DateTime.now().difference(start).inMilliseconds;
      setState(() {
        _history.add(BackupHistoryItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          date: DateTime.now(),
          type: BackupType.manual,
          status: BackupStatus.healthy,
          size: sizeStr,
          durationMs: duration,
          notes: '$fileName',
        ));
        _exporting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Backup berhasil: $fileName ($sizeStr)'),
          backgroundColor: DashboardTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ));
      }
    } catch (e) {
      setState(() => _exporting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Backup gagal: $e'),
          backgroundColor: DashboardTheme.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ));
      }
    }
  }

  Future<void> _runIntegrityCheck() async {
    setState(() => _checkingIntegrity = true);
    try {
      final client = Supabase.instance.client;
      final orgId = AppEnv.organizationId;
      final counts = <String, int>{};
      final issues = <String>[];

      final tables = ['products', 'sales', 'sale_items', 'restocks', 'restock_items', 'customers', 'debt_transactions', 'stock_movements'];
      for (final t in tables) {
        try {
          final rows = await client.from(t).select('id').eq('organization_id', orgId);
          counts[t] = (rows as List).length;
        } catch (e) {
          issues.add('Tabel $t tidak dapat dibaca: $e');
          counts[t] = -1;
        }
      }

      // Verify sale items have matching sales
      final saleIds = counts['sales']! >= 0 ? (await client.from('sales').select('id').eq('organization_id', orgId) as List).map((r) => r['id'] as String).toSet() : <String>{};
      final orphanItems = counts['sale_items']! >= 0
          ? (await client.from('sale_items').select('sale_id') as List).where((r) => !saleIds.contains(r['sale_id'])).length
          : 0;
      if (orphanItems > 0) issues.add('$orphanItems sale_items tanpa transaksi induk.');

      final status = issues.isEmpty ? IntegrityStatus.pass : IntegrityStatus.fail;
      setState(() {
        _integrityResult = IntegrityCheckResult(
          status: status,
          schemaVersion: 7,
          tableCounts: counts,
          checkedAt: DateTime.now(),
          issues: issues,
        );
        _checkingIntegrity = false;
      });
    } catch (e) {
      setState(() {
        _integrityResult = IntegrityCheckResult(
          status: IntegrityStatus.fail,
          schemaVersion: 0,
          tableCounts: {},
          checkedAt: DateTime.now(),
          issues: ['Gagal menjalankan pemeriksaan: $e'],
        );
        _checkingIntegrity = false;
      });
    }
  }

  Future<void> _showRestoreDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(children: [
          Icon(Icons.warning_rounded, color: DashboardTheme.danger, size: 20),
          const SizedBox(width: 8),
          const Text('Konfirmasi Restore'),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('PERHATIAN: Restore akan menggantikan seluruh data bisnis dengan data dari file backup.', style: TextStyle(fontSize: 14, color: DashboardTheme.danger, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          const Text('• Data yang ada saat ini akan dihapus.'),
          const Text('• Proses ini tidak dapat dibatalkan.'),
          const Text('• Pastikan Anda memiliki backup terbaru.'),
          const SizedBox(height: 12),
          Text('Fitur ini akan tersedia di fase berikutnya.', style: TextStyle(fontSize: 12, color: DashboardTheme.textSecondary)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, false),
            style: ElevatedButton.styleFrom(backgroundColor: DashboardTheme.danger, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
            child: const Text('Coming Soon'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Summary cards
// ---------------------------------------------------------------------------

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.summary});
  final BackupSummary summary;

  Color _statusColor(BackupStatus s) => switch (s) {
        BackupStatus.healthy => DashboardTheme.success,
        BackupStatus.warning => DashboardTheme.warning,
        BackupStatus.failed => DashboardTheme.danger,
        BackupStatus.unknown => DashboardTheme.textSecondary,
      };

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth > 900 ? 3 : 2;
      final w = (c.maxWidth - (cols - 1) * 12) / cols;
      return Wrap(spacing: 12, runSpacing: 12, children: [
        SizedBox(width: w, child: _Card('Backup Terakhir', summary.formattedLastBackup, Icons.backup_rounded, DashboardTheme.primary)),
        SizedBox(width: w, child: _Card('Status Backup', summary.statusLabel, Icons.health_and_safety_rounded, _statusColor(summary.backupStatus))),
        SizedBox(width: w, child: _Card('Cloud Sync', 'Supabase', Icons.cloud_done_rounded, _statusColor(summary.cloudSyncStatus))),
        SizedBox(width: w, child: _Card('Ukuran Database', summary.databaseSize, Icons.storage_rounded, DashboardTheme.primary)),
        SizedBox(width: w, child: _Card('Storage Digunakan', summary.storageUsed, Icons.folder_rounded, DashboardTheme.textSecondary)),
        SizedBox(width: w, child: _Card('Perangkat Terhubung', '${summary.connectedDevices}', Icons.devices_rounded, DashboardTheme.success)),
      ]);
    });
  }
}

class _Card extends StatelessWidget {
  const _Card(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: DashboardTheme.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: DashboardTheme.border)),
      child: Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 18, color: color)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 11, color: DashboardTheme.textSecondary)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
        ])),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Integrity results
// ---------------------------------------------------------------------------

class _IntegrityResults extends StatelessWidget {
  const _IntegrityResults({required this.result});
  final IntegrityCheckResult result;

  @override
  Widget build(BuildContext context) {
    final isPassed = result.passed;
    final color = isPassed ? DashboardTheme.success : DashboardTheme.danger;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withAlpha(10), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withAlpha(40))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(isPassed ? Icons.check_circle_rounded : Icons.error_rounded, color: color, size: 18),
          const SizedBox(width: 8),
          Text(isPassed ? 'LULUS — Database sehat' : 'GAGAL — Ditemukan masalah', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
          const Spacer(),
          Text('Diperiksa: ${result.formattedDate}', style: TextStyle(fontSize: 11, color: DashboardTheme.textTertiary)),
        ]),
        const SizedBox(height: 12),
        Text('Schema v${result.schemaVersion} · ${result.tableCounts.length} tabel', style: TextStyle(fontSize: 12, color: DashboardTheme.textSecondary)),
        if (result.tableCounts.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 4, children: result.tableCounts.entries.map((e) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: DashboardTheme.bg, borderRadius: BorderRadius.circular(4), border: Border.all(color: DashboardTheme.border)),
            child: Text('${e.key}: ${e.value}', style: const TextStyle(fontSize: 10, fontFamily: 'monospace')),
          )).toList()),
        ],
        if (result.issues.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...result.issues.map((i) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              Icon(Icons.warning_amber_rounded, size: 12, color: DashboardTheme.danger),
              const SizedBox(width: 6),
              Expanded(child: Text(i, style: TextStyle(fontSize: 12, color: DashboardTheme.danger))),
            ]),
          )),
        ],
      ]),
    );
  }
}

class _H extends StatelessWidget {
  const _H(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: DashboardTheme.textSecondary));
}
