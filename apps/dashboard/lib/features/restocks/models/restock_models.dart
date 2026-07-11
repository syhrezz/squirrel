import 'package:intl/intl.dart';

final _idr = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
String _fmt(int n) => _idr.format(n);

// ---------------------------------------------------------------------------
// Enums + Filter
// ---------------------------------------------------------------------------

enum RestockSortField { date, total, itemCount }
enum RestockSortDir { asc, desc }
enum RestockDatePreset { today, yesterday, last7, last30, all }

class RestockFilter {
  const RestockFilter({
    this.search = '',
    this.datePreset = RestockDatePreset.all,
    this.minTotal,
    this.maxTotal,
    this.sortField = RestockSortField.date,
    this.sortDir = RestockSortDir.desc,
    this.page = 0,
    this.pageSize = 25,
  });

  final String search;
  final RestockDatePreset datePreset;
  final int? minTotal;
  final int? maxTotal;
  final RestockSortField sortField;
  final RestockSortDir sortDir;
  final int page;
  final int pageSize;

  RestockFilter copyWith({
    String? search,
    RestockDatePreset? datePreset,
    int? minTotal,
    int? maxTotal,
    RestockSortField? sortField,
    RestockSortDir? sortDir,
    int? page,
    int? pageSize,
    bool clearMin = false,
    bool clearMax = false,
  }) =>
      RestockFilter(
        search: search ?? this.search,
        datePreset: datePreset ?? this.datePreset,
        minTotal: clearMin ? null : (minTotal ?? this.minTotal),
        maxTotal: clearMax ? null : (maxTotal ?? this.maxTotal),
        sortField: sortField ?? this.sortField,
        sortDir: sortDir ?? this.sortDir,
        page: page ?? this.page,
        pageSize: pageSize ?? this.pageSize,
      );

  RestockFilter reset() => const RestockFilter();

  bool get hasActiveFilters =>
      search.isNotEmpty ||
      datePreset != RestockDatePreset.all ||
      minTotal != null ||
      maxTotal != null;

  (int? from, int? to) get epochRange {
    final now = DateTime.now();
    switch (datePreset) {
      case RestockDatePreset.today:
        return (DateTime(now.year, now.month, now.day)
            .millisecondsSinceEpoch, null);
      case RestockDatePreset.yesterday:
        return (
          DateTime(now.year, now.month, now.day - 1)
              .millisecondsSinceEpoch,
          DateTime(now.year, now.month, now.day)
              .millisecondsSinceEpoch,
        );
      case RestockDatePreset.last7:
        return (DateTime(now.year, now.month, now.day - 7)
            .millisecondsSinceEpoch, null);
      case RestockDatePreset.last30:
        return (DateTime(now.year, now.month, now.day - 30)
            .millisecondsSinceEpoch, null);
      case RestockDatePreset.all:
        return (null, null);
    }
  }
}

class RestockPageResult {
  const RestockPageResult({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  final List<RestockExplorerItem> items;
  final int totalCount;
  final int page;
  final int pageSize;

  int get totalPages =>
      pageSize > 0 ? (totalCount / pageSize).ceil() : 1;
  bool get hasNext => page < totalPages - 1;
  bool get hasPrev => page > 0;
}

// ---------------------------------------------------------------------------
// List item
// ---------------------------------------------------------------------------

class RestockExplorerItem {
  const RestockExplorerItem({
    required this.id,
    required this.restockNumber,
    required this.createdAt,
    required this.createdBy,
    required this.deviceId,
    required this.totalAmount,
    required this.itemCount,
    required this.synced,
  });

  final String id;
  final String restockNumber;
  final DateTime createdAt;
  final String createdBy;
  final String deviceId;
  final int totalAmount;
  final int itemCount;
  final bool synced;

  String get formattedDate =>
      DateFormat('d MMM yyyy').format(createdAt);
  String get formattedTime =>
      DateFormat('HH:mm').format(createdAt);
  String get formattedTotal => _fmt(totalAmount);
}

// ---------------------------------------------------------------------------
// Detail
// ---------------------------------------------------------------------------

class RestockDetail {
  const RestockDetail({
    required this.id,
    required this.restockNumber,
    required this.createdAt,
    required this.createdBy,
    required this.deviceId,
    required this.totalAmount,
    required this.synced,
    required this.items,
  });

  final String id;
  final String restockNumber;
  final DateTime createdAt;
  final String createdBy;
  final String deviceId;
  final int totalAmount;
  final bool synced;
  final List<RestockItemDetail> items;

  String get formattedDate =>
      DateFormat('d MMMM yyyy').format(createdAt);
  String get formattedTime =>
      DateFormat('HH:mm:ss').format(createdAt);
  String get formattedTotal => _fmt(totalAmount);

  int get totalInventoryAdded =>
      items.fold(0, (sum, i) => sum + i.inventoryAdded);
  String get formattedInventoryAdded =>
      '$totalInventoryAdded unit';
  double get avgCostPerItem => items.isEmpty
      ? 0
      : totalAmount / items.fold(0, (s, i) => s + i.quantity);
}

class RestockItemDetail {
  const RestockItemDetail({
    required this.id,
    required this.productId,
    required this.productName,
    required this.inventoryUnit,
    required this.purchaseUnit,
    required this.purchaseConversion,
    required this.quantity,
    required this.purchasePrice,
    required this.subtotal,
  });

  final String id;
  final String productId;
  final String productName;
  final String inventoryUnit;
  final String purchaseUnit;
  final int purchaseConversion;
  final int quantity;
  final int purchasePrice;
  final int subtotal;

  /// Total inventory units added = quantity × conversion.
  int get inventoryAdded => quantity * purchaseConversion;

  String get formattedPrice => _fmt(purchasePrice);
  String get formattedSubtotal => _fmt(subtotal);
}

// ---------------------------------------------------------------------------
// Purchase history
// ---------------------------------------------------------------------------

class PurchaseHistoryPoint {
  const PurchaseHistoryPoint({
    required this.date,
    required this.purchasePrice,
    required this.quantity,
    required this.restockId,
    this.prevPrice,
  });

  final DateTime date;
  final int purchasePrice;
  final int quantity;
  final String restockId;
  final int? prevPrice;

  double get changePercent {
    if (prevPrice == null || prevPrice == 0) return 0;
    return (purchasePrice - prevPrice!) / prevPrice! * 100;
  }

  String get formattedDate =>
      DateFormat('d MMM yyyy').format(date);
  String get formattedPrice => _fmt(purchasePrice);
  String get formattedChange =>
      changePercent == 0
          ? '—'
          : '${changePercent > 0 ? '+' : ''}${changePercent.toStringAsFixed(1)}%';
}

// ---------------------------------------------------------------------------
// Purchase summary
// ---------------------------------------------------------------------------

class PurchaseSummary {
  const PurchaseSummary({
    required this.totalRestocks,
    required this.totalSpent,
    required this.avgPerRestock,
    required this.highestItem,
    required this.lowestItem,
    required this.priceIncreases,
    required this.priceDecreases,
  });

  final int totalRestocks;
  final int totalSpent;
  final int avgPerRestock;
  final String highestItem;
  final String lowestItem;
  final int priceIncreases;
  final int priceDecreases;

  String get formattedTotal => _fmt(totalSpent);
  String get formattedAvg => _fmt(avgPerRestock);
}
