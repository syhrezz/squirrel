/// In-memory model representing a product added to the current transaction.
///
/// This is NOT persisted until the user confirms the transaction.
/// It lives only in the PenjualanNotifier state.
class CartItem {
  const CartItem({
    required this.productId,
    required this.productName,
    required this.sellingPrice,
    required this.quantity,
    required this.currentStock,
  });

  final String productId;
  final String productName;

  /// Snapshot of the selling price at the time of adding to cart.
  final int sellingPrice;
  final int quantity;

  /// Stock at the time of adding — for display only.
  final int currentStock;

  int get subtotal => sellingPrice * quantity;

  CartItem copyWith({int? quantity}) => CartItem(
        productId: productId,
        productName: productName,
        sellingPrice: sellingPrice,
        quantity: quantity ?? this.quantity,
        currentStock: currentStock,
      );
}
