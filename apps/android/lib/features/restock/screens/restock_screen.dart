import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../features/product/providers/product_providers.dart';
import '../../../shared/widgets/currency_input_field.dart';
import '../../../shared/widgets/product_search_field.dart';
import '../../../shared/widgets/quantity_button.dart';
import '../../../shared/widgets/summary_row.dart';
import '../../../shared/widgets/transaction_footer.dart';
import '../models/shopping_item.dart';
import '../providers/restock_providers.dart';

/// Belanja / Restock Barang screen.
///
/// Records one shopping trip after returning from the wholesaler.
/// The mental model is "I just finished shopping" not "I am updating inventory".
///
/// Layout:
///   AppBar (Belanja / Restock)
///   SearchField      ← shared ProductSearchField
///   SearchResults (shown only while search query is non-empty)
///   OR
///   ShoppingList (shown when search is empty)
///   BottomSummary    ← shared TransactionFooter + SummaryRow + FooterActionButton
class RestockScreen extends ConsumerStatefulWidget {
  const RestockScreen({super.key});

  @override
  ConsumerState<RestockScreen> createState() => _RestockScreenState();
}

class _RestockScreenState extends ConsumerState<RestockScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value.trim().toLowerCase());
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  Future<void> _save() async {
    final success = await ref.read(restockSaveProvider.notifier).save();
    if (!mounted) return;

    if (success) {
      ref.read(restockProvider.notifier).clear();
      ref.read(restockSaveProvider.notifier).build();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Belanja berhasil disimpan.',
            style: TextStyle(fontSize: 16),
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      final error = ref.read(restockSaveProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menyimpan: $error',
            style: const TextStyle(fontSize: 14),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopping = ref.watch(restockProvider);
    final saveState = ref.watch(restockSaveProvider);
    final productsAsync = ref.watch(productListProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        title: const Text('Belanja / Restock'),
      ),
      body: Column(
        children: [
          // Shared search field widget
          ProductSearchField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            onClear: _clearSearch,
            hasQuery: _searchQuery.isNotEmpty,
          ),

          // Main content: search results OR shopping list
          Expanded(
            child: _searchQuery.isNotEmpty
                ? _SearchResults(
                    query: _searchQuery,
                    productsAsync: productsAsync,
                    shoppingItems: shopping.items,
                    onProductTap: (item) {
                      ref.read(restockProvider.notifier).addProduct(item);
                      _clearSearch();
                    },
                  )
                : _ShoppingList(
                    items: shopping.items,
                    onIncrement: (id) =>
                        ref.read(restockProvider.notifier).incrementQuantity(id),
                    onDecrement: (id) =>
                        ref.read(restockProvider.notifier).decrementQuantity(id),
                    onRemove: (id) =>
                        ref.read(restockProvider.notifier).removeItem(id),
                    onQuantityChanged: (id, qty) =>
                        ref.read(restockProvider.notifier).setQuantity(id, qty),
                    onPriceChanged: (id, price) =>
                        ref.read(restockProvider.notifier).setPurchasePrice(id, price),
                  ),
          ),

          // Pinned bottom summary — shared TransactionFooter
          TransactionFooter(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Shared SummaryRow for total
                SummaryRow(
                  label: 'Total Belanja',
                  value: CurrencyFormatter.format(shopping.totalAmount),
                  isTotal: true,
                ),
                const SizedBox(height: 14),

                // Shared FooterActionButton
                FooterActionButton(
                  label: 'Simpan Belanja',
                  onPressed: _save,
                  isSaving: saveState.isLoading,
                  enabled: shopping.canSave,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Search Results
// ---------------------------------------------------------------------------

class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.query,
    required this.productsAsync,
    required this.shoppingItems,
    required this.onProductTap,
  });

  final String query;
  final AsyncValue productsAsync;
  final List<ShoppingItem> shoppingItems;
  final void Function(ShoppingItem) onProductTap;

  @override
  Widget build(BuildContext context) {
    return productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (products) {
        final filtered = products
            .where((p) => p.isActive && p.name.toLowerCase().contains(query))
            .toList();

        if (filtered.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Produk "$query" tidak ditemukan.',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: filtered.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final product = filtered[index];
            final alreadyAdded =
                shoppingItems.any((i) => i.productId == product.id);
            final unitDisplay = product.unit == 'lainnya' &&
                    product.customUnit != null
                ? product.customUnit!
                : product.unit;

            return ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              title: Text(
                product.name,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                'Stok: ${product.currentStock}  •  $unitDisplay',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Beli: ${CurrencyFormatter.format(product.lastBuyPrice)}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    alreadyAdded
                        ? Icons.check_circle
                        : Icons.add_circle_outline,
                    color: alreadyAdded
                        ? Colors.green
                        : Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                ],
              ),
              onTap: alreadyAdded
                  ? null
                  : () => onProductTap(
                        ShoppingItem(
                          productId: product.id,
                          productName: product.name,
                          unit: product.unit,
                          customUnit: product.customUnit,
                          quantity: 1,
                          purchasePrice: product.lastBuyPrice,
                        ),
                      ),
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Shopping List
// ---------------------------------------------------------------------------

class _ShoppingList extends StatelessWidget {
  const _ShoppingList({
    required this.items,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    required this.onQuantityChanged,
    required this.onPriceChanged,
  });

  final List<ShoppingItem> items;
  final void Function(String) onIncrement;
  final void Function(String) onDecrement;
  final void Function(String) onRemove;
  final void Function(String, int) onQuantityChanged;
  final void Function(String, int) onPriceChanged;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Belum ada produk ditambahkan',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'Gunakan pencarian di atas untuk menambahkan produk yang dibeli.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
      itemCount: items.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        return _ShoppingItemRow(
          item: item,
          onIncrement: () => onIncrement(item.productId),
          onDecrement: () => onDecrement(item.productId),
          onRemove: () => onRemove(item.productId),
          onQuantityChanged: (qty) => onQuantityChanged(item.productId, qty),
          onPriceChanged: (price) => onPriceChanged(item.productId, price),
        );
      },
    );
  }
}

class _ShoppingItemRow extends StatefulWidget {
  const _ShoppingItemRow({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    required this.onQuantityChanged,
    required this.onPriceChanged,
  });

  final ShoppingItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;
  final void Function(int) onQuantityChanged;
  final void Function(int) onPriceChanged;

  @override
  State<_ShoppingItemRow> createState() => _ShoppingItemRowState();
}

class _ShoppingItemRowState extends State<_ShoppingItemRow> {
  late TextEditingController _qtyController;
  late TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _qtyController =
        TextEditingController(text: widget.item.quantity.toString());
    _priceController =
        TextEditingController(text: widget.item.purchasePrice.toString());
  }

  @override
  void didUpdateWidget(_ShoppingItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync quantity field when +/- buttons are tapped
    if (oldWidget.item.quantity != widget.item.quantity) {
      final newText = widget.item.quantity.toString();
      if (_qtyController.text != newText) {
        _qtyController.text = newText;
      }
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isValid =
        widget.item.quantity > 0 && widget.item.purchasePrice > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: product name + remove button
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.item.productName,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: widget.onRemove,
                padding: const EdgeInsets.all(4),
                constraints:
                    const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Row 2: quantity controls + price field
          Row(
            children: [
              // Quantity
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jumlah (${widget.item.displayUnit})',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Shared QuantityButton (size 34 for compact row)
                        QuantityButton(
                          icon: Icons.remove,
                          onPressed: widget.onDecrement,
                          size: 34,
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 56,
                          child: TextField(
                            controller: _qtyController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 4),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (v) {
                              final n = int.tryParse(v) ?? 0;
                              widget.onQuantityChanged(n);
                            },
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Shared QuantityButton
                        QuantityButton(
                          icon: Icons.add,
                          onPressed: widget.onIncrement,
                          size: 34,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Purchase price — shared CurrencyInputField
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Harga Beli (Rp)',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    CurrencyInputField(
                      controller: _priceController,
                      onChanged: (v) {
                        final n = int.tryParse(v) ?? 0;
                        widget.onPriceChanged(n);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Row 3: subtotal
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              isValid
                  ? 'Subtotal: ${CurrencyFormatter.format(widget.item.subtotal)}'
                  : 'Subtotal: -',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isValid
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
