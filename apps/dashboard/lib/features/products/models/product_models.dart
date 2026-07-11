import 'package:intl/intl.dart';

final _idr = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
String _fmt(int n) => _idr.format(n);

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

enum ProductSortField { name, stock, updatedAt, sellPrice }
enum ProductStatusFilter { all, active, inactive }
enum ProductStockFilter { all, lowStock, outOfStock }

// ---------------------------------------------------------------------------
// Filter
// ---------------------------------------------------------------------------

class ProductFilter {
  const ProductFilter({
    this.search = '',
    this.category = '',
    this.status = ProductStatusFilter.all,
    this.stockFilter = ProductStockFilter.all,
    this.sortField = ProductSortField.updatedAt,
    this.sortAscending = false,
    this.page = 0,
    this.pageSize = 25,
  });

  final String search;
  final String category;
  final ProductStatusFilter status;
  final ProductStockFilter stockFilter;
  final ProductSortField sortField;
  final bool sortAscending;
  final int page;
  final int pageSize;

  ProductFilter copyWith({
    String? search,
    String? category,
    ProductStatusFilter? status,
    ProductStockFilter? stockFilter,
    ProductSortField? sortField,
    bool? sortAscending,
    int? page,
    int? pageSize,
  }) =>
      ProductFilter(
        search: search ?? this.search,
        category: category ?? this.category,
        status: status ?? this.status,
        stockFilter: stockFilter ?? this.stockFilter,
        sortField: sortField ?? this.sortField,
        sortAscending: sortAscending ?? this.sortAscending,
        page: page ?? this.page,
        pageSize: pageSize ?? this.pageSize,
      );

  ProductFilter resetFilters() => const ProductFilter();

  bool get hasActiveFilters =>
      search.isNotEmpty ||
      category.isNotEmpty ||
      status != ProductStatusFilter.all ||
      stockFilter != ProductStockFilter.all;
}

class ProductPageResult {
  const ProductPageResult({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  final List<ProductExplorerItem> items;
  final int totalCount;
  final int page;
  final int pageSize;

  int get totalPages =>
      pageSize > 0 ? (totalCount / pageSize).ceil() : 1;
  bool get hasNextPage => page < totalPages - 1;
  bool get hasPrevPage => page > 0;
}

// ---------------------------------------------------------------------------
// List item
// ---------------------------------------------------------------------------

class ProductExplorerItem {
  const ProductExplorerItem({
    required this.id,
    required this.name,
    required this.category,
    required this.currentStock,
    required this.inventoryUnit,
    required this.purchaseUnit,
    required this.purchaseConversion,
    required this.sellPrice,
    required this.lastBuyPrice,
    required this.isActive,
    required this.updatedAt,
    this.minSellingPrice,
  });

  final String id;
  final String name;
  final String category;
  final int currentStock;
  final String inventoryUnit;
  final String purchaseUnit;
  final int purchaseConversion;
  final int sellPrice;
  final int lastBuyPrice;
  final bool isActive;
  final DateTime updatedAt;
  final int? minSellingPrice;

  bool get isLowStock => currentStock > 0 && currentStock <= 3;
  bool get isOutOfStock => currentStock <= 0;

  String get formattedSellPrice => _fmt(minSellingPrice ?? sellPrice);
  String get formattedBuyPrice => _fmt(lastBuyPrice);
  String get formattedUpdatedAt =>
      DateFormat('d MMM yyyy').format(updatedAt);
  String get stockLabel => '$currentStock $inventoryUnit';
}

// ---------------------------------------------------------------------------
// Detail
// ---------------------------------------------------------------------------

class ProductExplorerDetail {
  const ProductExplorerDetail({
    required this.id,
    required this.name,
    required this.category,
    required this.isActive,
    required this.inventoryUnit,
    required this.purchaseUnit,
    required this.purchaseConversion,
    required this.currentStock,
    required this.sellPrice,
    required this.lastBuyPrice,
    required this.updatedAt,
    required this.createdAt,
    required this.sellingOptions,
    this.lastRestockDate,
    this.lastSaleDate,
    this.unitsSold30d = 0,
    this.revenue30d = 0,
  });

  final String id;
  final String name;
  final String category;
  final bool isActive;
  final String inventoryUnit;
  final String purchaseUnit;
  final int purchaseConversion;
  final int currentStock;
  final int sellPrice;
  final int lastBuyPrice;
  final DateTime updatedAt;
  final DateTime createdAt;
  final List<SellingOptionItem> sellingOptions;
  final DateTime? lastRestockDate;
  final DateTime? lastSaleDate;
  final int unitsSold30d;
  final int revenue30d;

  int get inventoryValue => currentStock * lastBuyPrice;
  double get estimatedMargin => lastBuyPrice > 0
      ? ((sellPrice - lastBuyPrice) / sellPrice * 100)
      : 0;
  double get avgDailySales30d => unitsSold30d / 30.0;

  String get formattedStock => '$currentStock $inventoryUnit';
  String get formattedValue => _fmt(inventoryValue);
  String get formattedSell => _fmt(sellPrice);
  String get formattedBuy => _fmt(lastBuyPrice);
  String get formattedRevenue30d => _fmt(revenue30d);
  String get formattedMargin =>
      '${estimatedMargin.toStringAsFixed(1)}%';
  String get formattedConversion =>
      '1 $purchaseUnit = $purchaseConversion $inventoryUnit';
}

class SellingOptionItem {
  const SellingOptionItem({
    required this.id,
    required this.displayName,
    required this.quantity,
    required this.sellingPrice,
    required this.isActive,
  });

  final String id;
  final String displayName;
  final int quantity;
  final int sellingPrice;
  final bool isActive;

  String get formattedPrice => _fmt(sellingPrice);
}

// ---------------------------------------------------------------------------
// Recent transactions
// ---------------------------------------------------------------------------

class RecentProductSale {
  const RecentProductSale({
    required this.saleId,
    required this.date,
    required this.quantity,
    required this.sellingPrice,
    required this.subtotal,
  });

  final String saleId;
  final DateTime date;
  final int quantity;
  final int sellingPrice;
  final int subtotal;

  String get formattedDate =>
      DateFormat('d MMM yyyy HH:mm').format(date);
  String get formattedPrice => _fmt(sellingPrice);
  String get formattedSubtotal => _fmt(subtotal);
}

class RecentProductRestock {
  const RecentProductRestock({
    required this.restockId,
    required this.date,
    required this.quantity,
    required this.purchasePrice,
    required this.subtotal,
  });

  final String restockId;
  final DateTime date;
  final int quantity;
  final int purchasePrice;
  final int subtotal;

  String get formattedDate =>
      DateFormat('d MMM yyyy HH:mm').format(date);
  String get formattedPrice => _fmt(purchasePrice);
  String get formattedSubtotal => _fmt(subtotal);
}

class InventoryTimelinePoint {
  const InventoryTimelinePoint({
    required this.date,
    required this.stock,
    required this.changeType,
    required this.changeAmount,
  });

  final DateTime date;
  final int stock;
  final String changeType; // 'sale' | 'restock'
  final int changeAmount;

  String get label =>
      DateFormat('d/M').format(date);
}
