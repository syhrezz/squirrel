import 'package:flutter/material.dart';
import '../../core/database/app_database.dart';
import '../../core/utils/currency_formatter.dart';
import '../../features/penjualan/models/cart_item.dart';

/// A reusable product row tile used in the category product list.
///
/// Presentation-only — no business logic inside.
/// Tapping anywhere on the row calls [onTap].
class ProductTile extends StatelessWidget {
  const ProductTile({
    super.key,
    required this.product,
    required this.onTap,
    this.inCart = false,
    this.cartQuantity = 0,
  });

  final Product product;
  final VoidCallback onTap;
  final bool inCart;
  final int cartQuantity;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLowStock = product.currentStock <= 3;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(6),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: inCart
                        ? colorScheme.primary.withAlpha(20)
                        : colorScheme.primary.withAlpha(10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.inventory_2_rounded,
                    size: 22,
                    color: inCart
                        ? colorScheme.primary
                        : colorScheme.primary.withAlpha(150),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            'Stok: ${product.currentStock} ${product.unit}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isLowStock
                                  ? Colors.orange[600]
                                  : Colors.grey[500],
                              fontWeight: isLowStock
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          if (isLowStock) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.warning_amber_rounded,
                                size: 12, color: Colors.orange[500]),
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
                        color: colorScheme.primary,
                      ),
                    ),
                    if (inCart)
                      Container(
                        margin: const EdgeInsets.only(top: 3),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'x$cartQuantity',
                          style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 8),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_rounded,
                      size: 20, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Converts a [Product] to a [CartItem] for adding to the cart.
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
