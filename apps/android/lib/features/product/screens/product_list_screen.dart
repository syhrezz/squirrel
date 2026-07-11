import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/error_retry.dart';
import '../providers/product_providers.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() =>
      _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showInactive = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final productsAsync = ref.watch(productListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colorScheme.primary.withAlpha(18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.inventory_2_rounded,
                  size: 18, color: colorScheme.primary),
            ),
            const SizedBox(width: 10),
            const Text(
              'Data Produk',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showInactive ? Icons.visibility_rounded : Icons.visibility_off_rounded,
              size: 22,
            ),
            tooltip: _showInactive ? 'Sembunyikan Nonaktif' : 'Tampilkan Nonaktif',
            onPressed: () =>
                setState(() => _showInactive = !_showInactive),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.add_rounded,
                    size: 20, color: colorScheme.primary),
              ),
              tooltip: 'Tambah Produk',
              onPressed: () => context.pushNamed('product-add'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) =>
                  setState(() => _searchQuery = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Cari produk...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
                prefixIcon:
                    Icon(Icons.search_rounded, color: Colors.grey[400]),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close_rounded,
                            color: Colors.grey[400]),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: colorScheme.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
            ),
          ),

          Expanded(
            child: productsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorRetry(
                onRetry: () => ref.invalidate(productListProvider),
              ),
              data: (products) {
                final filtered = products.where((p) {
                  final matchesSearch = _searchQuery.isEmpty ||
                      p.name
                          .toLowerCase()
                          .contains(_searchQuery);
                  final matchesActive =
                      _showInactive || p.isActive;
                  return matchesSearch && matchesActive;
                }).toList();

                if (products.isEmpty) {
                  return _EmptyState(
                    onAddTap: () =>
                        context.pushNamed('product-add'),
                  );
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded,
                              size: 56, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'Produk "$_searchQuery" tidak ditemukan.',
                            style: TextStyle(
                                fontSize: 15, color: Colors.grey[500]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding:
                      const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final product = filtered[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _ProductCard(
                        product: product,
                        onTap: () => context.pushNamed(
                          'product-edit',
                          pathParameters: {'id': product.id},
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onTap});

  final dynamic product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLowStock = product.currentStock <= 3;
    final isInactive = !product.isActive;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: isInactive
                        ? Colors.grey[100]
                        : colorScheme.primary.withAlpha(15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.inventory_2_rounded,
                    size: 22,
                    color: isInactive
                        ? Colors.grey[400]
                        : colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isInactive
                                    ? Colors.grey[400]
                                    : const Color(0xFF1A1A1A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isInactive)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Nonaktif',
                                style: TextStyle(
                                    fontSize: 10, color: Colors.grey[500]),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            'Stok: ${product.currentStock} ${product.unit}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isLowStock && !isInactive
                                  ? Colors.orange[600]
                                  : Colors.grey[500],
                              fontWeight: isLowStock && !isInactive
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          if (isLowStock && !isInactive) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.warning_amber_rounded,
                                size: 13, color: Colors.orange[500]),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.format(product.sellPrice),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isInactive
                            ? Colors.grey[400]
                            : colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Beli: ${CurrencyFormatter.format(product.lastBuyPrice)}',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey[400]),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded,
                    color: Colors.grey[300], size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAddTap});
  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.primary.withAlpha(12),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(Icons.inventory_2_outlined,
                  size: 40,
                  color: colorScheme.primary.withAlpha(100)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Belum ada produk',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tambahkan produk untuk mulai berjualan.',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onAddTap,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tambah Produk'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
