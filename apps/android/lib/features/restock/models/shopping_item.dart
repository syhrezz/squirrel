/// In-memory model representing one product in the current shopping session.
///
/// NOT persisted until the user confirms with "Simpan Belanja".
/// Lives only in RestockNotifier state.
class ShoppingItem {
  const ShoppingItem({
    required this.productId,
    required this.productName,
    required this.unit,
    required this.customUnit,
    required this.quantity,
    required this.purchasePrice,
  });

  final String productId;
  final String productName;
  final String unit;
  final String? customUnit;
  final int quantity;

  /// Actual price paid per unit on this shopping trip.
  final int purchasePrice;

  int get subtotal => quantity * purchasePrice;

  String get displayUnit =>
      unit == 'lainnya' && customUnit != null ? customUnit! : unit;

  ShoppingItem copyWith({int? quantity, int? purchasePrice}) => ShoppingItem(
        productId: productId,
        productName: productName,
        unit: unit,
        customUnit: customUnit,
        quantity: quantity ?? this.quantity,
        purchasePrice: purchasePrice ?? this.purchasePrice,
      );
}
