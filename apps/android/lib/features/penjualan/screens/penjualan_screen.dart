import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../features/product/data/models/product_category.dart';
import '../../../features/product/data/repositories/product_repository.dart';
import '../../../features/product/providers/product_providers.dart';
import '../../../shared/providers/database_providers.dart';
import '../../../shared/widgets/category_chip_bar.dart';
import '../../../shared/widgets/currency_input_field.dart';
import '../../../shared/widgets/frequently_sold_section.dart';
import '../../../shared/widgets/product_tile.dart';
import '../../../shared/widgets/quantity_button.dart';
import '../../../shared/widgets/recent_products_section.dart';
import '../../../shared/widgets/summary_row.dart';
import '../../../shared/widgets/transaction_footer.dart';
import '../models/cart_item.dart';
import '../providers/discovery_providers.dart';
import '../providers/penjualan_providers.dart';

class PenjualanScreen extends ConsumerStatefulWidget {
  const PenjualanScreen({super.key});

  @override
  ConsumerState<PenjualanScreen> createState() =>
      _PenjualanScreenState();
}

class _PenjualanScreenState extends ConsumerState<PenjualanScreen> {
  final _searchController = TextEditingController();
  final _paymentController = TextEditingController();
  String _searchQuery = '';
  ProductCategory? _selectedCategory;

  bool get _isSearching => _searchQuery.isNotEmpty;

  @override
  void dispose() {
    _searchController.dispose();
    _paymentController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) =>
      setState(() => _searchQuery = value.trim().toLowerCase());

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  void _addToCart(CartItem item) {
    ref.read(penjualanProvider.notifier).addProduct(item);
  }

  /// Handles a product tap from any discovery section or search results.
  ///
  /// - 0 selling options: adds product directly using legacy price/unit.
  /// - 1 selling option: adds that option immediately. No popup.
  /// - 2+ selling options: shows a bottom sheet for the operator to choose.
  Future<void> _handleProductTap(Product product) async {
    final repo = ref.read(productRepositoryProvider);
    final options = await repo.getSellingOptions(product.id);

    if (!mounted) return;

    if (options.isEmpty) {
      // Legacy product — no options configured. Add directly.
      _addToCart(CartItem(
        productId: product.id,
        productName: product.name,
        sellingPrice: product.sellPrice,
        quantity: 1,
        currentStock: product.currentStock,
        inventoryUnit: product.inventoryUnit,
        inventoryQuantityPerUnit: 1,
      ));
      return;
    }

    if (options.length == 1) {
      // Single option — add immediately with no popup.
      final o = options.first;
      _addToCart(CartItem(
        productId: product.id,
        productName: product.name,
        sellingPrice: o.sellingPrice,
        quantity: 1,
        currentStock: product.currentStock,
        inventoryUnit: product.inventoryUnit,
        inventoryQuantityPerUnit: o.quantity,
        sellingOptionId: o.id,
        displayName: o.displayName,
      ));
      return;
    }

    // Multiple options — show bottom sheet.
    await _showSellingOptionsSheet(product, options);
  }

