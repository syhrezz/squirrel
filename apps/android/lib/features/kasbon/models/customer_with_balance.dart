import '../../../core/database/app_database.dart';

/// View model combining a customer with their calculated balance
/// and last activity timestamp.
///
/// This is NOT a database table. It is computed by [KasbonRepository]
/// and used only in the customer list UI.
///
/// Balance = SUM(debt amounts) - SUM(payment amounts)
/// A negative balance means the customer has overpaid.
class CustomerWithBalance {
  const CustomerWithBalance({
    required this.customer,
    required this.balance,
    this.lastActivityAt,
  });

  final Customer customer;

  /// Outstanding balance in IDR. Can be negative (overpaid).
  final int balance;

  /// epoch ms of the most recent debt_transaction for this customer.
  /// Null if no transactions exist yet.
  final int? lastActivityAt;
}
