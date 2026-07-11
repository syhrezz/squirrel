import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/shared_widgets.dart';
import '../../../theme/dashboard_theme.dart';
import '../providers/admin_providers.dart';

class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DashboardTheme.sp32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.go('/admin')),
            const SizedBox(width: 8),
            const Expanded(child: PageHeader(title: 'Pengguna', subtitle: 'Anggota organisasi yang memiliki akses dashboard.')),
            OutlinedButton.icon(
              onPressed: () => _showComingSoon(context, 'Invite User'),
              icon: const Icon(Icons.person_add_rounded, size: 14),
              label: const Text('Invite User'),
            ),
          ]),
          const SizedBox(height: 24),
          SectionCard(
            title: 'Anggota',
            subtitle: 'Administrator dan Operator',
            child: usersAsync.when(
              loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
              error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(usersProvider)),
              data: (users) {
                if (users.isEmpty) {
                  return const EmptyState(title: 'Tidak ada pengguna', description: 'Undang anggota untuk memberi akses dashboard.', icon: Icons.people_rounded);
                }
                return Column(children: [
                  // Header
                  Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
                    const Expanded(child: _H('Nama')),
                    const Expanded(child: _H('Email')),
                    const SizedBox(width: 120, child: _H('Role')),
                    const SizedBox(width: 100, child: _H('Status')),
                    const SizedBox(width: 150, child: _H('Terakhir Login')),
                    const SizedBox(width: 80, child: _H('Perangkat')),
                  ])),
                  Divider(height: 1, color: DashboardTheme.border),
                  ...users.map((u) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(children: [
                      Expanded(child: Text(u.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                      Expanded(child: Text(u.email, style: TextStyle(fontSize: 12, color: DashboardTheme.textSecondary))),
                      SizedBox(width: 120, child: StatusChip(label: u.roleLabel, color: u.role == 'administrator' ? DashboardTheme.primary : DashboardTheme.success)),
                      SizedBox(width: 100, child: StatusChip(label: u.isActive ? 'Aktif' : 'Nonaktif', color: u.isActive ? DashboardTheme.success : DashboardTheme.textSecondary)),
                      SizedBox(width: 150, child: Text(u.formattedLastLogin, style: TextStyle(fontSize: 12, color: DashboardTheme.textSecondary))),
                      SizedBox(width: 80, child: Text('${u.deviceCount}', style: const TextStyle(fontSize: 13))),
                    ]),
                  )),
                ]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AdminDevicesScreen extends ConsumerWidget {
  const AdminDevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(devicesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DashboardTheme.sp32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.go('/admin')),
            const SizedBox(width: 8),
            const Expanded(child: PageHeader(title: 'Perangkat', subtitle: 'Semua perangkat Android yang terdaftar.')),
            OutlinedButton.icon(onPressed: () => ref.invalidate(devicesProvider), icon: const Icon(Icons.refresh_rounded, size: 14), label: const Text('Refresh')),
          ]),
          const SizedBox(height: 24),
          SectionCard(
            title: 'Perangkat Terdaftar',
            child: devicesAsync.when(
              loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
              error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(devicesProvider)),
              data: (devices) {
                if (devices.isEmpty) {
                  return const EmptyState(title: 'Tidak ada perangkat', description: 'Belum ada perangkat Android yang mensinkronisasi data.', icon: Icons.devices_rounded);
                }
                return Column(children: [
                  Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
                    Container(width: 12, margin: const EdgeInsets.only(right: 12)),
                    const Expanded(child: _H('Nama Perangkat')),
                    const SizedBox(width: 80, child: _H('Platform')),
                    const SizedBox(width: 80, child: _H('Versi')),
                    const SizedBox(width: 150, child: _H('Terakhir Sync')),
                    const SizedBox(width: 100, child: _H('Antrian')),
                    const SizedBox(width: 100, child: _H('Status')),
                  ])),
                  Divider(height: 1, color: DashboardTheme.border),
                  ...devices.map((d) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(children: [
                      Container(
                        width: 8, height: 8,
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: d.syncStatus == 'online' ? DashboardTheme.success : d.syncStatus == 'warning' ? DashboardTheme.warning : DashboardTheme.textTertiary,
                        ),
                      ),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(d.deviceName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        Text(d.shortId, style: TextStyle(fontSize: 10, color: DashboardTheme.textTertiary, fontFamily: 'monospace')),
                      ])),
                      SizedBox(width: 80, child: Text(d.platform, style: TextStyle(fontSize: 12, color: DashboardTheme.textSecondary))),
                      SizedBox(width: 80, child: Text(d.appVersion, style: TextStyle(fontSize: 12, color: DashboardTheme.textSecondary))),
                      SizedBox(width: 150, child: Text(d.formattedLastSeen, style: TextStyle(fontSize: 12, color: DashboardTheme.textSecondary))),
                      SizedBox(width: 100, child: Text(d.pendingQueue > 0 ? '${d.pendingQueue} pending' : 'Clear', style: TextStyle(fontSize: 12, color: d.pendingQueue > 0 ? DashboardTheme.warning : DashboardTheme.success))),
                      SizedBox(width: 100, child: StatusChip(
                        label: d.syncStatus == 'online' ? 'Online' : d.syncStatus == 'warning' ? 'Warning' : 'Offline',
                        color: d.syncStatus == 'online' ? DashboardTheme.success : d.syncStatus == 'warning' ? DashboardTheme.warning : DashboardTheme.textTertiary,
                      )),
                    ]),
                  )),
                ]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AdminSyncScreen extends ConsumerWidget {
  const AdminSyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncAsync = ref.watch(syncHealthProvider);
    final period = ref.watch(syncHealthPeriodProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DashboardTheme.sp32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.go('/admin')),
            const SizedBox(width: 8),
            const Expanded(child: PageHeader(title: 'Sync Health', subtitle: 'Kesehatan sinkronisasi antara Android dan Supabase.')),
            // Period picker
            ...[('today', 'Hari Ini'), ('7d', '7 Hari'), ('30d', '30 Hari')].map((p) => Padding(
              padding: const EdgeInsets.only(left: 4),
              child: GestureDetector(
                onTap: () => ref.read(syncHealthPeriodProvider.notifier).state = p.$1,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: period == p.$1 ? DashboardTheme.primary : DashboardTheme.bg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: period == p.$1 ? DashboardTheme.primary : DashboardTheme.border),
                  ),
                  child: Text(p.$2, style: TextStyle(fontSize: 12, color: period == p.$1 ? Colors.white : DashboardTheme.textSecondary, fontWeight: FontWeight.w500)),
                ),
              ),
            )),
          ]),
          const SizedBox(height: 24),

          syncAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(syncHealthProvider)),
            data: (s) => Column(children: [
              // KPI cards
              LayoutBuilder(builder: (context, c) {
                final cols = c.maxWidth > 900 ? 4 : 2;
                final w = (c.maxWidth - (cols - 1) * 12) / cols;
                return Wrap(spacing: 12, runSpacing: 12, children: [
                  SizedBox(width: w, child: _KpiCard('Success Rate', s.formattedSuccessRate, color: s.successRate < 80 ? DashboardTheme.danger : DashboardTheme.success)),
                  SizedBox(width: w, child: _KpiCard('Total Sesi', '${s.totalSessions}', color: DashboardTheme.primary)),
                  SizedBox(width: w, child: _KpiCard('Sesi Berhasil', '${s.successfulSessions}', color: DashboardTheme.success)),
                  SizedBox(width: w, child: _KpiCard('Sesi Gagal', '${s.failedSessions}', color: s.failedSessions > 0 ? DashboardTheme.danger : DashboardTheme.textSecondary)),
                  SizedBox(width: w, child: _KpiCard('Avg Duration', s.formattedAvgDuration, color: DashboardTheme.primary)),
                  SizedBox(width: w, child: _KpiCard('Last Success', s.formattedLastSuccess, color: DashboardTheme.success)),
                  SizedBox(width: w, child: _KpiCard('Last Failed', s.formattedLastFailed, color: s.failedSessions > 0 ? DashboardTheme.danger : DashboardTheme.textSecondary)),
                  SizedBox(width: w, child: _KpiCard('Pending Records', '${s.pendingRecords}', color: s.pendingRecords > 0 ? DashboardTheme.warning : DashboardTheme.success)),
                ]);
              }),
              const SizedBox(height: 16),

              // Recent sessions table
              SectionCard(
                title: 'Sesi Sync Terakhir',
                child: s.recentSessions.isEmpty
                    ? const EmptyState(title: 'Belum ada sesi', description: 'Belum ada log sinkronisasi.', icon: Icons.sync_rounded)
                    : Column(children: [
                        Row(children: const [
                          Expanded(child: _H('Waktu')),
                          SizedBox(width: 100, child: _H('Durasi')),
                          SizedBox(width: 80, child: _H('Upload')),
                          SizedBox(width: 80, child: _H('Download')),
                          SizedBox(width: 100, child: _H('Status')),
                        ]),
                        Divider(height: 1, color: DashboardTheme.border),
                        ...s.recentSessions.map((sess) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(children: [
                            Expanded(child: Text(sess.formattedDate, style: const TextStyle(fontSize: 12))),
                            SizedBox(width: 100, child: Text(sess.formattedDuration, style: TextStyle(fontSize: 12, color: DashboardTheme.textSecondary))),
                            SizedBox(width: 80, child: Text('↑${sess.uploadedRecords}', style: const TextStyle(fontSize: 12))),
                            SizedBox(width: 80, child: Text('↓${sess.downloadedRecords}', style: const TextStyle(fontSize: 12))),
                            SizedBox(width: 100, child: StatusChip(
                              label: sess.status,
                              color: sess.status == 'success' ? DashboardTheme.success : sess.status == 'partial' ? DashboardTheme.warning : DashboardTheme.danger,
                            )),
                          ]),
                        )),
                      ]),
              ),

              if (s.lastError != null) ...[
                const SizedBox(height: 16),
                SectionCard(
                  title: 'Last Error',
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: DashboardTheme.danger.withAlpha(10), borderRadius: BorderRadius.circular(6), border: Border.all(color: DashboardTheme.danger.withAlpha(40))),
                    child: Text(s.lastError!, style: TextStyle(fontSize: 12, color: DashboardTheme.danger, fontFamily: 'monospace')),
                  ),
                ),
              ],
            ]),
          ),
        ],
      ),
    );
  }
}

