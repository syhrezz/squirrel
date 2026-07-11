import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/shared_widgets.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../theme/dashboard_theme.dart';
import '../models/product_models.dart';
import '../providers/product_providers.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() =>
      _ProductsScreenState();
}

class _ProductsScreenState
    extends ConsumerState<ProductsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(productFilterProvider);
    final productsAsync = ref.watch(productsPageProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
          child: Row(
            children: [
              const Expanded(
                child: PageHeader(
                  title: 'Products',
                  subtitle:
                      'Lihat dan analisis seluruh produk warung.',
                ),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    ref.invalidate(productsPageProvider),
                icon: const Icon(Icons.refresh_rounded,
                    size: 14),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 32),
          child: _ProductFilterToolbar(
            filter: filter,
            searchController: _searchController,
            onFilterChanged: (f) =>
                ref.read(productFilterProvider.notifier).state =
                    f,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 32),
            child: productsAsync.when(
              loading: () => _ProductTableSkeleton(),
              error: (e, _) {
                if (e.toString().contains('debounced')) {
                  return _ProductTableSkeleton();
                }
                return ErrorView(
                  message: e.toString(),
                  onRetry: () =>
                      ref.invalidate(productsPageProvider),
                );
              },
              data: (result) => _ProductTable(
                result: result,
                filter: filter,
                onSort: (f) => ref
                    .read(productFilterProvider.notifier)
                    .setSort(f),
                onPageChange: (p) => ref
                    .read(productFilterProvider.notifier)
                    .setPage(p),
                onPageSizeChange: (s) => ref
                    .read(productFilterProvider.notifier)
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
// Filter toolbar
// ---------------------------------------------------------------------------

class _ProductFilterToolbar extends StatelessWidget {
  const _ProductFilterToolbar({
    required this.filter,
    required this.searchController,
    required this.onFilterChanged,
  });

  final ProductFilter filter;
  final TextEditingController searchController;
  final void Function(ProductFilter) onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DashboardTheme.surface,
        borderRadius:
            BorderRadius.circular(DashboardTheme.radius8),
        border: Border.all(color: DashboardTheme.border),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Search
          SizedBox(
            width: 240,
            height: 36,
            child: TextField(
              controller: searchController,
              onChanged: (v) => onFilterChanged(
                  filter.copyWith(search: v.trim(), page: 0)),
              decoration: InputDecoration(
                hintText: 'Cari produk...',
                prefixIcon: Icon(Icons.search_rounded,
                    size: 16,
                    color: DashboardTheme.textTertiary),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12),
                filled: true,
                fillColor: DashboardTheme.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide:
                      BorderSide(color: DashboardTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide:
                      BorderSide(color: DashboardTheme.border),
                ),
              ),
            ),
          ),

          // Status filter
          _FilterDropdown<ProductStatusFilter>(
            value: filter.status,
            items: const {
              ProductStatusFilter.all: 'Semua Status',
              ProductStatusFilter.active: 'Aktif',
              ProductStatusFilter.inactive: 'Nonaktif',
            },
            onChanged: (v) => onFilterChanged(
                filter.copyWith(status: v, page: 0)),
          ),

          // Stock filter
          _FilterDropdown<ProductStockFilter>(
            value: filter.stockFilter,
            items: const {
              ProductStockFilter.all: 'Semua Stok',
              ProductStockFilter.lowStock: 'Stok Rendah',
              ProductStockFilter.outOfStock: 'Habis',
            },
            onChanged: (v) => onFilterChanged(
                filter.copyWith(stockFilter: v, page: 0)),
          ),

          // Reset
          if (filter.hasActiveFilters)
            TextButton.icon(
              onPressed: () {
                searchController.clear();
                onFilterChanged(const ProductFilter());
              },
              icon: const Icon(Icons.close_rounded, size: 14),
              label: const Text('Reset'),
              style: TextButton.styleFrom(
                  foregroundColor: DashboardTheme.danger),
            ),
        ],
      ),
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final T value;
  final Map<T, String> items;
  final void Function(T) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: DashboardTheme.bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: DashboardTheme.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          style: TextStyle(
              fontSize: 12,
              color: DashboardTheme.textPrimary),
          items: items.entries
              .map((e) => DropdownMenuItem<T>(
                  value: e.key,
                  child: Text(e.value,
                      style: const TextStyle(fontSize: 12))))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Product table
// ---------------------------------------------------------------------------

class _ProductTable extends StatelessWidget {
  const _ProductTable({
    required this.result,
    required this.filter,
    required this.onSort,
    required this.onPageChange,
    required this.onPageSizeChange,
  });

  final ProductPageResult result;
  final ProductFilter filter;
  final void Function(ProductSortField) onSort;
  final void Function(int) onPageChange;
  final void Function(int) onPageSizeChange;

  @override
  Widget build(BuildContext context) {
    if (result.items.isEmpty) {
      return SectionCard(
        child: EmptyState(
          title: 'Tidak ada produk',
          description:
              'Tidak ada produk yang sesuai dengan filter.',
          icon: Icons.inventory_2_rounded,
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
                _ProductTableHeader(
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
                      return _ProductRow(
                        item: item,
                        onTap: () => context
                            .go('/products/${item.id}'),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _ProductPagination(
          result: result,
          onPageChange: onPageChange,
          onPageSizeChange: onPageSizeChange,
        ),
      ],
    );
  }
}

class _ProductTableHeader extends StatelessWidget {
  const _ProductTableHeader(
      {required this.filter, required this.onSort});

  final ProductFilter filter;
  final void Function(ProductSortField) onSort;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 10),
      color: DashboardTheme.bg,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _SortableHeader(
              label: 'Produk',
              field: ProductSortField.name,
              currentField: filter.sortField,
              ascending: filter.sortAscending,
              onSort: onSort,
            ),
          ),
          const SizedBox(
            width: 100,
            child: Text('Kategori',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280))),
          ),
          _SortableHeader(
            label: 'Stok',
            field: ProductSortField.stock,
            currentField: filter.sortField,
            ascending: filter.sortAscending,
            onSort: onSort,
            width: 90,
          ),
          const SizedBox(
            width: 80,
            child: Text('Unit',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280))),
          ),
          _SortableHeader(
            label: 'Harga Jual',
            field: ProductSortField.sellPrice,
            currentField: filter.sortField,
            ascending: filter.sortAscending,
            onSort: onSort,
            width: 110,
            textAlign: TextAlign.right,
          ),
          const SizedBox(
            width: 110,
            child: Text('Harga Beli',
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280))),
          ),
          const SizedBox(
            width: 80,
            child: Text('Status',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280))),
          ),
        ],
      ),
    );
  }
}

