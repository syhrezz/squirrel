/// In-memory model representing one product in the current shopping session.
///
/// NOT persisted until the user confirms with "Simpan Belanja".
/// Lives only in RestockNotifier state.
///
/// v3: purchasePrice is now price PER PURCHASE UNIT (e.g. price per Dus).
/// subtotal = quantity × purchasePrice — auto-calculated.
class ShoppingItem {
  const ShoppingItem({
    required this.productId,
    required this.productName,
    required this.purchaseUnit,
    required this.purchaseConversion,
    required this.inventoryUnit,
    required this.quantity,
    required this.purchasePrice,
  });

  final String productId;
  final String productName;

  /// The unit shown to the operator. Example: 'Dus', 'Pack', 'Karung'
  final String purchaseUnit;

  /// How many inventory units are in 1 purchase unit.
  /// Example: 1 Dus = 40 pcs → purchaseConversion = 40
  final int purchaseConversion;

  /// The internal inventory unit. Example: 'pcs', 'gram'
  final String inventoryUnit;

  /// How many purchase units the operator bought.
  final int quantity;

  /// Price PER PURCHASE UNIT in IDR.
  /// Example: 1 Dus = 50.000 → purchasePrice = 50000
  final int purchasePrice;

  /// Subtotal = quantity × purchasePrice (auto-calculated).
  int get subtotal => quantity * purchasePrice;

  /// How many inventory units will be added to stock.
  int get inventoryStockAdded => quantity * purchaseConversion;

  ShoppingItem copyWith({int? quantity, int? purchasePrice}) => ShoppingItem(
        productId: productId,
        productName: productName,
        purchaseUnit: purchaseUnit,
        purchaseConversion: purchaseConversion,
        inventoryUnit: inventoryUnit,
        quantity: quantity ?? this.quantity,
        purchasePrice: purchasePrice ?? this.purchasePrice,
      );
}
