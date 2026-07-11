import 'package:intl/intl.dart';

final _idr = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
String _fmt(int n) => _idr.format(n);

// ---------------------------------------------------------------------------
// Enums + Filter
// ---------------------------------------------------------------------------

enum CustomerSortField { name, balance, lastTransaction }
enum CustomerBalanceFilter { all, hasDebt, paidOff, overpaid }

class CustomerFilter {
  const CustomerFilter({
    this.search = '',
    this.balanceFilter = CustomerBalanceFilter.all,
    this.sortField = CustomerSortField.balance,
    this.sortAscending = false,
    this.page = 0,
    this.pageSize = 25,
  });

  final String search;
  final CustomerBalanceFilter balanceFilter;
  final CustomerSortField sortField;
  final bool sortAscending;
  final int page;
  final int pageSize;

  CustomerFilter copyWith({
    String? search,
    CustomerBalanceFilter? balanceFilter,
    CustomerSortField? sortField,
    bool? sortAscending,
    int? page,
    int? pageSize,
  }) =>
      CustomerFilter(
        search: search ?? this.search,
        balanceFilter: balanceFilter ?? this.balanceFilter,
        sortField: sortField ?? this.sortField,
        sortAscending: sortAscending ?? this.sortAscending,
        page: page ?? this.page,
        pageSize: pageSize ?? this.pageSize,
      );

  CustomerFilter reset() => const CustomerFilter();

  bool get hasActiveFilters =>
      search.isNotEmpty ||
      balanceFilter != CustomerBalanceFilter.all;
}

class CustomerPageResult {
  const CustomerPageResult({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  final List<CustomerExplorerItem> items;
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

class CustomerExplorerItem {
  const CustomerExplorerItem({
    required this.id,
    required this.name,
    required this.phone,
    required this.balance,
    required this.txCount,
    required this.isActive,
    this.lastTransactionDate,
  });

  final String id;
  final String name;
  final String? phone;
  final int balance; // positive = owes money, negative = overpaid
  final int txCount;
  final bool isActive;
  final DateTime? lastTransactionDate;

  bool get hasDebt => balance > 0;
  bool get isOverpaid => balance < 0;
  bool get isPaidOff => balance == 0;

  String get formattedBalance => _fmt(balance.abs());
  String get formattedLastTx => lastTransactionDate != null
      ? DateFormat('d MMM yyyy').format(lastTransactionDate!)
      : '—';

  String get statusLabel {
    if (!isActive) return 'Nonaktif';
    if (hasDebt) return 'Berhutang';
    if (isOverpaid) return 'Lebih Bayar';
    return 'Lunas';
  }
}

// ---------------------------------------------------------------------------
// Detail
// ---------------------------------------------------------------------------

class CustomerExplorerDetail {
  const CustomerExplorerDetail({
    required this.id,
    required this.name,
    required this.phone,
    required this.note,
    required this.isActive,
    required this.createdAt,
    required this.balance,
    required this.totalDebt,
    required this.totalPayment,
    required this.debtCount,
    required this.paymentCount,
    this.lastPaymentDate,
    this.largestDebt = 0,
    this.largestPayment = 0,
  });

  final String id;
  final String name;
  final String? phone;
  final String? note;
  final bool isActive;
  final DateTime createdAt;
  final int balance;
  final int totalDebt;
  final int totalPayment;
  final int debtCount;
  final int paymentCount;
  final DateTime? lastPaymentDate;
  final int largestDebt;
  final int largestPayment;

  String get formattedBalance => _fmt(balance.abs());
  String get formattedTotalDebt => _fmt(totalDebt);
  String get formattedTotalPayment => _fmt(totalPayment);
  String get formattedCreated =>
      DateFormat('d MMMM yyyy').format(createdAt);
  String get formattedLastPayment => lastPaymentDate != null
      ? DateFormat('d MMM yyyy').format(lastPaymentDate!)
      : '—';
  String get formattedLargestDebt => _fmt(largestDebt);
  String get formattedLargestPayment => _fmt(largestPayment);
}

// ---------------------------------------------------------------------------
// Timeline
// ---------------------------------------------------------------------------

class DebtTimelineItem {
  const DebtTimelineItem({
    required this.id,
    required this.type,
    required this.amount,
    required this.createdAt,
    required this.runningBalance,
    this.note,
  });

  final String id;
  final String type; // 'debt' | 'payment'
  final int amount;
  final DateTime createdAt;
  final int runningBalance;
  final String? note;

  bool get isDebt => type == 'debt';
  String get formattedAmount => _fmt(amount);
  String get formattedBalance => _fmt(runningBalance.abs());
  String get formattedDate =>
      DateFormat('d MMM yyyy HH:mm').format(createdAt);
}

// ---------------------------------------------------------------------------
// Debt aging
// ---------------------------------------------------------------------------

class DebtAgingBucket {
  const DebtAgingBucket({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final int amount;
  final int color; // hex color value

  String get formattedAmount => _fmt(amount);
  double fraction(int total) =>
      total > 0 ? amount / total : 0;
}

// ---------------------------------------------------------------------------
// Summary
// ---------------------------------------------------------------------------

class KasbonSummary {
  const KasbonSummary({
    required this.totalOutstanding,
    required this.totalCustomers,
    required this.customersWithDebt,
    required this.paidThisMonth,
    required this.averageOutstanding,
    required this.largestBalance,
    this.largestCustomerName = '',
  });

  final int totalOutstanding;
  final int totalCustomers;
  final int customersWithDebt;
  final int paidThisMonth;
  final int averageOutstanding;
  final int largestBalance;
  final String largestCustomerName;

  String get formattedOutstanding => _fmt(totalOutstanding);
  String get formattedPaid => _fmt(paidThisMonth);
  String get formattedAverage => _fmt(averageOutstanding);
  String get formattedLargest => _fmt(largestBalance);
}