class _SortableHeader extends StatelessWidget {
  const _SortableHeader({
    required this.label,
    required this.field,
    required this.currentField,
    required this.ascending,
    required this.onSort,
    this.width,
    this.textAlign = TextAlign.left,
  });

  final String label;
  final ProductSortField field;
  final ProductSortField currentField;
  final bool ascending;
  final void Function(ProductSortField) onSort;
  final double? width;
  final TextAlign textAlign;

  bool get isActive => currentField == field;

  Widget _build() => InkWell(
        onTap: () => onSort(field),
        child: Row(
          mainAxisAlignment: textAlign == TextAlign.right
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? DashboardTheme.primary
                        : DashboardTheme.textSecondary)),
            const SizedBox(width: 4),
            Icon(
              isActive
                  ? (ascending
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded)
                  : Icons.unfold_more_rounded,
              size: 12,
              color: isActive
                  ? DashboardTheme.primary
                  : DashboardTheme.textTertiary,
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (width != null) return SizedBox(width: width, child: _build());
    return Expanded(child: _build());
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.item, required this.onTap});

  final ProductExplorerItem item;
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
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis),
                    Text(item.formattedUpdatedAt,
                        style: TextStyle(
                            fontSize: 11,
                            color: DashboardTheme.textTertiary)),
                  ],
                ),
              ),
              SizedBox(
                width: 100,
                child: Text(item.category,
                    style: TextStyle(
                        fontSize: 12,
                        color: DashboardTheme.textSecondary),
                    overflow: TextOverflow.ellipsis),
              ),
              SizedBox(
                width: 90,
                child: Row(
                  children: [
                    Text(item.stockLabel,
                        style: TextStyle(
                          fontSize: 13,
                          color: item.isOutOfStock
                              ? DashboardTheme.danger
                              : item.isLowStock
                                  ? DashboardTheme.warning
                                  : DashboardTheme.textPrimary,
                          fontWeight: (item.isLowStock ||
                                  item.isOutOfStock)
                              ? FontWeight.w600
                              : FontWeight.normal,
                        )),
                    if (item.isOutOfStock || item.isLowStock) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 12,
                        color: item.isOutOfStock
                            ? DashboardTheme.danger
                            : DashboardTheme.warning,
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(
                width: 80,
                child: Text(item.inventoryUnit,
                    style: TextStyle(
                        fontSize: 12,
                        color: DashboardTheme.textSecondary)),
              ),
              SizedBox(
                width: 110,
                child: Text(item.formattedSellPrice,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
              ),
              SizedBox(
                width: 110,
                child: Text(item.formattedBuyPrice,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: 12,
                        color: DashboardTheme.textSecondary)),
              ),
              SizedBox(
                width: 80,
                child: StatusChip(
                  label: item.isActive ? 'Aktif' : 'Nonaktif',
                  color: item.isActive
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

class _ProductPagination extends StatelessWidget {
  const _ProductPagination({
    required this.result,
    required this.onPageChange,
    required this.onPageSizeChange,
  });

  final ProductPageResult result;
  final void Function(int) onPageChange;
  final void Function(int) onPageSizeChange;

  @override
  Widget build(BuildContext context) {
    final start = result.page * result.pageSize + 1;
    final end = (start + result.pageSize - 1)
        .clamp(1, result.totalCount);
    return Row(
      children: [
        Text(
          '$start–$end dari ${result.totalCount} produk',
          style: TextStyle(
              fontSize: 12,
              color: DashboardTheme.textSecondary),
        ),
        const Spacer(),
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
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          iconSize: 18,
          onPressed: result.hasPrevPage
              ? () => onPageChange(result.page - 1)
              : null,
        ),
        Text('${result.page + 1} / ${result.totalPages}',
            style: const TextStyle(fontSize: 12)),
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

class _ProductTableSkeleton extends StatelessWidget {
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
            child: const Row(
              children: [
                SkeletonBox(width: 80, height: 12),
                SizedBox(width: 16),
                Expanded(
                    child:
                        SkeletonBox(width: 100, height: 12)),
              ],
            ),
          ),
          Divider(height: 1, color: DashboardTheme.border),
          ...List.generate(
            8,
            (_) => Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: TableRowSkeleton(),
                ),
                Divider(
                    height: 1,
                    color: DashboardTheme.borderLight),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
