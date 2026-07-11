import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/dev_user.dart';
import '../../../shared/providers/database_providers.dart';
import '../../../features/sync/providers/sync_providers.dart';
import '../providers/dev_tools_providers.dart';

/// DEV ONLY — Developer Tools screen.
///
/// Completely hidden in release builds via kDebugMode.
/// Never imported by any production screen or router.
///
/// Sections:
/// - Database Statistics
/// - Seed / Reset
/// - Data Generators
/// - Stress Tests
/// - Debug Info
/// - Data Integrity
/// - Danger Zone
class DevToolsScreen extends ConsumerStatefulWidget {
  const DevToolsScreen({super.key});

  @override
  ConsumerState<DevToolsScreen> createState() => _DevToolsScreenState();
}

class _DevToolsScreenState extends ConsumerState<DevToolsScreen> {
  bool _isRunning = false;
  String? _lastMessage;

  Future<void> _run(String successMsg, Future<void> Function() action) async {
    setState(() {
      _isRunning = true;
      _lastMessage = null;
    });
    try {
      await action();
      ref.invalidate(dbStatsProvider);
      ref.invalidate(integrityCheckProvider);
      setState(() => _lastMessage = successMsg);
    } catch (e) {
      setState(() => _lastMessage = 'Error: $e');
    } finally {
      setState(() => _isRunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(kDebugMode, 'DevToolsScreen must not be used in release builds');

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      appBar: AppBar(
        backgroundColor: Colors.deepOrange[700],
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Row(
          children: [
            Icon(Icons.developer_mode_rounded, size: 20),
            SizedBox(width: 8),
            Text('Developer Tools'),
          ],
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Debug mode warning banner
              _DebugBanner(),
              const SizedBox(height: 16),

              // Status message
              if (_lastMessage != null) ...[
                _StatusMessage(message: _lastMessage!),
                const SizedBox(height: 16),
              ],

              // Database Statistics
              _SectionHeader(title: 'Statistik Database', icon: Icons.bar_chart_rounded),
              const SizedBox(height: 8),
              _DbStatsCard(),
              const SizedBox(height: 20),

              // Seed / Reset
              _SectionHeader(title: 'Data & Reset', icon: Icons.restore_rounded),
              const SizedBox(height: 8),
              _ActionCard(
                title: 'Seed Sample Data',
                subtitle: 'Insert sample data if database is empty',
                icon: Icons.playlist_add_rounded,
                onTap: _isRunning ? null : () => _run(
                  'Sample data seeded.',
                  () => ref.read(devToolsDataServiceProvider).seedSampleData(),
                ),
              ),
              const SizedBox(height: 8),
              _ActionCard(
                title: 'Reset Demo Data',
                subtitle: 'Clear all data then re-seed sample data',
                icon: Icons.refresh_rounded,
                onTap: _isRunning ? null : () => _confirmAndRun(
                  context,
                  title: 'Reset Demo Data?',
                  body: 'Semua data akan dihapus dan diganti dengan data demo.',
                  successMsg: 'Demo data reset.',
                  action: () => ref.read(devToolsDataServiceProvider).resetDemoData(),
                ),
              ),
              const SizedBox(height: 20),

              // Data Generators
              _SectionHeader(title: 'Generate Data', icon: Icons.auto_fix_high_rounded),
              const SizedBox(height: 8),
              ..._buildGenerators(context),
              const SizedBox(height: 20),

              // Stress Tests
              _SectionHeader(title: 'Stress Tests / Edge Cases', icon: Icons.bug_report_rounded),
              const SizedBox(height: 8),
              ..._buildStressTests(context),
              const SizedBox(height: 20),

              // Debug Info
              _SectionHeader(title: 'Debug Info', icon: Icons.info_outline_rounded),
              const SizedBox(height: 8),
              _DebugInfoCard(),
              const SizedBox(height: 20),

              // Data Integrity
              _SectionHeader(title: 'Data Integrity', icon: Icons.verified_rounded),
              const SizedBox(height: 8),
              _IntegrityCard(),
              const SizedBox(height: 20),

              // Sync Queue
              _SectionHeader(title: 'Synchronization', icon: Icons.sync_rounded),
              const SizedBox(height: 8),
              _SyncQueueCard(),
              const SizedBox(height: 20),

              // Danger Zone
              _SectionHeader(
                title: 'Danger Zone',
                icon: Icons.warning_amber_rounded,
                color: Colors.red[700]!,
              ),
              const SizedBox(height: 8),
              _ActionCard(
                title: 'Clear All Data',
                subtitle: 'Permanently deletes all records from all tables',
                icon: Icons.delete_forever_rounded,
                iconColor: Colors.red,
                onTap: _isRunning ? null : () => _confirmAndRun(
                  context,
                  title: 'Clear All Data?',
                  body: 'Semua data akan dihapus permanen. Tindakan ini tidak bisa dibatalkan.',
                  successMsg: 'All data cleared.',
                  action: () => ref.read(devToolsDataServiceProvider).clearAllData(),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
          if (_isRunning)
            Container(
              color: Colors.black.withAlpha(50),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Running...', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildGenerators(BuildContext context) {
    final svc = ref.read(devToolsDataServiceProvider);
    return [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _ChipButton(label: '50 Produk',      onTap: _isRunning ? null : () => _run('50 products generated.', () => svc.generateProducts(50))),
          _ChipButton(label: '100 Produk',     onTap: _isRunning ? null : () => _run('100 products generated.', () => svc.generateProducts(100))),
          _ChipButton(label: '500 Produk',     onTap: _isRunning ? null : () => _run('500 products generated.', () => svc.generateProducts(500))),
          _ChipButton(label: '100 Penjualan',  onTap: _isRunning ? null : () => _run('100 sales generated.', () => svc.generateSales(100))),
          _ChipButton(label: '500 Penjualan',  onTap: _isRunning ? null : () => _run('500 sales generated.', () => svc.generateSales(500))),
          _ChipButton(label: '20 Pelanggan',   onTap: _isRunning ? null : () => _run('20 customers generated.', () => svc.generateCustomers(20))),
          _ChipButton(label: '100 Pelanggan',  onTap: _isRunning ? null : () => _run('100 customers generated.', () => svc.generateCustomers(100))),
          _ChipButton(label: '100 Kasbon',     onTap: _isRunning ? null : () => _run('100 debt transactions generated.', () => svc.generateDebtTransactions(100))),
          _ChipButton(label: '50 Restock',     onTap: _isRunning ? null : () => _run('50 restocks generated.', () => svc.generateRestocks(50))),
        ],
      ),
    ];
  }

  List<Widget> _buildStressTests(BuildContext context) {
    final svc = ref.read(devToolsDataServiceProvider);
    return [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _ChipButton(label: 'Stok Rendah',     onTap: _isRunning ? null : () => _run('Low stock products added.', svc.generateLowStockProducts)),
          _ChipButton(label: 'Stok Kosong',     onTap: _isRunning ? null : () => _run('Zero stock products added.', svc.generateZeroStockProducts)),
          _ChipButton(label: 'Produk Nonaktif', onTap: _isRunning ? null : () => _run('Inactive products added.', svc.generateInactiveProducts)),
          _ChipButton(label: 'Kasbon Panjang',  onTap: _isRunning ? null : () => _run('Large kasbon history added.', svc.generateLargeKasbonHistory)),
          _ChipButton(label: 'Lebih Bayar',     onTap: _isRunning ? null : () => _run('Overpaid customer added.', svc.generateOverpaidCustomers)),
        ],
      ),
    ];
  }

  Future<void> _confirmAndRun(
    BuildContext context, {
    required String title,
    required String body,
    required String successMsg,
    required Future<void> Function() action,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(title.contains('Clear') ? 'Hapus' : 'Lanjutkan',
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _run(successMsg, action);
    }
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _DebugBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.deepOrange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.deepOrange[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.deepOrange[700], size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'DEBUG MODE — This module is hidden in release builds',
              style: TextStyle(fontSize: 12, color: Colors.deepOrange[800]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon, this.color});
  final String title;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      children: [
        Icon(icon, size: 16, color: effectiveColor),
        const SizedBox(width: 6),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: effectiveColor,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final isError = message.startsWith('Error');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isError ? Colors.red[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isError ? Colors.red[200]! : Colors.green[200]!,
        ),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 13,
          color: isError ? Colors.red[800] : Colors.green[800],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: onTap != null ? 1 : 0,
      shadowColor: Colors.black.withAlpha(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 22, color: onTap != null
                  ? (iconColor ?? Theme.of(context).colorScheme.primary)
                  : Colors.grey),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChipButton extends StatelessWidget {
  const _ChipButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 13)),
      onPressed: onTap,
      backgroundColor: onTap != null
          ? Theme.of(context).colorScheme.primaryContainer
          : Colors.grey[200],
    );
  }
}

class _DbStatsCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dbStatsProvider);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(16),
      child: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.red)),
        data: (stats) => Column(
          children: [
            _StatRow('Produk',             '${stats.products}'),
            _StatRow('Produk Aktif',       '${stats.activeProducts}'),
            _StatRow('Pelanggan',          '${stats.customers}'),
            _StatRow('Pelanggan Berhutang','${stats.outstandingCustomers}'),
            _StatRow('Penjualan',          '${stats.sales}'),
            _StatRow('Item Penjualan',     '${stats.saleItems}'),
            _StatRow('Restock',            '${stats.restocks}'),
            _StatRow('Item Restock',       '${stats.restockItems}'),
            _StatRow('Transaksi Kasbon',   '${stats.debtTransactions}'),
            _StatRow('Stock Movements',    '${stats.stockMovements}'),
            const Divider(height: 16),
            _StatRow('Schema Version',     'v${stats.schemaVersion}'),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _DebugInfoCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(appDatabaseProvider);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _StatRow('Device ID',        kDevUser.deviceId),
          _StatRow('Current User',     '${kDevUser.name} (${kDevUser.role.name})'),
          _StatRow('Schema Version',   'v${db.schemaVersion}'),
          _StatRow('Last Sync',        'N/A (sync belum diimplementasi)'),
          _StatRow('Sync Queue',       'N/A'),
          _StatRow('App Version',      '1.0.0+1'),
          _StatRow('Build Mode',       kDebugMode ? 'DEBUG' : 'RELEASE'),
        ],
      ),
    );
  }
}

