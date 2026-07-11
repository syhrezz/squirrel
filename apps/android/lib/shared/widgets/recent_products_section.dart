import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/utils/currency_formatter.dart';
import '../../features/penjualan/models/cart_item.dart';
import '../../features/penjualan/providers/discovery_providers.dart';

class RecentProductsSection extends ConsumerWidget {
  const RecentProductsSection({
    super.key,
    required this.onProductTap,
    required this.cartItems,
  });

  final Future<void> Function(Product) onProductTap;
  final List<CartItem> cartItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentAsync = ref.watch(recentlySoldProvider);

    return recentAsync.when(
      loading: () => const SizedBox(
        height: 130,
        child: Center(
            child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (products) {
        if (products.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final inCart = cartItems
                  .any((c) => c.productId == product.id);
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _RecentProductCard(
                  product: product,
                  inCart: inCart,
                  onTap: () => onProductTap(product),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _RecentProductCard extends StatelessWidget {
  const _RecentProductCard({
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
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.history_rounded,
                size: 20,
                color: Colors.orange[600],
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
