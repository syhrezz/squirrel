import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/shared_widgets.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../theme/dashboard_theme.dart';
import '../models/customer_models.dart';
import '../providers/customer_providers.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() =>
      _CustomersScreenState();
}

class _CustomersScreenState
    extends ConsumerState<CustomersScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(customerFilterProvider);
    final customersAsync = ref.watch(customersPageProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
          child: Row(
            children: [
              const Expanded(
                child: PageHeader(
                  title: 'Kasbon',
                  subtitle:
                      'Lihat seluruh pelanggan dan saldo kasbon.',
                ),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    ref.invalidate(customersPageProvider),
                icon: const Icon(Icons.refresh_rounded,
                    size: 14),
                label: const Text('Refresh'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download_rounded,
                    size: 14),
                label: const Text('Export CSV'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Summary strip
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: _KasbonSummaryStrip(),
        ),
        const SizedBox(height: 16),

        // Filters
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: _CustomerFilterToolbar(
            filter: filter,
            searchController: _searchController,
            onFilterChanged: (f) =>
                ref.read(customerFilterProvider.notifier).state =
                    f,
          ),
        ),
        const SizedBox(height: 16),

        // Table
        Expanded(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 32),
            child: customersAsync.when(
              loading: () => _CustomerTableSkeleton(),
              error: (e, _) {
                if (e.toString().contains('debounced')) {
                  return _CustomerTableSkeleton();
                }
                return ErrorView(
                  message: e.toString(),
                  onRetry: () =>
                      ref.invalidate(customersPageProvider),
                );
              },
              data: (result) => _CustomerTable(
                result: result,
                filter: filter,
                onSort: (f) => ref
                    .read(customerFilterProvider.notifier)
                    .setSort(f),
                onPageChange: (p) => ref
                    .read(customerFilterProvider.notifier)
                    .setPage(p),
                onPageSizeChange: (s) => ref
                    .read(customerFilterProvider.notifier)
                    .setPageSize(s),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Summary strip
// ---------------------------------------------------------------------------

class _KasbonSummaryStrip extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(kasbonSummaryProvider);

    return summaryAsync.when(
      loading: () => const SizedBox(height: 72),
      error: (_, __) => const SizedBox.shrink(),
      data: (s) => Row(
        children: [
          _SummaryTile('Outstanding', s.formattedOutstanding,
              Icons.account_balance_wallet_rounded,
              DashboardTheme.danger),
          const SizedBox(width: 12),
          _SummaryTile(
              'Total Pelanggan',
              '${s.totalCustomers}',
              Icons.people_rounded,
              DashboardTheme.primary),
          const SizedBox(width: 12),
          _SummaryTile(
              'Berhutang',
              '${s.customersWithDebt}',
              Icons.warning_amber_rounded,
              DashboardTheme.warning),
          const SizedBox(width: 12),
          _SummaryTile('Dibayar Bulan Ini',
              s.formattedPaid,
              Icons.check_circle_rounded,
              DashboardTheme.success),
          const SizedBox(width: 12),
          _SummaryTile(
              'Rata-rata Outstanding',
              s.formattedAverage,
              Icons.analytics_rounded,
              DashboardTheme.primary),
          const SizedBox(width: 12),
          _SummaryTile(
              'Terbesar',
              '${s.largestCustomerName} (${s.formattedLargest})',
              Icons.person_rounded,
              DashboardTheme.danger),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile(
      this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: DashboardTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: DashboardTheme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 11,
                          color: DashboardTheme.textSecondary),
                      overflow: TextOverflow.ellipsis),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis),
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
// Filter toolbar
// ---------------------------------------------------------------------------

class _CustomerFilterToolbar extends StatelessWidget {
  const _CustomerFilterToolbar({
    required this.filter,
    required this.searchController,
    required this.onFilterChanged,
  });

  final CustomerFilter filter;
  final TextEditingController searchController;
  final void Function(CustomerFilter) onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DashboardTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DashboardTheme.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 220,
            height: 36,
            child: TextField(
              controller: searchController,
              onChanged: (v) => onFilterChanged(
                  filter.copyWith(search: v.trim(), page: 0)),
              decoration: InputDecoration(
                hintText: 'Cari nama pelanggan...',
                prefixIcon: Icon(Icons.search_rounded,
                    size: 16,
                    color: DashboardTheme.textTertiary),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12),
                filled: true,
                fillColor: DashboardTheme.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                      color: DashboardTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                      color: DashboardTheme.border),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ...[
            (CustomerBalanceFilter.all, 'Semua'),
            (CustomerBalanceFilter.hasDebt, 'Ada Hutang'),
            (CustomerBalanceFilter.paidOff, 'Lunas'),
            (CustomerBalanceFilter.overpaid, 'Overpaid'),
          ].map((entry) {
            final isActive = filter.balanceFilter == entry.$1;
            return Padding(
              padding: const EdgeInsets.only(left: 4),
              child: GestureDetector(
                onTap: () => onFilterChanged(filter.copyWith(
                    balanceFilter: entry.$1, page: 0)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isActive
                        ? DashboardTheme.primary
                        : DashboardTheme.bg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isActive
                          ? DashboardTheme.primary
                          : DashboardTheme.border,
                    ),
                  ),
                  child: Text(entry.$2,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isActive
                              ? Colors.white
                              : DashboardTheme.textSecondary)),
                ),
              ),
            );
          }),
          if (filter.hasActiveFilters) ...[
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () {
                searchController.clear();
                onFilterChanged(const CustomerFilter());
              },
              icon:
                  const Icon(Icons.close_rounded, size: 14),
              label: const Text('Reset'),
              style: TextButton.styleFrom(
                  foregroundColor: DashboardTheme.danger),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Customer Table
// ---------------------------------------------------------------------------

class _CustomerTable extends StatelessWidget {
  const _CustomerTable({
    required this.result,
    required this.filter,
    required this.onSort,
    required this.onPageChange,
    required this.onPageSizeChange,
  });

  final CustomerPageResult result;
  final CustomerFilter filter;
  final void Function(CustomerSortField) onSort;
  final void Function(int) onPageChange;
  final void Function(int) onPageSizeChange;

  @override
  Widget build(BuildContext context) {
    if (result.items.isEmpty) {
      return SectionCard(
        child: EmptyState(
          title: 'Tidak ada pelanggan',
          description:
              'Tidak ada pelanggan yang sesuai dengan filter.',
          icon: Icons.people_rounded,
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: SectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _CustomerTableHeader(
                    filter: filter, onSort: onSort),
                Divider(
                    height: 1, color: DashboardTheme.border),
                Expanded(
                  child: ListView.separated(
                    itemCount: result.items.length,
                    separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: DashboardTheme.borderLight),
                    itemBuilder: (context, i) {
                      final item = result.items[i];
                      return _CustomerRow(
                        item: item,
                        onTap: () => context
                            .go('/customers/${item.id}'),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _CustomerPagination(
          result: result,
          onPageChange: onPageChange,
          onPageSizeChange: onPageSizeChange,
        ),
      ],
    );
  }
}

class _CustomerTableHeader extends StatelessWidget {
  const _CustomerTableHeader(
      {required this.filter, required this.onSort});
  final CustomerFilter filter;
  final void Function(CustomerSortField) onSort;

  Widget _col(String label,
      {CustomerSortField? field,
      double? width,
      TextAlign align = TextAlign.left}) {
    Widget w = InkWell(
      onTap: field != null ? () => onSort(field) : null,
      child: Row(
        mainAxisAlignment: align == TextAlign.right
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: field != null &&
                          filter.sortField == field
                      ? DashboardTheme.primary
                      : DashboardTheme.textSecondary)),
          if (field != null) ...[
            const SizedBox(width: 4),
            Icon(
              filter.sortField == field
                  ? (filter.sortAscending
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded)
                  : Icons.unfold_more_rounded,
              size: 12,
              color: filter.sortField == field
                  ? DashboardTheme.primary
                  : DashboardTheme.textTertiary,
            ),
          ],
        ],
      ),
    );
    if (width != null) return SizedBox(width: width, child: w);
    return Expanded(child: w);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DashboardTheme.bg,
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _col('Pelanggan',
              field: CustomerSortField.name),
          _col('Telepon', width: 120),
          _col('Saldo',
              field: CustomerSortField.balance,
              width: 140,
              align: TextAlign.right),
          _col('Transaksi Terakhir',
              field: CustomerSortField.lastTransaction,
              width: 150),
          _col('Transaksi', width: 90),
          _col('Status', width: 100),
        ],
      ),
    );
  }
}

class _CustomerRow extends StatelessWidget {
  const _CustomerRow(
      {required this.item, required this.onTap});
  final CustomerExplorerItem item;
  final VoidCallback onTap;

  Color get _balanceColor {
    if (item.hasDebt) return DashboardTheme.danger;
    if (item.isOverpaid) return DashboardTheme.success;
    return DashboardTheme.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: DashboardTheme.bg,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(item.name,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis),
              ),
              SizedBox(
                width: 120,
                child: Text(item.phone ?? '—',
                    style: TextStyle(
                        fontSize: 12,
                        color: DashboardTheme.textSecondary),
                    overflow: TextOverflow.ellipsis),
              ),
              SizedBox(
                width: 140,
                child: Text(
                  item.balance == 0
                      ? 'Lunas'
                      : item.formattedBalance,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _balanceColor),
                ),
              ),
              SizedBox(
                width: 150,
                child: Text(item.formattedLastTx,
                    style: TextStyle(
                        fontSize: 12,
                        color: DashboardTheme.textSecondary)),
              ),
              SizedBox(
                width: 90,
                child: Text('${item.txCount}',
                    style: const TextStyle(fontSize: 13)),
              ),
              SizedBox(
                width: 100,
                child: StatusChip(
                  label: item.statusLabel,
                  color: item.hasDebt
                      ? DashboardTheme.danger
                      : item.isOverpaid
                          ? DashboardTheme.success
                          : DashboardTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerPagination extends StatelessWidget {
  const _CustomerPagination({
    required this.result,
    required this.onPageChange,
    required this.onPageSizeChange,
  });
  final CustomerPageResult result;
  final void Function(int) onPageChange;
  final void Function(int) onPageSizeChange;

  @override
  Widget build(BuildContext context) {
    final start = result.page * result.pageSize + 1;
    final end = (start + result.pageSize - 1)
        .clamp(1, result.totalCount);
    return Row(
      children: [
        Text('$start–$end dari ${result.totalCount} pelanggan',
            style: TextStyle(
                fontSize: 12,
                color: DashboardTheme.textSecondary)),
        const Spacer(),
        DropdownButton<int>(
          value: result.pageSize,
          underline: const SizedBox.shrink(),
          items: [25, 50, 100]
              .map((s) => DropdownMenuItem(
                  value: s,
                  child: Text('$s per halaman',
                      style: const TextStyle(fontSize: 12))))
              .toList(),
          onChanged: (v) {
            if (v != null) onPageSizeChange(v);
          },
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          iconSize: 18,
          onPressed: result.hasPrev
              ? () => onPageChange(result.page - 1)
              : null,
        ),
        Text('${result.page + 1} / ${result.totalPages}',
            style: const TextStyle(fontSize: 12)),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded),
          iconSize: 18,
          onPressed: result.hasNext
              ? () => onPageChange(result.page + 1)
              : null,
        ),
      ],
    );
  }
}

class _CustomerTableSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            height: 40,
            color: DashboardTheme.bg,
            padding:
                const EdgeInsets.symmetric(horizontal: 16),
            child: const Row(children: [
              Expanded(
                  child: SkeletonBox(width: 100, height: 12)),
              SizedBox(width: 16),
              SkeletonBox(width: 80, height: 12),
            ]),
          ),
          Divider(height: 1, color: DashboardTheme.border),
          ...List.generate(
              8,
              (_) => Column(children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: TableRowSkeleton(),
                    ),
                    Divider(
                        height: 1,
                        color: DashboardTheme.borderLight),
                  ])),
        ],
      ),
    );
  }
}