  Future<void> _showSellingOptionsSheet(
    Product product,
    List<ProductSellingOption> options,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SellingOptionsSheet(
        product: product,
        options: options,
        onOptionSelected: (cartItem) {
          Navigator.of(ctx).pop();
          _addToCart(cartItem);
        },
      ),
    );
  }

  Future<void> _finishTransaction() async {
    final success =
        await ref.read(transactionSaveProvider.notifier).save();
    if (!mounted) return;
    if (success) {
      ref.read(penjualanProvider.notifier).clear();
      _paymentController.clear();
      ref.read(transactionSaveProvider.notifier).build();
      // Invalidate discovery providers so they refresh next time
      ref.invalidate(frequentlySoldProvider);
      ref.invalidate(recentlySoldProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Transaksi berhasil disimpan.',
              style: TextStyle(fontSize: 15)),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      final error = ref.read(transactionSaveProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan: $error',
              style: const TextStyle(fontSize: 14)),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cart = ref.watch(penjualanProvider);
    final saveState = ref.watch(transactionSaveProvider);

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
              child: Icon(Icons.calculate_rounded,
                  size: 18, color: colorScheme.primary),
            ),
            const SizedBox(width: 10),
            const Text(
              'Hitung Penjualan',
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
          if (cart.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () {
                  ref.read(penjualanProvider.notifier).clear();
                  _paymentController.clear();
                },
                icon: const Icon(Icons.delete_sweep_rounded,
                    size: 18),
                label: const Text('Bersihkan'),
                style: TextButton.styleFrom(
                    foregroundColor: Colors.red[600]),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Cart area — only shown when cart has items
          if (cart.items.isNotEmpty)
            _CartArea(
              items: cart.items,
              onIncrement: (id) => ref
                  .read(penjualanProvider.notifier)
                  .incrementQuantity(id),
              onDecrement: (id) => ref
                  .read(penjualanProvider.notifier)
                  .decrementQuantity(id),
              onRemove: (id) => ref
                  .read(penjualanProvider.notifier)
                  .removeItem(id),
            ),

          // Discovery / search area
          Expanded(
            child: _isSearching
                ? _SearchResultsView(
                    query: _searchQuery,
                    cartItems: cart.items,
                    onProductTap: _handleProductTap,
                    searchController: _searchController,
                    onSearchChanged: _onSearchChanged,
                    onClear: _clearSearch,
                  )
                : _DiscoveryView(
                    cartItems: cart.items,
                    selectedCategory: _selectedCategory,
                    onProductTap: _handleProductTap,
                    onCategorySelected: (cat) =>
                        setState(() => _selectedCategory = cat),
                    searchController: _searchController,
                    onSearchChanged: _onSearchChanged,
                    onClear: _clearSearch,
                  ),
          ),

          // Bottom summary — always pinned
          _BottomSummary(
            cart: cart,
            paymentController: _paymentController,
            isSaving: saveState.isLoading,
            onPaymentChanged: (value) {
              final amount = int.tryParse(value) ?? 0;
              ref
                  .read(penjualanProvider.notifier)
                  .setAmountPaid(amount);
            },
            onFinish: _finishTransaction,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cart area — compact horizontal-scroll list of items in cart
// ---------------------------------------------------------------------------

class _CartArea extends StatelessWidget {
  const _CartArea({
    required this.items,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  final List<CartItem> items;
  final void Function(String) onIncrement;
  final void Function(String) onDecrement;
  final void Function(String) onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
      constraints: const BoxConstraints(maxHeight: 200),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6F4),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          CurrencyFormatter.format(
                              item.sellingPrice),
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      QuantityButton(
                          icon: Icons.remove,
                          onPressed: () =>
                              onDecrement(item.productId)),
                      SizedBox(
                        width: 32,
                        child: Text(
                          '${item.quantity}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      QuantityButton(
                          icon: Icons.add,
                          onPressed: () =>
                              onIncrement(item.productId)),
                    ],
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 72,
                    child: Text(
                      CurrencyFormatter.format(item.subtotal),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => onRemove(item.productId),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.close_rounded,
                          size: 16, color: Colors.grey[400]),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Discovery view — shown when search is empty
// ---------------------------------------------------------------------------

class _DiscoveryView extends ConsumerWidget {
  const _DiscoveryView({
    required this.cartItems,
    required this.selectedCategory,
    required this.onProductTap,
    required this.onCategorySelected,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClear,
  });

  final List<CartItem> cartItems;
  final ProductCategory? selectedCategory;
  final Future<void> Function(Product) onProductTap;
  final void Function(ProductCategory?) onCategorySelected;
  final TextEditingController searchController;
  final void Function(String) onSearchChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return CustomScrollView(
      slivers: [
        // Search field
        SliverToBoxAdapter(
          child: _SearchField(
            controller: searchController,
            onChanged: onSearchChanged,
            onClear: onClear,
          ),
        ),

        // Section: Pilih Kategori — right under search
        SliverToBoxAdapter(
          child: _SectionHeader(
            title: 'Pilih Kategori',
            subtitle: 'Jelajahi per kategori',
            icon: Icons.grid_view_rounded,
            iconColor: Colors.purple[400]!,
          ),
        ),
        SliverToBoxAdapter(
          child: CategoryChipBar(
            selected: selectedCategory,
            onCategorySelected: onCategorySelected,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 4)),

        // Category product list — shown when a category is selected
        if (selectedCategory != null) ...[
          _CategoryProductList(
            category: selectedCategory!,
            cartItems: cartItems,
            onProductTap: onProductTap,
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
        ],

        // Section: Sering Dijual
        SliverToBoxAdapter(
          child: _SectionHeader(
            title: 'Sering Dijual',
            subtitle: '30 hari terakhir',
            icon: Icons.trending_up_rounded,
            iconColor: colorScheme.primary,
          ),
        ),
        SliverToBoxAdapter(
          child: FrequentlySoldSection(
            onProductTap: onProductTap,
            cartItems: cartItems,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // Section: Terakhir Dijual
        SliverToBoxAdapter(
          child: _SectionHeader(
            title: 'Terakhir Dijual',
            subtitle: 'Paling baru dulu',
            icon: Icons.history_rounded,
            iconColor: Colors.orange[600]!,
          ),
        ),
        SliverToBoxAdapter(
          child: RecentProductsSection(
            onProductTap: onProductTap,
            cartItems: cartItems,
          ),
        ),

        // Bottom padding
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Search results view — replaces discovery when typing
// ---------------------------------------------------------------------------

class _SearchResultsView extends ConsumerWidget {
  const _SearchResultsView({
    required this.query,
    required this.cartItems,
    required this.onProductTap,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClear,
  });

  final String query;
  final List<CartItem> cartItems;
  final Future<void> Function(Product) onProductTap;
  final TextEditingController searchController;
  final void Function(String) onSearchChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use all products stream
    final productsAsync =
        ref.watch(productListProvider);

    return Column(
      children: [
        _SearchField(
          controller: searchController,
          onChanged: onSearchChanged,
          onClear: onClear,
          autofocus: false,
        ),
        Expanded(
          child: productsAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator()),
            error: (e, _) =>
                Center(child: Text('Error: $e')),
            data: (products) {
              final filtered = products
                  .where((p) =>
                      p.name.toLowerCase().contains(query))
                  .toList();

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
                          'Produk "$query" tidak ditemukan.',
                          style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[500]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding:
                    const EdgeInsets.fromLTRB(16, 8, 16, 8),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final product = filtered[index];
                  final cartItem = cartItems.firstWhere(
                    (c) => c.productId == product.id,
                    orElse: () => CartItem(
                      productId: '',
                      productName: '',
                      sellingPrice: 0,
                      quantity: 0,
                      currentStock: 0,
                      inventoryUnit: 'pcs',
                      inventoryQuantityPerUnit: 1,
                    ),
                  );
                  final inCart = cartItem.productId.isNotEmpty;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ProductTile(
                      product: product,
                      inCart: inCart,
                      cartQuantity: inCart
                          ? cartItem.quantity
                          : 0,
                      onTap: () => onProductTap(product),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Category product list (Sliver)
// ---------------------------------------------------------------------------

class _CategoryProductList extends ConsumerWidget {
  const _CategoryProductList({
    required this.category,
    required this.cartItems,
    required this.onProductTap,
  });

  final ProductCategory category;
  final List<CartItem> cartItems;
  final Future<void> Function(Product) onProductTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync =
        ref.watch(productsByCategoryProvider(category.value));

    return productsAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => const SliverToBoxAdapter(
          child: SizedBox.shrink()),
      data: (products) {
        if (products.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 16),
              child: Text(
                'Tidak ada produk pada kategori ini.',
                style: TextStyle(
                    fontSize: 14, color: Colors.grey[500]),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final product = products[index];
                final cartItem = cartItems.firstWhere(
                  (c) => c.productId == product.id,
                  orElse: () => CartItem(
                    productId: '',
                    productName: '',
                    sellingPrice: 0,
                    quantity: 0,
                    currentStock: 0,
                    inventoryUnit: 'pcs',
                    inventoryQuantityPerUnit: 1,
                  ),
                );
                final inCart = cartItem.productId.isNotEmpty;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ProductTile(
                    product: product,
                    inCart: inCart,
                    cartQuantity:
                        inCart ? cartItem.quantity : 0,
                    onTap: () => onProductTap(product),
                  ),
                );
              },
              childCount: products.length,
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Shared small widgets
// ---------------------------------------------------------------------------

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final void Function(String) onChanged;
  final VoidCallback onClear;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasQuery = controller.text.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        autofocus: autofocus,
        decoration: InputDecoration(
          hintText: 'Cari produk...',
          hintStyle:
              TextStyle(color: Colors.grey[400], fontSize: 15),
          prefixIcon: Icon(Icons.search_rounded,
              color: Colors.grey[400]),
          suffixIcon: hasQuery
              ? IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: Colors.grey[400]),
                  onPressed: onClear,
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
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            subtitle,
            style: TextStyle(
                fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom summary — unchanged business logic
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
    final isInsufficient = cart.items.isNotEmpty &&
        cart.amountPaid > 0 &&
        !cart.canFinish;

    return TransactionFooter(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SummaryRow(
            label: 'Total',
            value: CurrencyFormatter.format(cart.totalAmount),
            isTotal: true,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const SizedBox(
                width: 110,
                child:
                    Text('Bayar', style: TextStyle(fontSize: 16)),
              ),
              Expanded(
                child: CurrencyInputField(
                  controller: paymentController,
                  onChanged: onPaymentChanged,
                  errorText:
                      isInsufficient ? 'Pembayaran kurang' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SummaryRow(
            label: 'Kembalian',
            value: cart.amountPaid >= cart.totalAmount
                ? CurrencyFormatter.format(cart.changeAmount)
                : '-',
          ),
          const SizedBox(height: 14),
          FooterActionButton(
            label: 'Selesaikan Transaksi',
            onPressed: () async => onFinish(),
            isSaving: isSaving,
            enabled: cart.canFinish,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Selling options bottom sheet
// ---------------------------------------------------------------------------

class _SellingOptionsSheet extends ConsumerStatefulWidget {
  const _SellingOptionsSheet({
    required this.product,
    required this.options,
    required this.onOptionSelected,
  });

  final Product product;
  final List<ProductSellingOption> options;
  final void Function(CartItem) onOptionSelected;

  @override
  ConsumerState<_SellingOptionsSheet> createState() =>
      _SellingOptionsSheetState();
}

class _SellingOptionsSheetState
    extends ConsumerState<_SellingOptionsSheet> {
  int? _selectedIndex;
  final _priceController = TextEditingController();

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Product name
          Text(
            widget.product.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pilih ukuran / opsi jual',
            style:
                TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
          const SizedBox(height: 16),

          // Options list
          ...widget.options.asMap().entries.map((entry) {
            final i = entry.key;
            final option = entry.value;
            final isSelected = _selectedIndex == i;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedIndex = i;
                    _priceController.text =
                        option.sellingPrice.toString();
                  });

                  // If product does NOT allow manual price,
                  // add to cart immediately on tap.
                  if (!widget.product.allowManualPrice) {
                    widget.onOptionSelected(CartItem(
                      productId: widget.product.id,
                      productName: widget.product.name,
                      sellingPrice: option.sellingPrice,
                      quantity: 1,
                      currentStock: widget.product.currentStock,
                      inventoryUnit: widget.product.inventoryUnit,
                      inventoryQuantityPerUnit: option.quantity,
                      sellingOptionId: option.id,
                      displayName: option.displayName,
                    ));
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary.withAlpha(12)
                        : const Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : Colors.grey[200]!,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: isSelected
                            ? colorScheme.primary
                            : Colors.grey[400],
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          option.displayName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(option.sellingPrice),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          // Manual price editor — only shown when allowManualPrice = true
          // and an option is selected
          if (widget.product.allowManualPrice &&
              _selectedIndex != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.edit_rounded,
                          size: 14, color: Colors.orange[700]),
                      const SizedBox(width: 6),
                      Text(
                        'Harga bisa diubah',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly
                    ],
                    decoration: InputDecoration(
                      prefixText: 'Rp ',
                      prefixStyle: TextStyle(
                          color: Colors.grey[700], fontSize: 16),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: Colors.orange[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: Colors.orange[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: Colors.orange[600]!, width: 1.5),
                      ),
                    ),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        final option =
                            widget.options[_selectedIndex!];
                        final price = int.tryParse(
                                _priceController.text.trim()) ??
                            option.sellingPrice;
                        widget.onOptionSelected(CartItem(
                          productId: widget.product.id,
                          productName: widget.product.name,
                          sellingPrice: price,
                          quantity: 1,
                          currentStock:
                              widget.product.currentStock,
                          inventoryUnit:
                              widget.product.inventoryUnit,
                          inventoryQuantityPerUnit: option.quantity,
                          sellingOptionId: option.id,
                          displayName: option.displayName,
                        ));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Tambah ke Keranjang',
                          style: TextStyle(fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