class AdminOrganizationScreen extends ConsumerWidget {
  const AdminOrganizationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orgAsync = ref.watch(organizationProvider);
    final sysAsync = ref.watch(systemInfoProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DashboardTheme.sp32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.go('/admin')),
            const SizedBox(width: 8),
            const Expanded(child: PageHeader(title: 'Organisasi', subtitle: 'Informasi dan konfigurasi organisasi.')),
            OutlinedButton.icon(
              onPressed: () => _showComingSoon(context, 'Edit Organization'),
              icon: const Icon(Icons.edit_rounded, size: 14),
              label: const Text('Edit'),
            ),
          ]),
          const SizedBox(height: 24),

          LayoutBuilder(builder: (context, c) {
            final side = (c.maxWidth - 16) / 2;
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(width: side, child: SectionCard(
                title: 'Informasi Organisasi',
                child: orgAsync.when(
                  loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                  error: (e, _) => ErrorView(message: e.toString()),
                  data: (org) => Column(children: [
                    _InfoRow('Nama Bisnis', org.name),
                    _InfoRow('Slug', org.slug),
                    _InfoRow('ID Organisasi', org.shortId),
                    _InfoRow('Dibuat', org.formattedCreated),
                    _InfoRow('Timezone', org.timezone),
                    _InfoRow('Mata Uang', org.currency),
                  ]),
                ),
              )),
              const SizedBox(width: 16),
              SizedBox(width: side, child: SectionCard(
                title: 'Informasi Sistem',
                child: sysAsync.when(
                  loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                  error: (e, _) => ErrorView(message: e.toString()),
                  data: (sys) => Column(children: [
                    _InfoRow('Dashboard Version', sys.dashboardVersion),
                    _InfoRow('Flutter Version', sys.flutterVersion),
                    _InfoRow('Schema Version', '${sys.schemaVersion}'),
                    _InfoRow('Build Mode', sys.buildMode),
                    _InfoRow('Supabase', sys.supabaseStatus),
                    _InfoRow('Org ID', sys.organizationId.substring(0, 8)),
                  ]),
                ),
              )),
            ]);
          }),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

void _showComingSoon(BuildContext context, String feature) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text('Coming Soon'),
      content: Text('$feature akan tersedia di fase berikutnya.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
    ),
  );
}

class _H extends StatelessWidget {
  const _H(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: DashboardTheme.textSecondary));
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      SizedBox(width: 140, child: Text(label, style: TextStyle(fontSize: 13, color: DashboardTheme.textSecondary))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
    ]),
  );
}

class _KpiCard extends StatelessWidget {
  const _KpiCard(this.label, this.value, {required this.color});
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: DashboardTheme.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: DashboardTheme.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 11, color: DashboardTheme.textSecondary)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color), overflow: TextOverflow.ellipsis),
    ]),
  );
}
