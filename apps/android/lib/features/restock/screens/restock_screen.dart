import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../features/product/providers/product_providers.dart';
import '../../../shared/widgets/product_search_field.dart';
import '../../../shared/widgets/quantity_button.dart';
import '../../../shared/widgets/summary_row.dart';
import '../../../shared/widgets/transaction_footer.dart';
import '../models/shopping_item.dart';
import '../providers/restock_providers.dart';

// ---------------------------------------------------------------------------
// Thousand separator formatter (same as kasbon)
// ---------------------------------------------------------------------------

class _TF extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue o, TextEditingValue n) {
    final digits = n.text.replaceAll('.', '');
    if (digits.isEmpty) return n.copyWith(text: '');
    final buf = StringBuffer();
    final len = digits.length;
    for (var i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) buf.write('.');
      buf.write(digits[i]);
    }
    final s = buf.toString();
    return TextEditingValue(
        text: s, selection: TextSelection.collapsed(offset: s.length));
  }

  static int parse(String v) =>
      int.tryParse(v.replaceAll('.', '')) ?? 0;
}

// ---------------------------------------------------------------------------
// Main screen — shows history with FAB to add new restock
// ---------------------------------------------------------------------------

class RestockScreen extends ConsumerWidget {
  const RestockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final historyAsync = ref.watch(restockHistoryProvider);

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
              child: Icon(Icons.shopping_bag_rounded,
                  size: 18, color: colorScheme.primary),
            ),
            const SizedBox(width: 10),
            const Text(
              'Belanja Barang',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
      ),
      body: historyAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text('Error: $e')),
        data: (history) {
          if (history.isEmpty) {
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
                      child: Icon(Icons.shopping_bag_outlined,
                          size: 40,
                          color: colorScheme.primary.withAlpha(100)),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Belum ada riwayat belanja',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap tombol + untuk mencatat belanja.',
                      style: TextStyle(
                          fontSize: 14, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final entry = history[index];
              return _RestockHistoryCard(entry: entry);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddRestockSheet(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Catat Belanja'),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _openAddRestockSheet(BuildContext context, WidgetRef ref) {
    // Clear any previous session
    ref.read(restockProvider.notifier).clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddRestockSheet(),
    );
  }
}

// ---------------------------------------------------------------------------
// History card
// ---------------------------------------------------------------------------

class _RestockHistoryCard extends StatelessWidget {
  const _RestockHistoryCard({required this.entry});
  final RestockWithItems entry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dt = DateTime.fromMillisecondsSinceEpoch(
        entry.restock.createdAt);
    final dateStr =
        DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(dt);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context)
            .copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding:
              const EdgeInsets.fromLTRB(16, 0, 16, 12),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primary.withAlpha(15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.shopping_bag_rounded,
                size: 20, color: colorScheme.primary),
          ),
          title: Text(
            CurrencyFormatter.format(entry.restock.totalAmount),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colorScheme.primary,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dateStr,
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey[500])),
              Text(
                '${entry.items.length} produk',
                style: TextStyle(
                    fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
          children: [
            Divider(height: 1, color: Colors.grey[100]),
            const SizedBox(height: 8),
            // Items list
            ...entry.items.map((item) {
              final productName = item.productId; // will be replaced below
              return _RestockItemRow(item: item);
            }),
            const SizedBox(height: 4),
            // Total row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700])),
                Text(
                  CurrencyFormatter.format(entry.restock.totalAmount),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RestockItemRow extends ConsumerWidget {
  const _RestockItemRow({required this.item});
  final RestockItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync =
        ref.watch(productDetailProvider(item.productId));
    final name = productAsync.when(
      data: (p) => p?.name ?? item.productId.substring(0, 8),
      loading: () => '...',
      error: (_, __) => item.productId.substring(0, 8),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                Text(
                  '${item.quantity}× ${CurrencyFormatter.format(item.purchasePrice)}',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.format(item.subtotal),
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add Restock Bottom Sheet
// ---------------------------------------------------------------------------

class _AddRestockSheet extends ConsumerStatefulWidget {
  const _AddRestockSheet();

  @override
  ConsumerState<_AddRestockSheet> createState() =>
      _AddRestockSheetState();
}

class _AddRestockSheetState
    extends ConsumerState<_AddRestockSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final success =
        await ref.read(restockSaveProvider.notifier).save();
    if (!mounted) return;

    if (success) {
      ref.read(restockProvider.notifier).clear();
      ref.read(restockSaveProvider.notifier).build();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Belanja berhasil disimpan.',
              style: TextStyle(fontSize: 15)),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      final error = ref.read(restockSaveProvider).error;
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
    final shopping = ref.watch(restockProvider);
    final saveState = ref.watch(restockSaveProvider);
    final productsAsync = ref.watch(productListProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF4F6F4),
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle + header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Catat Belanja Baru',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (shopping.items.isNotEmpty)
                          TextButton.icon(
                            onPressed: () => ref
                                .read(restockProvider.notifier)
                                .clear(),
                            icon: const Icon(
                                Icons.delete_sweep_rounded,
                                size: 16),
                            label: const Text('Bersihkan'),
                            style: TextButton.styleFrom(
                                foregroundColor: Colors.red[600]),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Search
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: ProductSearchField(
                  controller: _searchController,
                  onChanged: (v) => setState(
                      () => _searchQuery = v.trim().toLowerCase()),
                  onClear: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  hasQuery: _searchQuery.isNotEmpty,
                ),
              ),

              // Content
              Expanded(
                child: _searchQuery.isNotEmpty
                    ? _SearchResults(
                        query: _searchQuery,
                        productsAsync: productsAsync,
                        onAdd: (item) {
                          ref
                              .read(restockProvider.notifier)
                              .addProduct(item);
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : shopping.items.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Text(
                                'Cari produk di atas untuk ditambahkan.',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500]),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(
                                16, 4, 16, 8),
                            itemCount: shopping.items.length,
                            itemBuilder: (context, i) {
                              final item = shopping.items[i];
                              return _ShoppingItemCard(
                                item: item,
                                onQuantityChanged: (qty) => ref
                                    .read(restockProvider.notifier)
                                    .setQuantity(
                                        item.productId, qty),
                                onPriceChanged: (price) => ref
                                    .read(restockProvider.notifier)
                                    .setPurchasePrice(
                                        item.productId, price),
                                onRemove: () => ref
                                    .read(restockProvider.notifier)
                                    .removeItem(item.productId),
                              );
                            },
                          ),
              ),

              // Footer
              if (shopping.items.isNotEmpty)
                _BottomSummary(
                  shopping: shopping,
                  isSaving: saveState.isLoading,
                  onSave: _save,
                ),
            ],
          ),
        );
      },
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
    required this.onAdd,
  });

  final String query;
  final AsyncValue<List<Product>> productsAsync;
  final void Function(ShoppingItem) onAdd;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return productsAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (products) {
        final filtered = products
            .where((p) => p.name.toLowerCase().contains(query))
            .toList();

        if (filtered.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Produk "$query" tidak ditemukan.',
                style:
                    TextStyle(fontSize: 15, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          itemCount: filtered.length,
          itemBuilder: (context, i) {
            final p = filtered[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onAdd(ShoppingItem(
                    productId: p.id,
                    productName: p.name,
                    purchaseUnit: p.purchaseUnit,
                    purchaseConversion: p.purchaseConversion,
                    inventoryUnit: p.inventoryUnit,
                    quantity: 1,
                    purchasePrice: p.lastBuyPrice,
                  )),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: colorScheme.primary
                                .withAlpha(15),
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                          child: Icon(
                              Icons.inventory_2_rounded,
                              size: 20,
                              color: colorScheme.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(p.name,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight:
                                          FontWeight.w600)),
                              Text(
                                'Stok: ${p.currentStock} ${p.inventoryUnit}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.add_circle_rounded,
                            color: colorScheme.primary, size: 26),
                      ],
                    ),
                  ),
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
// Shopping Item Card — with thousand separator on price
// ---------------------------------------------------------------------------

class _ShoppingItemCard extends StatefulWidget {
  const _ShoppingItemCard({
    required this.item,
    required this.onQuantityChanged,
    required this.onPriceChanged,
    required this.onRemove,
  });

  final ShoppingItem item;
  final void Function(int) onQuantityChanged;
  final void Function(int) onPriceChanged;
  final VoidCallback onRemove;

  @override
  State<_ShoppingItemCard> createState() =>
      _ShoppingItemCardState();
}

class _ShoppingItemCardState extends State<_ShoppingItemCard> {
  late TextEditingController _priceController;
  bool _priceInitialized = false;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController();
    _initPrice();
  }

  void _initPrice() {
    if (widget.item.purchasePrice > 0) {
      final formatted = _formatThousands(widget.item.purchasePrice);
      _priceController.text = formatted;
    }
    _priceInitialized = true;
  }

  String _formatThousands(int value) {
    final s = value.toString();
    final buf = StringBuffer();
    final len = s.length;
    for (var i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      widget.item.quantity > 0 && widget.item.purchasePrice > 0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final subtotal = widget.item.subtotal;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(Icons.inventory_2_rounded,
                    size: 18, color: colorScheme.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.item.productName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: widget.onRemove,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.close_rounded,
                      size: 18, color: Colors.grey[400]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Qty + Price row
          Row(
            children: [
              // Quantity
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Jumlah (${widget.item.purchaseUnit})',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[500])),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      QuantityButton(
                        icon: Icons.remove,
                        onPressed: () =>
                            widget.onQuantityChanged(
                                widget.item.quantity - 1),
                      ),
                      SizedBox(
                        width: 38,
                        child: Text(
                          '${widget.item.quantity}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      QuantityButton(
                        icon: Icons.add,
                        onPressed: () =>
                            widget.onQuantityChanged(
                                widget.item.quantity + 1),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 14),

              // Price per unit
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Harga/unit',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[500])),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 44,
                      child: TextField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [_TF()],
                        decoration: InputDecoration(
                          hintText: '0',
                          prefixText: 'Rp ',
                          prefixStyle: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600]),
                          contentPadding:
                              const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: Colors.grey[200]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: Colors.grey[200]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: colorScheme.primary,
                                width: 1.5),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF9F9F9),
                        ),
                        style: const TextStyle(fontSize: 14),
                        onChanged: (v) {
                          final n = _TF.parse(v);
                          widget.onPriceChanged(n);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Subtotal + stock helper
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Menambah stok: ${widget.item.inventoryStockAdded} ${widget.item.inventoryUnit}',
                style: TextStyle(
                    fontSize: 11, color: Colors.grey[500]),
              ),
              Text(
                _isValid
                    ? 'Subtotal: ${CurrencyFormatter.format(subtotal)}'
                    : 'Subtotal: —',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _isValid
                      ? colorScheme.primary
                      : Colors.grey[400],
                ),
              ),
            ],
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
    required this.shopping,
    required this.isSaving,
    required this.onSave,
  });

  final ShoppingState shopping;
  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return TransactionFooter(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SummaryRow(
            label: 'Total Belanja',
            value: CurrencyFormatter.format(shopping.totalAmount),
            isTotal: true,
          ),
          const SizedBox(height: 14),
          FooterActionButton(
            label: 'Simpan Belanja',
            onPressed: () async => onSave(),
            isSaving: isSaving,
            enabled: shopping.canSave,
          ),
        ],
      ),
    );
  }
}
