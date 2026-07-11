import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/utils/currency_formatter.dart';
import '../../features/penjualan/models/cart_item.dart';
import '../../features/penjualan/providers/discovery_providers.dart';

class FrequentlySoldSection extends ConsumerWidget {
  const FrequentlySoldSection({
    super.key,
    required this.onProductTap,
    required this.cartItems,
  });

  final Future<void> Function(Product) onProductTap;
  final List<CartItem> cartItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final frequentAsync = ref.watch(frequentlySoldProvider);

    return frequentAsync.when(
      loading: () => const SizedBox(
        height: 130,
        child: Center(
            child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            child: Text(
              'Belum ada produk yang sering dijual.',
              style:
                  TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          );
        }

        return SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final inCart = cartItems
                  .any((c) => c.productId == item.product.id);
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _ProductQuickCard(
                  product: item.product,
                  inCart: inCart,
                  onTap: () => onProductTap(item.product),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _ProductQuickCard extends StatelessWidget {
  const _ProductQuickCard({
    required this.product,
    required this.onTap,
    required this.inCart,
  });

  final Product product;
  final VoidCallback onTap;
  final bool inCart;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: inCart
              ? Border.all(color: colorScheme.primary, width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: inCart
                    ? colorScheme.primary.withAlpha(20)
                    : colorScheme.primary.withAlpha(12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.inventory_2_rounded,
                size: 20,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              product.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              CurrencyFormatter.format(product.sellPrice),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper used by both section widgets.
CartItem productToCartItem(Product product) {
  return CartItem(
    productId: product.id,
    productName: product.name,
    sellingPrice: product.sellPrice,
    quantity: 1,
    currentStock: product.currentStock,
    inventoryUnit: product.inventoryUnit,
    inventoryQuantityPerUnit: 1,
  );
}
