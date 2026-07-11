/// In-memory representation of one product selling option.
///
/// This mirrors a [ProductSellingOptionData] row but is used in-memory
/// for the sales screen bottom sheet and cart logic.
/// Never persisted directly — the selling price is snapshotted into SaleItems.
class SellingOption {
  const SellingOption({
    required this.id,
    required this.productId,
    required this.displayName,
    required this.inventoryQuantity,
    required this.sellingPrice,
    required this.displayOrder,
  });

  /// The database ID of this option row.
  final String id;
  final String productId;

  /// What the operator sees. Example: '500 gram', '1 pcs', '1 kg'
  final String displayName;

  /// How many inventory units this represents.
  /// Used for stock deduction — the operator never sees this number.
  final int inventoryQuantity;

  /// Price in IDR for this option.
  final int sellingPrice;
  final int displayOrder;
}
