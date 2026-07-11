import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/shared_widgets.dart';
import '../../../theme/dashboard_theme.dart';
import '../providers/admin_providers.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orgAsync = ref.watch(organizationProvider);
    final devicesAsync = ref.watch(devicesProvider);
    final usersAsync = ref.watch(usersProvider);
    final syncAsync = ref.watch(syncHealthProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DashboardTheme.sp32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Administration',
            subtitle: 'Kelola organisasi, perangkat, sinkronisasi, dan pengguna.',
          ),
          const SizedBox(height: 24),

          // Summary cards
          LayoutBuilder(builder: (context, c) {
            final cols = c.maxWidth > 900 ? 3 : 2;
            final w = (c.maxWidth - (cols - 1) * 12) / cols;
            return Wrap(spacing: 12, runSpacing: 12, children: [
              SizedBox(width: w, child: _AdminCard(
                icon: Icons.devices_rounded,
                title: 'Perangkat',
                value: devicesAsync.when(data: (d) => '${d.length} terdaftar', loading: () => '—', error: (_, __) => 'Error'),
                subtitle: devicesAsync.when(data: (d) => '${d.where((x) => x.isOnline).length} online', loading: () => '', error: (_, __) => ''),
                color: DashboardTheme.primary,
                onTap: () => context.go('/admin/devices'),
              )),
              SizedBox(width: w, child: _AdminCard(
                icon: Icons.people_rounded,
                title: 'Pengguna',
                value: usersAsync.when(data: (u) => '${u.length} anggota', loading: () => '—', error: (_, __) => 'Error'),
                subtitle: 'Administrator & Operator',
                color: DashboardTheme.success,
                onTap: () => context.go('/admin/users'),
              )),
              SizedBox(width: w, child: _AdminCard(
                icon: Icons.sync_rounded,
                title: 'Sinkronisasi',
                value: syncAsync.when(data: (s) => s.formattedSuccessRate, loading: () => '—', error: (_, __) => 'Error'),
                subtitle: syncAsync.when(data: (s) => '${s.totalSessions} sesi', loading: () => '', error: (_, __) => ''),
                color: syncAsync.when(data: (s) => s.successRate < 80 ? DashboardTheme.danger : DashboardTheme.success, loading: () => DashboardTheme.primary, error: (_, __) => DashboardTheme.danger),
                onTap: () => context.go('/admin/sync'),
              )),
              SizedBox(width: w, child: _AdminCard(
                icon: Icons.business_rounded,
                title: 'Organisasi',
                value: orgAsync.when(data: (o) => o.name, loading: () => '—', error: (_, __) => 'Error'),
                subtitle: orgAsync.when(data: (o) => o.slug, loading: () => '', error: (_, __) => ''),
                color: DashboardTheme.primary,
                onTap: () => context.go('/admin/organization'),
              )),
              SizedBox(width: w, child: _AdminCard(
                icon: Icons.backup_rounded,
                title: 'Backup',
                value: 'Supabase',
                subtitle: 'Dikelola otomatis',
                color: DashboardTheme.textSecondary,
                onTap: null,
              )),
              SizedBox(width: w, child: _AdminCard(
                icon: Icons.info_outline_rounded,
                title: 'App Version',
                value: '1.0.0',
                subtitle: 'Dashboard Web',
                color: DashboardTheme.textSecondary,
                onTap: null,
              )),
            ]);
          }),
          const SizedBox(height: 24),

          // Quick device status
          SectionCard(
            title: 'Status Perangkat',
            subtitle: 'Perangkat Android yang terdaftar',
            trailing: TextButton(onPressed: () => context.go('/admin/devices'), child: const Text('Lihat Semua')),
            child: devicesAsync.when(
              loading: () => const SizedBox(height: 60, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
              error: (e, _) => ErrorView(message: e.toString()),
              data: (devices) {
                if (devices.isEmpty) return const EmptyState(title: 'Tidak ada perangkat', description: 'Belum ada perangkat yang terdaftar.', icon: Icons.devices_rounded);
                return Column(children: devices.take(5).map((d) => _DeviceRow(device: d)).toList());
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  const _AdminCard({required this.icon, required this.title, required this.value, required this.color, this.subtitle, this.onTap});
  final IconData icon;
  final String title;
  final String value;
  final String? subtitle;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DashboardTheme.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: DashboardTheme.border),
          ),
          child: Row(children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 20, color: color)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontSize: 12, color: DashboardTheme.textSecondary)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
              if (subtitle != null) Text(subtitle!, style: TextStyle(fontSize: 11, color: DashboardTheme.textTertiary), overflow: TextOverflow.ellipsis),
            ])),
            if (onTap != null) Icon(Icons.chevron_right_rounded, size: 16, color: DashboardTheme.textTertiary),
          ]),
        ),
      ),
    );
  }
}

class _DeviceRow extends StatelessWidget {
  const _DeviceRow({required this.device});
  final dynamic device;

  @override
  Widget build(BuildContext context) {
    final statusColor = device.syncStatus == 'online'
        ? DashboardTheme.success
        : device.syncStatus == 'warning'
            ? DashboardTheme.warning
            : DashboardTheme.textTertiary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(device.deviceName as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          Text('${device.platform} · v${device.appVersion}', style: TextStyle(fontSize: 11, color: DashboardTheme.textSecondary)),
        ])),
        Text(device.formattedLastSeen as String, style: TextStyle(fontSize: 11, color: DashboardTheme.textTertiary)),
      ]),
    );
  }
}
