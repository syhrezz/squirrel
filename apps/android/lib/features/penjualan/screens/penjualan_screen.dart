import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../features/product/providers/product_providers.dart';
import '../../../shared/widgets/currency_input_field.dart';
import '../../../shared/widgets/product_search_field.dart';
import '../../../shared/widgets/quantity_button.dart';
import '../../../shared/widgets/summary_row.dart';
import '../../../shared/widgets/transaction_footer.dart';
import '../models/cart_item.dart';
import '../providers/penjualan_providers.dart';

/// Hitung Penjualan screen.
///
/// Replaces the physical calculator used at the shop counter.
/// Priority: speed, simplicity, zero confusion for the operator.
///
/// Layout:
///   AppBar
///   SearchField
///   SearchResults (shown only while search query is non-empty)
///   OR
///   TransactionList (shown when search is empty)
///   BottomSummary (always pinned)
class PenjualanScreen extends ConsumerStatefulWidget {
  const PenjualanScreen({super.key});

  @override
  ConsumerState<PenjualanScreen> createState() => _PenjualanScreenState();
}

class _PenjualanScreenState extends ConsumerState<PenjualanScreen> {
  final _searchController = TextEditingController();
  final _paymentController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _paymentController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value.trim().toLowerCase());
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  Future<void> _finishTransaction() async {
    final success = await ref.read(transactionSaveProvider.notifier).save();
    if (!mounted) return;
    if (success) {
      ref.read(penjualanProvider.notifier).clear();
      _paymentController.clear();
      ref.read(transactionSaveProvider.notifier).build();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Transaksi berhasil disimpan.',
            style: TextStyle(fontSize: 16),
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      final error = ref.read(transactionSaveProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menyimpan transaksi: $error',
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
    final cart = ref.watch(penjualanProvider);
    final saveState = ref.watch(transactionSaveProvider);
    final productsAsync = ref.watch(productListProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        title: const Text('Hitung Penjualan'),
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

          // Main content: search results OR transaction list
          Expanded(
            child: _searchQuery.isNotEmpty
                ? _SearchResults(
                    query: _searchQuery,
                    productsAsync: productsAsync,
                    cartItems: cart.items,
                    onProductTap: (item) {
                      ref.read(penjualanProvider.notifier).addProduct(item);
                      _clearSearch();
                    },
                  )
                : _TransactionList(
                    items: cart.items,
                    onIncrement: (id) =>
                        ref.read(penjualanProvider.notifier).incrementQuantity(id),
                    onDecrement: (id) =>
                        ref.read(penjualanProvider.notifier).decrementQuantity(id),
                    onRemove: (id) =>
                        ref.read(penjualanProvider.notifier).removeItem(id),
                  ),
          ),

          // Pinned bottom summary
          _BottomSummary(
            cart: cart,
            paymentController: _paymentController,
            isSaving: saveState.isLoading,
            onPaymentChanged: (value) {
              final amount = int.tryParse(value) ?? 0;
              ref.read(penjualanProvider.notifier).setAmountPaid(amount);
            },
            onFinish: _finishTransaction,
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
    required this.cartItems,
    required this.onProductTap,
  });

  final String query;
  final AsyncValue productsAsync;
  final List<CartItem> cartItems;
  final void Function(CartItem) onProductTap;

  @override
  Widget build(BuildContext context) {
    return productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (products) {
        final filtered = products.where((p) {
          return p.name.toLowerCase().contains(query);
        }).toList();

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
            final alreadyInCart =
                cartItems.any((i) => i.productId == product.id);

            return ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              title: Text(
                product.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'Stok: ${product.currentStock}',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    CurrencyFormatter.format(product.sellPrice),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    alreadyInCart ? Icons.add_circle : Icons.add_circle_outline,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                ],
              ),
              onTap: () => onProductTap(
                CartItem(
                  productId: product.id,
                  productName: product.name,
                  sellingPrice: product.sellPrice,
                  quantity: 1,
                  currentStock: product.currentStock,
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
// Transaction List
// ---------------------------------------------------------------------------

class _TransactionList extends StatelessWidget {
  const _TransactionList({
    required this.items,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  final List<CartItem> items;
  final void Function(String productId) onIncrement;
  final void Function(String productId) onDecrement;
  final void Function(String productId) onRemove;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Belum ada produk dipilih',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'Gunakan pencarian di atas untuk menambahkan produk.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        return _CartItemRow(
          item: item,
          onIncrement: () => onIncrement(item.productId),
          onDecrement: () => onDecrement(item.productId),
          onRemove: () => onRemove(item.productId),
        );
      },
    );
  }
}

class _CartItemRow extends StatelessWidget {
  const _CartItemRow({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Remove button
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: onRemove,
            tooltip: 'Hapus',
            iconSize: 24,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),

          // Product name + price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  CurrencyFormatter.format(item.sellingPrice),
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // Quantity controls — uses shared QuantityButton
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              QuantityButton(icon: Icons.remove, onPressed: onDecrement),
              SizedBox(
                width: 40,
                child: Text(
                  '${item.quantity}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              QuantityButton(icon: Icons.add, onPressed: onIncrement),
            ],
          ),

          const SizedBox(width: 8),

          // Subtotal
          SizedBox(
            width: 80,
            child: Text(
              CurrencyFormatter.format(item.subtotal),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom Summary
// ---------------------------------------------------------------------------

class _BottomSummary extends StatelessWidget {
  const _BottomSummary({
    required this.cart,
    required this.paymentController,
    required this.isSaving,
    required this.onPaymentChanged,
    required this.onFinish,
  });

  final CartState cart;
  final TextEditingController paymentController;
  final bool isSaving;
  final void Function(String) onPaymentChanged;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final isInsufficient =
        cart.items.isNotEmpty && cart.amountPaid > 0 && !cart.canFinish;

    // Uses shared TransactionFooter for the shadow + surface container
    return TransactionFooter(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Uses shared SummaryRow for total line
          SummaryRow(
            label: 'Total',
            value: CurrencyFormatter.format(cart.totalAmount),
            isTotal: true,
          ),
          const SizedBox(height: 10),

          // Customer payment — uses shared CurrencyInputField
          Row(
            children: [
              const SizedBox(
                width: 110,
                child: Text('Bayar', style: TextStyle(fontSize: 16)),
              ),
              Expanded(
                child: CurrencyInputField(
                  controller: paymentController,
                  onChanged: onPaymentChanged,
                  errorText: isInsufficient ? 'Pembayaran kurang' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Uses shared SummaryRow for change line
          SummaryRow(
            label: 'Kembalian',
            value: cart.amountPaid >= cart.totalAmount
                ? CurrencyFormatter.format(cart.changeAmount)
                : '-',
          ),
          const SizedBox(height: 14),

          // Uses shared FooterActionButton
          FooterActionButton(
            label: 'Selesaikan Transaksi',
            onPressed: _finishTransaction,
            isSaving: isSaving,
            enabled: cart.canFinish,
          ),
        ],
      ),
    );
  }

  // Exposed so FooterActionButton can call it
  Future<void> _finishTransaction() async => onFinish();
}
