import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/error_retry.dart';
import '../providers/product_providers.dart';

/// Product list screen — internal administration tooling.
///
/// This screen is NOT part of the operator daily workflow.
/// It allows administrators to manage product data.
///
/// Phase 3 improvements:
/// - Search bar with instant local filtering
/// - Unit and stock displayed on each row
/// - Nonaktif badge for inactive products (visible via admin toggle)
class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
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
    final productsAsync = ref.watch(productListProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        title: const Text('Data Produk'),
        actions: [
          // Toggle to show/hide inactive products
          IconButton(
            icon: Icon(
              _showInactive ? Icons.visibility : Icons.visibility_off,
              color: Colors.white,
            ),
            tooltip: _showInactive ? 'Sembunyikan Nonaktif' : 'Tampilkan Nonaktif',
            onPressed: () => setState(() => _showInactive = !_showInactive),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Tambah Produk',
            onPressed: () => context.pushNamed('product-add'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              controller: _searchController,
              onChanged: (v) =>
                  setState(() => _searchQuery = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Cari produk...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
              style: const TextStyle(fontSize: 16),
            ),
          ),

          // Product list
          Expanded(
            child: productsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorRetry(
                onRetry: () => ref.invalidate(productListProvider),
              ),
              data: (products) {
                // Apply inactive filter
                final visible = _showInactive
                    ? products
                    : products.where((p) => p.isActive).toList();

                // Apply search filter
                final filtered = _searchQuery.isEmpty
                    ? visible
                    : visible
                        .where((p) =>
                            p.name.toLowerCase().contains(_searchQuery))
                        .toList();

                if (filtered.isEmpty && products.isEmpty) {
                  return _EmptyProductList(
                    onAddTap: () => context.pushNamed('product-add'),
                  );
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Produk "$_searchQuery" tidak ditemukan.',
                        style: const TextStyle(
                            fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final product = filtered[index];
                    final unitDisplay =
                        product.unit == 'lainnya' &&
                                product.customUnit != null
                            ? product.customUnit!
                            : product.unit;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      title: Row(
                        children: [
                          Expanded(child: Text(product.name)),
                          if (!product.isActive)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Nonaktif',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(
                        'Satuan: $unitDisplay  •  Stok: ${product.currentStock}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            CurrencyFormatter.format(product.sellPrice),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            'Beli: ${CurrencyFormatter.format(product.lastBuyPrice)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      onTap: () => context.pushNamed(
                        'product-edit',
                        pathParameters: {'id': product.id},
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

class _EmptyProductList extends StatelessWidget {
  const _EmptyProductList({required this.onAddTap});

  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum ada produk.',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAddTap,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Produk'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 52),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
