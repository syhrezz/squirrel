import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/overview_models.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/shared_widgets.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../theme/dashboard_theme.dart';
import '../models/sales_models.dart';
import '../providers/sales_providers.dart';

class SalesScreen extends ConsumerStatefulWidget {
  const SalesScreen({super.key});

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(salesFilterProvider);
    final salesAsync = ref.watch(salesPageProvider);

    return Column(
      children: [
        // Page header + actions
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
          child: Row(
            children: [
              const Expanded(
                child: PageHeader(
                  title: 'Penjualan',
                  subtitle: 'Lihat seluruh transaksi penjualan.',
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(salesPageProvider),
                icon: const Icon(Icons.refresh_rounded, size: 14),
                label: const Text('Refresh'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {}, // placeholder
                icon: const Icon(Icons.download_rounded, size: 14),
                label: const Text('Export CSV'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Filter toolbar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: _FilterToolbar(
            filter: filter,
            searchController: _searchController,
            onFilterChanged: (newFilter) {
              ref.read(salesFilterProvider.notifier).state =
                  newFilter;
            },
          ),
        ),
        const SizedBox(height: 16),

        // Table
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: salesAsync.when(
              loading: () => _SalesTableSkeleton(),
              error: (e, _) {
                if (e.toString().contains('debounced')) {
                  return _SalesTableSkeleton();
                }
                return ErrorView(
                  message: e.toString(),
                  onRetry: () =>
                      ref.invalidate(salesPageProvider),
                );
              },
              data: (result) => _SalesTable(
                result: result,
                filter: filter,
                onSort: (field) => ref
                    .read(salesFilterProvider.notifier)
                    .setSort(field),
                onPageChange: (page) => ref
                    .read(salesFilterProvider.notifier)
                    .setPage(page),
                onPageSizeChange: (size) => ref
                    .read(salesFilterProvider.notifier)
                    .setPageSize(size),
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
// Filter Toolbar
// ---------------------------------------------------------------------------

class _FilterToolbar extends StatelessWidget {
  const _FilterToolbar({
    required this.filter,
    required this.searchController,
    required this.onFilterChanged,
  });

  final SalesFilter filter;
  final TextEditingController searchController;
  final void Function(SalesFilter) onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DashboardTheme.surface,
        borderRadius: BorderRadius.circular(DashboardTheme.radius8),
        border: Border.all(color: DashboardTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Search + date presets
          Row(
            children: [
              // Search
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    controller: searchController,
                    onChanged: (v) => onFilterChanged(
                        filter.copyWith(search: v.trim(), page: 0)),
                    decoration: InputDecoration(
                      hintText: 'Cari kasir, invoice...',
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
              ),
              const SizedBox(width: 12),

              // Quick date presets
              ...DateRangePreset.values.map((preset) {
                final labels = {
                  DateRangePreset.today: 'Hari Ini',
                  DateRangePreset.yesterday: 'Kemarin',
                  DateRangePreset.last7: '7 Hari',
                  DateRangePreset.last30: '30 Hari',
                  DateRangePreset.all: 'Semua',
                };
                final isActive = filter.datePreset == preset;
                return Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: _PresetChip(
                    label: labels[preset]!,
                    active: isActive,
                    onTap: () => onFilterChanged(
                        filter.copyWith(
                            datePreset: preset, page: 0)),
                  ),
                );
              }),

              // Reset
              if (filter.hasActiveFilters) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    searchController.clear();
                    onFilterChanged(const SalesFilter());
                  },
                  icon: const Icon(Icons.close_rounded, size: 14),
                  label: const Text('Reset'),
                  style: TextButton.styleFrom(
                    foregroundColor: DashboardTheme.danger,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? DashboardTheme.primary
              : DashboardTheme.bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: active
                ? DashboardTheme.primary
                : DashboardTheme.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: active
                ? Colors.white
                : DashboardTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sales Table
// ---------------------------------------------------------------------------

class _SalesTable extends StatelessWidget {
  const _SalesTable({
    required this.result,
    required this.filter,
    required this.onSort,
    required this.onPageChange,
    required this.onPageSizeChange,
  });

  final SalesPageResult result;
  final SalesFilter filter;
  final void Function(SalesSortField) onSort;
  final void Function(int) onPageChange;
  final void Function(int) onPageSizeChange;

  @override
  Widget build(BuildContext context) {
    if (result.items.isEmpty) {
      return SectionCard(
        child: EmptyState(
          title: 'Tidak ada penjualan',
          description:
              'Tidak ada transaksi yang sesuai dengan filter.',
          icon: Icons.receipt_long_rounded,
        ),
      );
    }

    return Column(
      children: [
        // Table
        Expanded(
          child: SectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                // Sticky header
                _TableHeader(
                  filter: filter,
                  onSort: onSort,
                ),
                Divider(height: 1, color: DashboardTheme.border),
                // Rows
                Expanded(
                  child: ListView.separated(
                    itemCount: result.items.length,
                    separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: DashboardTheme.borderLight),
                    itemBuilder: (context, index) {
                      final item = result.items[index];
                      return _SaleRow(
                        item: item,
                        onTap: () =>
                            context.go('/sales/${item.id}'),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Pagination
        _Pagination(
          result: result,
          onPageChange: onPageChange,
          onPageSizeChange: onPageSizeChange,
        ),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.filter, required this.onSort});

  final SalesFilter filter;
  final void Function(SalesSortField) onSort;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: DashboardTheme.bg,
      child: Row(
        children: [
          _HeaderCell(
            label: 'Invoice',
            width: 130,
          ),
          _HeaderCell(
            label: 'Tanggal',
            sortField: SalesSortField.date,
            currentSort: filter.sortField,
            sortDir: filter.sortDirection,
            onSort: onSort,
          ),
          const _HeaderCell(label: 'Jam', width: 60),
          const Expanded(child: _HeaderCell(label: 'Kasir')),
          _HeaderCell(
            label: 'Items',
            width: 60,
            sortField: SalesSortField.itemCount,
            currentSort: filter.sortField,
            sortDir: filter.sortDirection,
            onSort: onSort,
          ),
          _HeaderCell(
            label: 'Total',
            width: 120,
            textAlign: TextAlign.right,
            sortField: SalesSortField.total,
            currentSort: filter.sortField,
            sortDir: filter.sortDirection,
            onSort: onSort,
          ),
          const _HeaderCell(label: 'Sync', width: 60),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({
    required this.label,
    this.width,
    this.sortField,
    this.currentSort,
    this.sortDir,
    this.onSort,
    this.textAlign = TextAlign.left,
  });

  final String label;
  final double? width;
  final SalesSortField? sortField;
  final SalesSortField? currentSort;
  final SortDirection? sortDir;
  final void Function(SalesSortField)? onSort;
  final TextAlign textAlign;

  bool get isActive => sortField != null && currentSort == sortField;

  @override
  Widget build(BuildContext context) {
    Widget content = Row(
      mainAxisAlignment: textAlign == TextAlign.right
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isActive
                ? DashboardTheme.primary
                : DashboardTheme.textSecondary,
          ),
        ),
        if (sortField != null) ...[
          const SizedBox(width: 4),
          Icon(
            isActive
                ? (sortDir == SortDirection.asc
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded)
                : Icons.unfold_more_rounded,
            size: 12,
            color: isActive
                ? DashboardTheme.primary
                : DashboardTheme.textTertiary,
          ),
        ],
      ],
    );

    if (sortField != null && onSort != null) {
      content = InkWell(
        onTap: () => onSort!(sortField!),
        child: content,
      );
    }

    if (width != null) {
      return SizedBox(width: width, child: content);
    }
    return Expanded(child: content);
  }
}

class _SaleRow extends StatelessWidget {
  const _SaleRow({required this.item, required this.onTap});

  final SalesListItem item;
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
              // Invoice
              SizedBox(
                width: 130,
                child: Text(
                  item.invoiceNumber,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: DashboardTheme.primary,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              // Date
              SizedBox(
                width: 110,
                child: Text(item.formattedDate,
                    style: const TextStyle(fontSize: 13)),
              ),
              // Time
              SizedBox(
                width: 60,
                child: Text(item.formattedTime,
                    style: TextStyle(
                        fontSize: 12,
                        color: DashboardTheme.textSecondary)),
              ),
              // Cashier
              Expanded(
                child: Text(
                  item.createdBy,
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Items
              SizedBox(
                width: 60,
                child: Text('${item.itemCount}',
                    style: const TextStyle(fontSize: 13)),
              ),
              // Total
              SizedBox(
                width: 120,
                child: Text(
                  item.formattedTotal,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              // Sync
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

// ---------------------------------------------------------------------------
// Pagination
// ---------------------------------------------------------------------------

class _Pagination extends StatelessWidget {
  const _Pagination({
    required this.result,
    required this.onPageChange,
    required this.onPageSizeChange,
  });

  final SalesPageResult result;
  final void Function(int) onPageChange;
  final void Function(int) onPageSizeChange;

  @override
  Widget build(BuildContext context) {
    final start = result.page * result.pageSize + 1;
    final end =
        (start + result.pageSize - 1).clamp(1, result.totalCount);

    return Row(
      children: [
        Text(
          '$start–$end dari ${result.totalCount} transaksi',
          style: TextStyle(
              fontSize: 12, color: DashboardTheme.textSecondary),
        ),
        const Spacer(),

        // Page size picker
        DropdownButton<int>(
          value: result.pageSize,
          underline: const SizedBox.shrink(),
          items: [25, 50, 100].map((s) {
            return DropdownMenuItem(
                value: s,
                child: Text('$s per halaman',
                    style: const TextStyle(fontSize: 12)));
          }).toList(),
          onChanged: (v) {
            if (v != null) onPageSizeChange(v);
          },
        ),
        const SizedBox(width: 16),

        // Prev
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          iconSize: 18,
          onPressed: result.hasPrevPage
              ? () => onPageChange(result.page - 1)
              : null,
        ),
        Text(
          '${result.page + 1} / ${result.totalPages}',
          style: const TextStyle(fontSize: 12),
        ),
        // Next
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded),
          iconSize: 18,
          onPressed: result.hasNextPage
              ? () => onPageChange(result.page + 1)
              : null,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Skeleton
// ---------------------------------------------------------------------------

class _SalesTableSkeleton extends StatelessWidget {
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
            child: const Row(
              children: [
                SkeletonBox(width: 80, height: 12),
                SizedBox(width: 16),
                Expanded(child: SkeletonBox(width: 100, height: 12)),
              ],
            ),
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
