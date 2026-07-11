import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/shared_widgets.dart';
import '../../../theme/dashboard_theme.dart';
import '../models/customer_models.dart';
import '../providers/customer_providers.dart';

class CustomerDetailScreen extends ConsumerWidget {
  const CustomerDetailScreen(
      {super.key, required this.customerId});
  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync =
        ref.watch(customerDetailExplorerProvider(customerId));

    return detailAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(
            customerDetailExplorerProvider(customerId)),
      ),
      data: (customer) => SingleChildScrollView(
        padding: const EdgeInsets.all(DashboardTheme.sp32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => context.go('/customers'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PageHeader(
                    title: customer.name,
                    subtitle: customer.phone ?? 'Tidak ada nomor telepon',
                  ),
                ),
                StatusChip(
                  label: customer.isActive ? 'Aktif' : 'Nonaktif',
                  color: customer.isActive
                      ? DashboardTheme.success
                      : DashboardTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                StatusChip(
                  label: customer.balance > 0
                      ? 'Berhutang'
                      : customer.balance < 0
                          ? 'Lebih Bayar'
                          : 'Lunas',
                  color: customer.balance > 0
                      ? DashboardTheme.danger
                      : customer.balance < 0
                          ? DashboardTheme.success
                          : DashboardTheme.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Row 1: Customer info + Balance card
            LayoutBuilder(
              builder: (context, constraints) {
                final side = (constraints.maxWidth - 16) / 2;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: side,
                      child: SectionCard(
                        title: 'Data Pelanggan',
                        child: Column(children: [
                          _InfoRow('Nama', customer.name),
                          _InfoRow('Telepon',
                              customer.phone ?? '—'),
                          _InfoRow(
                              'Catatan', customer.note ?? '—'),
                          _InfoRow('Status',
                              customer.isActive ? 'Aktif' : 'Nonaktif'),
                          _InfoRow('Terdaftar',
                              customer.formattedCreated),
                        ]),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: side,
                      child: SectionCard(
                        title: 'Saldo Kasbon',
                        child: Column(children: [
                          _InfoRow(
                            'Saldo Saat Ini',
                            customer.balance == 0
                                ? 'Lunas'
                                : customer.formattedBalance,
                            valueStyle: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: customer.balance > 0
                                  ? DashboardTheme.danger
                                  : customer.balance < 0
                                      ? DashboardTheme.success
                                      : DashboardTheme.textSecondary,
                            ),
                          ),
                          _InfoRow('Total Hutang',
                              customer.formattedTotalDebt),
                          _InfoRow('Total Bayar',
                              customer.formattedTotalPayment),
                          _InfoRow('Jumlah Hutang',
                              '${customer.debtCount}x'),
                          _InfoRow('Jumlah Bayar',
                              '${customer.paymentCount}x'),
                        ]),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // Row 2: Payment behaviour + Debt aging
            LayoutBuilder(
              builder: (context, constraints) {
                final side = (constraints.maxWidth - 16) / 2;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: side,
                      child: SectionCard(
                        title: 'Perilaku Pembayaran',
                        child: Column(children: [
                          _InfoRow('Hutang Terbesar',
                              customer.formattedLargestDebt),
                          _InfoRow('Bayar Terbesar',
                              customer.formattedLargestPayment),
                          _InfoRow('Pembayaran Terakhir',
                              customer.formattedLastPayment),
                        ]),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: side,
                      child: _DebtAgingCard(
                          customerId: customerId),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // Transaction timeline
            _TimelineCard(customerId: customerId),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Debt Aging Card
// ---------------------------------------------------------------------------

class _DebtAgingCard extends ConsumerWidget {
  const _DebtAgingCard({required this.customerId});
  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agingAsync = ref.watch(debtAgingProvider(customerId));

    return SectionCard(
      title: 'Umur Hutang',
      subtitle: 'Berdasarkan tanggal transaksi',
      child: agingAsync.when(
        loading: () => const SizedBox(
            height: 80,
            child: Center(
                child: CircularProgressIndicator(strokeWidth: 2))),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (buckets) {
          final total = buckets.fold<int>(
              0, (sum, b) => sum + b.amount);
          if (total == 0) {
            return const EmptyState(
              title: 'Tidak ada hutang',
              description: 'Pelanggan ini tidak memiliki hutang.',
              icon: Icons.check_circle_rounded,
            );
          }
          return Column(
            children: [
              // Stacked bar
              Container(
                height: 16,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: DashboardTheme.borderLight,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: buckets
                        .where((b) => b.amount > 0)
                        .map((b) => Flexible(
                              flex: b.amount,
                              child: Container(
                                color: Color(b.color),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Legend
              ...buckets.map((b) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Color(b.color),
                            borderRadius:
                                BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(b.label,
                                style: const TextStyle(
                                    fontSize: 12))),
                        Text(b.formattedAmount,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Timeline Card
// ---------------------------------------------------------------------------

class _TimelineCard extends ConsumerWidget {
  const _TimelineCard({required this.customerId});
  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineAsync =
        ref.watch(customerTimelineProvider(customerId));

    return SectionCard(
      title: 'Riwayat Transaksi',
      subtitle: 'Terbaru dulu',
      child: timelineAsync.when(
        loading: () => const SizedBox(
            height: 120,
            child: Center(
                child: CircularProgressIndicator(strokeWidth: 2))),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              title: 'Belum ada transaksi',
              description: 'Belum ada hutang atau pembayaran.',
              icon: Icons.receipt_long_rounded,
            );
          }
          return Column(
            children: [
              // Header
              Row(children: [
                const SizedBox(
                    width: 32, child: SizedBox.shrink()),
                const SizedBox(width: 12),
                const Expanded(
                    child: _ColumnHeader('Tanggal')),
                const SizedBox(
                    width: 120,
                    child: _ColumnHeader('Jumlah',
                        textAlign: TextAlign.right)),
                const SizedBox(
                    width: 140,
                    child: _ColumnHeader('Saldo Berjalan',
                        textAlign: TextAlign.right)),
                const Expanded(child: _ColumnHeader('Catatan')),
              ]),
              Divider(height: 1, color: DashboardTheme.border),
              ...items.map((item) => Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8),
                    child: Row(children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: item.isDebt
                              ? DashboardTheme.danger.withAlpha(20)
                              : DashboardTheme.success.withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item.isDebt
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          size: 14,
                          color: item.isDebt
                              ? DashboardTheme.danger
                              : DashboardTheme.success,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.isDebt ? 'Hutang' : 'Bayar',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                            Text(item.formattedDate,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: DashboardTheme
                                        .textTertiary)),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: Text(
                          '${item.isDebt ? '+' : '-'} ${item.formattedAmount}',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: item.isDebt
                                ? DashboardTheme.danger
                                : DashboardTheme.success,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 140,
                        child: Text(
                          item.runningBalance >= 0
                              ? item.formattedBalance
                              : '-${item.formattedBalance}',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 12,
                            color: item.runningBalance > 0
                                ? DashboardTheme.danger
                                : item.runningBalance < 0
                                    ? DashboardTheme.success
                                    : DashboardTheme.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item.note ?? '—',
                          style: TextStyle(
                              fontSize: 12,
                              color: DashboardTheme.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]),
                  )),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value, {this.valueStyle});
  final String label;
  final String value;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        SizedBox(
          width: 140,
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: DashboardTheme.textSecondary)),
        ),
        Expanded(
          child: Text(value,
              style: valueStyle ??
                  const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
        ),
      ]),
    );
  }
}

class _ColumnHeader extends StatelessWidget {
  const _ColumnHeader(this.label,
      {this.textAlign = TextAlign.left});
  final String label;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return Text(label,
        textAlign: textAlign,
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: DashboardTheme.textSecondary));
  }
}
