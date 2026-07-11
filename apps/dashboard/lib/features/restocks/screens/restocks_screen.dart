import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/shared_widgets.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../theme/dashboard_theme.dart';
import '../models/restock_models.dart';
import '../providers/restock_providers.dart';

class RestocksScreen extends ConsumerStatefulWidget {
  const RestocksScreen({super.key});

  @override
  ConsumerState<RestocksScreen> createState() =>
      _RestocksScreenState();
}

class _RestocksScreenState
    extends ConsumerState<RestocksScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(restockFilterProvider);
    final restocksAsync = ref.watch(restocksPageProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
          child: Row(
            children: [
              const Expanded(
                child: PageHeader(
                  title: 'Restock Barang',
                  subtitle:
                      'Lihat seluruh riwayat pembelian barang.',
                ),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    ref.invalidate(restocksPageProvider),
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

        // Purchase summary cards
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 32),
          child: _PurchaseSummaryBar(),
        ),
        const SizedBox(height: 16),

        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 32),
          child: _RestockFilterToolbar(
            filter: filter,
            searchController: _searchController,
            onFilterChanged: (f) =>
                ref.read(restockFilterProvider.notifier).state = f,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 32),
            child: restocksAsync.when(
              loading: () => _RestockTableSkeleton(),
              error: (e, _) {
                if (e.toString().contains('debounced')) {
                  return _RestockTableSkeleton();
                }
                return ErrorView(
                  message: e.toString(),
                  onRetry: () =>
                      ref.invalidate(restocksPageProvider),
                );
              },
              data: (result) => _RestockTable(
                result: result,
                filter: filter,
                onSort: (f) => ref
                    .read(restockFilterProvider.notifier)
                    .setSort(f),
                onPageChange: (p) => ref
                    .read(restockFilterProvider.notifier)
                    .setPage(p),
                onPageSizeChange: (s) => ref
                    .read(restockFilterProvider.notifier)
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
// Purchase Summary Bar
// ---------------------------------------------------------------------------

class _PurchaseSummaryBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(purchaseSummaryProvider);

    return summaryAsync.when(
      loading: () => const SizedBox(
          height: 80,
          child: Center(
              child: CircularProgressIndicator(strokeWidth: 2))),
      error: (_, __) => const SizedBox.shrink(),
      data: (s) => Row(
        children: [
          _SummaryTile('Total Restock', '${s.totalRestocks}',
              Icons.shopping_bag_rounded,
              DashboardTheme.primary),
          const SizedBox(width: 12),
          _SummaryTile('Total Pembelian', s.formattedTotal,
              Icons.payments_rounded, DashboardTheme.success),
          const SizedBox(width: 12),
          _SummaryTile('Rata-rata/Restock', s.formattedAvg,
              Icons.analytics_rounded, DashboardTheme.primary),
          const SizedBox(width: 12),
          _SummaryTile('Harga Naik', '${s.priceIncreases} produk',
              Icons.trending_up_rounded, DashboardTheme.danger),
          const SizedBox(width: 12),
          _SummaryTile('Harga Turun',
              '${s.priceDecreases} produk',
              Icons.trending_down_rounded,
              DashboardTheme.success),
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
                          fontSize: 14,
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

class _RestockFilterToolbar extends StatelessWidget {
  const _RestockFilterToolbar({
    required this.filter,
    required this.searchController,
    required this.onFilterChanged,
  });

  final RestockFilter filter;
  final TextEditingController searchController;
  final void Function(RestockFilter) onFilterChanged;

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
                hintText: 'Cari nomor restock...',
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
          ...RestockDatePreset.values.map((preset) {
            final labels = {
              RestockDatePreset.today: 'Hari Ini',
              RestockDatePreset.yesterday: 'Kemarin',
              RestockDatePreset.last7: '7 Hari',
              RestockDatePreset.last30: '30 Hari',
              RestockDatePreset.all: 'Semua',
            };
            final isActive = filter.datePreset == preset;
            return Padding(
              padding: const EdgeInsets.only(left: 4),
              child: GestureDetector(
                onTap: () => onFilterChanged(
                    filter.copyWith(datePreset: preset, page: 0)),
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
                  child: Text(
                    labels[preset]!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isActive
                          ? Colors.white
                          : DashboardTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }),
          if (filter.hasActiveFilters) ...[
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () {
                searchController.clear();
                onFilterChanged(const RestockFilter());
              },
              icon: const Icon(Icons.close_rounded, size: 14),
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
// Restock table
// ---------------------------------------------------------------------------

class _RestockTable extends StatelessWidget {
  const _RestockTable({
    required this.result,
    required this.filter,
    required this.onSort,
    required this.onPageChange,
    required this.onPageSizeChange,
  });

  final RestockPageResult result;
  final RestockFilter filter;
  final void Function(RestockSortField) onSort;
  final void Function(int) onPageChange;
  final void Function(int) onPageSizeChange;

  @override
  Widget build(BuildContext context) {
    if (result.items.isEmpty) {
      return SectionCard(
        child: EmptyState(
          title: 'Belum ada data restock',
          description:
              'Tidak ada restock yang sesuai dengan filter.',
          icon: Icons.shopping_bag_rounded,
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
                _RestockTableHeader(
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
                      return _RestockRow(
                        item: item,
                        onTap: () => context
                            .go('/restocks/${item.id}'),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _RestockPagination(
          result: result,
          onPageChange: onPageChange,
          onPageSizeChange: onPageSizeChange,
        ),
      ],
    );
  }
}

class _RestockTableHeader extends StatelessWidget {
  const _RestockTableHeader(
      {required this.filter, required this.onSort});
  final RestockFilter filter;
  final void Function(RestockSortField) onSort;

  Widget _header(String label,
      {RestockSortField? field, double? width, TextAlign align = TextAlign.left}) {
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
                  ? (filter.sortDir == RestockSortDir.asc
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
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 10),
      color: DashboardTheme.bg,
      child: Row(
        children: [
          _header('Nomor Restock', width: 140),
          _header('Tanggal', field: RestockSortField.date, width: 110),
          _header('Jam', width: 60),
          Expanded(child: _header('Dibuat Oleh')),
          _header('Items', field: RestockSortField.itemCount, width: 60),
          _header('Total', field: RestockSortField.total, width: 130, align: TextAlign.right),
          _header('Sync', width: 60),
        ],
      ),
    );
  }
}

class _RestockRow extends StatelessWidget {
  const _RestockRow({required this.item, required this.onTap});
  final RestockExplorerItem item;
  final VoidCallback onTap;

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
              SizedBox(
                width: 140,
                child: Text(item.restockNumber,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: DashboardTheme.primary,
                        fontFamily: 'monospace')),
              ),
              SizedBox(
                width: 110,
                child: Text(item.formattedDate,
                    style: const TextStyle(fontSize: 13)),
              ),
              SizedBox(
                width: 60,
                child: Text(item.formattedTime,
                    style: TextStyle(
                        fontSize: 12,
                        color: DashboardTheme.textSecondary)),
              ),
              Expanded(
                child: Text(item.createdBy,
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis),
              ),
              SizedBox(
                width: 60,
                child: Text('${item.itemCount}',
                    style: const TextStyle(fontSize: 13)),
              ),
              SizedBox(
                width: 130,
                child: Text(item.formattedTotal,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
              SizedBox(
                width: 60,
                child: Icon(
                  item.synced
                      ? Icons.cloud_done_rounded
                      : Icons.cloud_upload_rounded,
                  size: 14,
                  color: item.synced
                      ? DashboardTheme.success
                      : DashboardTheme.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RestockPagination extends StatelessWidget {
  const _RestockPagination({
    required this.result,
    required this.onPageChange,
    required this.onPageSizeChange,
  });
  final RestockPageResult result;
  final void Function(int) onPageChange;
  final void Function(int) onPageSizeChange;

  @override
  Widget build(BuildContext context) {
    final start = result.page * result.pageSize + 1;
    final end = (start + result.pageSize - 1)
        .clamp(1, result.totalCount);
    return Row(
      children: [
        Text('$start–$end dari ${result.totalCount} restock',
            style: TextStyle(
                fontSize: 12,
                color: DashboardTheme.textSecondary)),
        const Spacer(),
        DropdownButton<int>(
          value: result.pageSize,
          underline: const SizedBox.shrink(),
          items: [25, 50, 100].map((s) => DropdownMenuItem(
              value: s,
              child: Text('$s per halaman',
                  style: const TextStyle(fontSize: 12)))).toList(),
          onChanged: (v) { if (v != null) onPageSizeChange(v); },
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

class _RestockTableSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            height: 40,
            color: DashboardTheme.bg,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Row(children: [
              SkeletonBox(width: 100, height: 12),
              SizedBox(width: 16),
              Expanded(child: SkeletonBox(width: 80, height: 12)),
            ]),
          ),
          Divider(height: 1, color: DashboardTheme.border),
          ...List.generate(8, (_) => Column(children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: TableRowSkeleton(),
            ),
            Divider(height: 1, color: DashboardTheme.borderLight),
          ])),
        ],
      ),
    );
  }
}
