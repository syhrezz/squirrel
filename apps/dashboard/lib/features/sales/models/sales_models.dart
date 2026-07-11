import 'package:intl/intl.dart';

final _idr = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
String _fmt(int n) => _idr.format(n);

// ---------------------------------------------------------------------------
// Filter & pagination
// ---------------------------------------------------------------------------

enum SalesSortField { date, total, itemCount }
enum SortDirection { asc, desc }
enum DateRangePreset { today, yesterday, last7, last30, all }

class SalesFilter {
  const SalesFilter({
    this.search = '',
    this.datePreset = DateRangePreset.all,
    this.dateFrom,
    this.dateTo,
    this.minTotal,
    this.maxTotal,
    this.sortField = SalesSortField.date,
    this.sortDirection = SortDirection.desc,
    this.page = 0,
    this.pageSize = 25,
  });

  final String search;
  final DateRangePreset datePreset;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final int? minTotal;
  final int? maxTotal;
  final SalesSortField sortField;
  final SortDirection sortDirection;
  final int page;
  final int pageSize;

  SalesFilter copyWith({
    String? search,
    DateRangePreset? datePreset,
    DateTime? dateFrom,
    DateTime? dateTo,
    int? minTotal,
    int? maxTotal,
    SalesSortField? sortField,
    SortDirection? sortDirection,
    int? page,
    int? pageSize,
    bool clearDateRange = false,
    bool clearMinTotal = false,
    bool clearMaxTotal = false,
  }) {
    return SalesFilter(
      search: search ?? this.search,
      datePreset: datePreset ?? this.datePreset,
      dateFrom: clearDateRange ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDateRange ? null : (dateTo ?? this.dateTo),
      minTotal: clearMinTotal ? null : (minTotal ?? this.minTotal),
      maxTotal: clearMaxTotal ? null : (maxTotal ?? this.maxTotal),
      sortField: sortField ?? this.sortField,
      sortDirection: sortDirection ?? this.sortDirection,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  SalesFilter resetFilters() => const SalesFilter();

  bool get hasActiveFilters =>
      search.isNotEmpty ||
      datePreset != DateRangePreset.all ||
      dateFrom != null ||
      dateTo != null ||
      minTotal != null ||
      maxTotal != null;

  /// Returns epoch ms range based on preset or custom range.
  (int? from, int? to) get epochRange {
    final now = DateTime.now();
    switch (datePreset) {
      case DateRangePreset.today:
        final start = DateTime(now.year, now.month, now.day);
        return (start.millisecondsSinceEpoch, null);
      case DateRangePreset.yesterday:
        final start =
            DateTime(now.year, now.month, now.day - 1);
        final end = DateTime(now.year, now.month, now.day);
        return (start.millisecondsSinceEpoch,
            end.millisecondsSinceEpoch);
      case DateRangePreset.last7:
        final start =
            DateTime(now.year, now.month, now.day - 7);
        return (start.millisecondsSinceEpoch, null);
      case DateRangePreset.last30:
        final start =
            DateTime(now.year, now.month, now.day - 30);
        return (start.millisecondsSinceEpoch, null);
      case DateRangePreset.all:
        if (dateFrom != null || dateTo != null) {
          return (
            dateFrom?.millisecondsSinceEpoch,
            dateTo?.millisecondsSinceEpoch
          );
        }
        return (null, null);
    }
  }
}

class SalesPageResult {
  const SalesPageResult({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  final List<SalesListItem> items;
  final int totalCount;
  final int page;
  final int pageSize;

  int get totalPages => (totalCount / pageSize).ceil();
  bool get hasNextPage => page < totalPages - 1;
  bool get hasPrevPage => page > 0;
}

// ---------------------------------------------------------------------------
// List item (table row)
// ---------------------------------------------------------------------------

class SalesListItem {
  const SalesListItem({
    required this.id,
    required this.invoiceNumber,
    required this.createdAt,
    required this.createdBy,
    required this.deviceId,
    required this.totalAmount,
    required this.itemCount,
    required this.synced,
  });

  final String id;
  final String invoiceNumber;
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
  String get shortId => id.substring(0, 8).toUpperCase();
}

// ---------------------------------------------------------------------------
// Detail
// ---------------------------------------------------------------------------

class SaleDetail {
  const SaleDetail({
    required this.id,
    required this.invoiceNumber,
    required this.createdAt,
    required this.createdBy,
    required this.deviceId,
    required this.totalAmount,
    required this.amountPaid,
    required this.changeAmount,
    required this.synced,
    required this.items,
  });

  final String id;
  final String invoiceNumber;
  final DateTime createdAt;
  final String createdBy;
  final String deviceId;
  final int totalAmount;
  final int amountPaid;
  final int changeAmount;
  final bool synced;
  final List<SaleItemDetail> items;

  String get formattedDate =>
      DateFormat('d MMMM yyyy', 'id_ID').format(createdAt);
  String get formattedTime =>
      DateFormat('HH:mm:ss').format(createdAt);
  String get formattedTotal => _fmt(totalAmount);
  String get formattedPaid => _fmt(amountPaid);
  String get formattedChange => _fmt(changeAmount);
  String get shortId => id.substring(0, 8).toUpperCase();
}

class SaleItemDetail {
  const SaleItemDetail({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.sellingPrice,
    required this.subtotal,
  });

  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final int sellingPrice;
  final int subtotal;

  String get formattedPrice => _fmt(sellingPrice);
  String get formattedSubtotal => _fmt(subtotal);
}
