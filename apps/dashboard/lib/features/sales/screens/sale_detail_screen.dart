import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/shared_widgets.dart';
import '../../../theme/dashboard_theme.dart';
import '../providers/sales_providers.dart';

class SaleDetailScreen extends ConsumerWidget {
  const SaleDetailScreen({super.key, required this.saleId});
  final String saleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(saleDetailProvider(saleId));

    return detailAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(saleDetailProvider(saleId)),
      ),
      data: (sale) => SingleChildScrollView(
        padding: const EdgeInsets.all(DashboardTheme.sp32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => context.go('/sales'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PageHeader(
                    title: sale.invoiceNumber,
                    subtitle:
                        '${sale.formattedDate} pukul ${sale.formattedTime}',
                  ),
                ),
                StatusChip(
                  label: sale.synced ? 'Synced' : 'Pending Sync',
                  color: sale.synced
                      ? DashboardTheme.success
                      : DashboardTheme.warning,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Info cards row
            LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Transaction info
                    Expanded(
                      flex: 2,
                      child: SectionCard(
                        title: 'Detail Transaksi',
                        child: Column(
                          children: [
                            _InfoRow('Invoice',
                                sale.invoiceNumber),
                            _InfoRow('Tanggal',
                                sale.formattedDate),
                            _InfoRow(
                                'Jam', sale.formattedTime),
                            _InfoRow('Kasir', sale.createdBy),
                            _InfoRow(
                                'Device', sale.deviceId),
                            _InfoRow(
                              'Status Sync',
                              sale.synced
                                  ? 'Tersinkronisasi'
                                  : 'Menunggu sinkronisasi',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Summary card
                    Expanded(
                      child: SectionCard(
                        title: 'Ringkasan',
                        child: Column(
                          children: [
                            _InfoRow('Jumlah Item',
                                '${sale.items.length} produk'),
                            _InfoRow(
                                'Total', sale.formattedTotal,
                                valueStyle: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      DashboardTheme.primary,
                                )),
                            _InfoRow('Dibayar',
                                sale.formattedPaid),
                            _InfoRow('Kembalian',
                                sale.formattedChange),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // Items table
            SectionCard(
              title: 'Produk Dibeli',
              subtitle: '${sale.items.length} item',
              child: Column(
                children: [
                  // Table header
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                            child: _ColumnHeader('Produk')),
                        const SizedBox(
                            width: 80,
                            child: _ColumnHeader('Qty',
                                textAlign:
                                    TextAlign.right)),
                        const SizedBox(
                            width: 120,
                            child: _ColumnHeader('Harga',
                                textAlign:
                                    TextAlign.right)),
                        const SizedBox(
                            width: 120,
                            child: _ColumnHeader('Subtotal',
                                textAlign:
                                    TextAlign.right)),
                      ],
                    ),
                  ),
                  Divider(
                      height: 1,
                      color: DashboardTheme.border),
                  ...sale.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(item.productName,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight:
                                        FontWeight.w500)),
                          ),
                          SizedBox(
                            width: 80,
                            child: Text('${item.quantity}',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                    fontSize: 13)),
                          ),
                          SizedBox(
                            width: 120,
                            child: Text(item.formattedPrice,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                    fontSize: 13)),
                          ),
                          SizedBox(
                            width: 120,
                            child: Text(
                                item.formattedSubtotal,
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight:
                                        FontWeight.w600,
                                    color: DashboardTheme
                                        .primary)),
                          ),
                        ],
                      ),
                    );
                  }),
                  Divider(
                      height: 1,
                      color: DashboardTheme.border),
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 10),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text('Total',
                              style: TextStyle(
                                  fontWeight:
                                      FontWeight.w700)),
                        ),
                        SizedBox(
                          width: 120,
                          child: Text(sale.formattedTotal,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: DashboardTheme.primary,
                              )),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Timeline
            SectionCard(
              title: 'Timeline',
              child: Column(
                children: [
                  _TimelineItem(
                    icon: Icons.receipt_rounded,
                    color: DashboardTheme.success,
                    title: 'Transaksi Dibuat',
                    subtitle:
                        '${sale.formattedDate} pukul ${sale.formattedTime} oleh ${sale.createdBy}',
                  ),
                  _TimelineItem(
                    icon: sale.synced
                        ? Icons.cloud_done_rounded
                        : Icons.cloud_upload_rounded,
                    color: sale.synced
                        ? DashboardTheme.primary
                        : DashboardTheme.textTertiary,
                    title: sale.synced
                        ? 'Tersinkronisasi ke Supabase'
                        : 'Menunggu sinkronisasi',
                    subtitle: sale.synced
                        ? 'Data telah dikirim ke server.'
                        : 'Akan dikirim saat perangkat online.',
                    isLast: true,
                  ),
                ],
              ),
            ),
          ],
        ),
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
      child: Row(
        children: [
          SizedBox(
            width: 120,
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
        ],
      ),
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

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.isLast = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 14, color: color),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color: DashboardTheme.borderLight,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 12,
                      color: DashboardTheme.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}