class _IntegrityCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultAsync = ref.watch(integrityCheckProvider);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          resultAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.red)),
            data: (result) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      result.passed ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      color: result.passed ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      result.passed ? 'PASS — No issues found' : 'FAIL — ${result.issues.length} issue(s)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: result.passed ? Colors.green[700] : Colors.red[700],
                      ),
                    ),
                  ],
                ),
                if (!result.passed) ...[
                  const SizedBox(height: 8),
                  ...result.issues.map((issue) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '• $issue',
                      style: TextStyle(fontSize: 12, color: Colors.red[700]),
                    ),
                  )),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => ref.invalidate(integrityCheckProvider),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Run Again'),
          ),
        ],
      ),
    );
  }
}

/// DEV ONLY — Sync queue status card.
class _SyncQueueCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(syncQueueSnapshotProvider);
    final logsAsync = ref.watch(recentSyncLogsProvider);
    final pendingAsync = ref.watch(pendingSyncQueueProvider);
    final failedAsync = ref.watch(failedSyncQueueProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(12),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Queue snapshot
          snapshotAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (e, _) =>
                Text('Error: $e', style: const TextStyle(color: Colors.red)),
            data: (snap) => Column(
              children: [
                _StatRow('Pending', '${snap.pending}'),
                _StatRow('Syncing', '${snap.syncing}'),
                _StatRow('Failed', '${snap.failed}'),
                _StatRow('Total', '${snap.total}'),
              ],
            ),
          ),
          const Divider(height: 20),

          // Pending entries
          const Text('Pending Queue',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          pendingAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('Error: $e'),
            data: (entries) => entries.isEmpty
                ? Text('Empty',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]))
                : Column(
                    children: entries
                        .take(5)
                        .map((e) => Text(
                               '${e.targetTable} / ${e.recordId.substring(0, 8)}… [${e.operation}]',
                              style: const TextStyle(fontSize: 11),
                            ))
                        .toList(),
                  ),
          ),
          const Divider(height: 20),

          // Failed entries
          const Text('Failed Queue',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          failedAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('Error: $e'),
            data: (entries) => entries.isEmpty
                ? Text('Empty',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]))
                : Column(
                    children: entries
                        .take(5)
                        .map((e) => Text(
                               '${e.targetTable} retry #${e.retryCount}: ${e.lastError ?? "unknown"}',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.red[700]),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ))
                        .toList(),
                  ),
          ),
          const Divider(height: 20),

          // Recent sync logs
          const Text('Recent Sync Log',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          logsAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('Error: $e'),
            data: (logs) => logs.isEmpty
                ? Text('No sync sessions yet.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]))
                : Column(
                    children: logs
                        .take(5)
                        .map((l) {
                          final dt = DateTime.fromMillisecondsSinceEpoch(
                              l.startedAt);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Icon(
                                  l.status == 'success'
                                      ? Icons.check_circle_rounded
                                      : Icons.cancel_rounded,
                                  size: 14,
                                  color: l.status == 'success'
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')} — '
                                    '↑${l.uploadedRecords} ↓${l.downloadedRecords} '
                                    '${l.durationMs != null ? "(${l.durationMs}ms)" : ""}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                          );
                        })
                        .toList(),
                  ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              ref.invalidate(syncQueueSnapshotProvider);
              ref.invalidate(recentSyncLogsProvider);
              ref.invalidate(pendingSyncQueueProvider);
              ref.invalidate(failedSyncQueueProvider);
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}
