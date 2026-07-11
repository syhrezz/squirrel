/// In-memory model representing a product added to the current transaction.
///
/// This is NOT persisted until the user confirms the transaction.
/// It lives only in the PenjualanNotifier state.
///
/// v2: now carries sellingOptionId and inventoryQuantity so the repository
/// knows exactly how many inventory units to deduct from stock.
class CartItem {
  const CartItem({
    required this.productId,
    required this.productName,
    required this.sellingPrice,
    required this.quantity,
    required this.currentStock,
    required this.inventoryUnit,
    required this.inventoryQuantityPerUnit,
    this.sellingOptionId,
    this.displayName,
  });

  final String productId;
  final String productName;

  /// Snapshot of the selling price at the time of adding to cart.
  final int sellingPrice;

  /// How many of this selling option the customer is buying.
  final int quantity;

  /// Stock at the time of adding — for display only.
  final int currentStock;

  /// The inventory unit label, e.g. 'pcs', 'gram'. For display only.
  final String inventoryUnit;

  /// How many inventory units ONE of this selling option represents.
  /// Stock deduction = quantity * inventoryQuantityPerUnit
  /// Example: 500 gram option → inventoryQuantityPerUnit = 500
  final int inventoryQuantityPerUnit;

  /// The ID of the selling option chosen. Null for legacy/simple products.
  final String? sellingOptionId;

  /// Display name of the option e.g. '500 gram'. Falls back to productName.
  final String? displayName;

  String get label => displayName ?? productName;

  int get subtotal => sellingPrice * quantity;

  /// Total inventory units this cart item will deduct from stock.
  int get totalInventoryDeduction => inventoryQuantityPerUnit * quantity;

  CartItem copyWith({int? quantity, int? sellingPrice}) => CartItem(
        productId: productId,
        productName: productName,
        sellingPrice: sellingPrice ?? this.sellingPrice,
        quantity: quantity ?? this.quantity,
        currentStock: currentStock,
        inventoryUnit: inventoryUnit,
        inventoryQuantityPerUnit: inventoryQuantityPerUnit,
        sellingOptionId: sellingOptionId,
        displayName: displayName,
      );
}
