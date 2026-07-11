import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/utils/uuid_util.dart';
import '../../../../core/utils/dev_user.dart';
import '../../models/customer_with_balance.dart';

/// Append-only ledger operations for kasbon (debt/payment) tracking.
///
/// NO update or delete methods exist by design.
/// Balance is NEVER stored — always calculated from the ledger.
abstract class KasbonRepository {
  /// Watches all active customers with their calculated balances,
  /// sorted by latest activity first.
  Stream<List<CustomerWithBalance>> watchCustomersWithBalance();

  /// Watches all transactions for one customer, newest first.
  Stream<List<DebtTransaction>> watchTransactions(String customerId);

  /// Watches the calculated outstanding balance for one customer.
  Stream<int> watchBalance(String customerId);

  /// Appends a debt entry to the ledger.
  Future<void> addDebt({
    required String customerId,
    required int amount,
    String? note,
  });

  /// Appends a payment entry to the ledger.
  Future<void> addPayment({
    required String customerId,
    required int amount,
    String? note,
  });
}

class DriftKasbonRepository implements KasbonRepository {
  const DriftKasbonRepository(this._db);
  final AppDatabase _db;

  @override
  Stream<List<CustomerWithBalance>> watchCustomersWithBalance() {
    // Watch customers table — stream updates on any customer change
    final customerStream = (_db.select(_db.customers)
          ..where((c) => c.isActive.equals(true)))
        .watch();

    return customerStream.asyncMap((customers) async {
      final result = <CustomerWithBalance>[];

      for (final customer in customers) {
        // Calculate balance for each customer
        final txRows = await (_db.select(_db.debtTransactions)
              ..where((t) => t.customerId.equals(customer.id)))
            .get();

        int balance = 0;
        int? lastActivity;
        for (final tx in txRows) {
          if (tx.type == 'debt') {
            balance += tx.amount;
          } else {
            balance -= tx.amount;
          }
          if (lastActivity == null || tx.createdAt > lastActivity) {
            lastActivity = tx.createdAt;
          }
        }

        result.add(CustomerWithBalance(
          customer: customer,
          balance: balance,
          lastActivityAt: lastActivity,
        ));
      }

      // Sort: customers with recent activity first, then alphabetically
      result.sort((a, b) {
        if (a.lastActivityAt != null && b.lastActivityAt != null) {
          return b.lastActivityAt!.compareTo(a.lastActivityAt!);
        }
        if (a.lastActivityAt != null) return -1;
        if (b.lastActivityAt != null) return 1;
        return a.customer.name.compareTo(b.customer.name);
      });

      return result;
    });
    // Suppress unused variable warning — txStream triggers reactivity
    // ignore: unused_local_variable
  }

  @override
  Stream<List<DebtTransaction>> watchTransactions(String customerId) {
    return (_db.select(_db.debtTransactions)
          ..where((t) => t.customerId.equals(customerId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  @override
  Stream<int> watchBalance(String customerId) {
    return watchTransactions(customerId).map((txList) {
      int balance = 0;
      for (final tx in txList) {
        if (tx.type == 'debt') {
          balance += tx.amount;
        } else {
          balance -= tx.amount;
        }
      }
      return balance;
    });
  }

  @override
  Future<void> addDebt({
    required String customerId,
    required int amount,
    String? note,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.into(_db.debtTransactions).insert(
          DebtTransactionsCompanion.insert(
            id: UuidUtil.generate(),
            customerId: customerId,
            type: 'debt',
            amount: amount,
            note: Value(note),
            createdAt: now,
            createdBy: kDevUser.id,
            synced: const Value(false),
          ),
        );
  }

  @override
  Future<void> addPayment({
    required String customerId,
    required int amount,
    String? note,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.into(_db.debtTransactions).insert(
          DebtTransactionsCompanion.insert(
            id: UuidUtil.generate(),
            customerId: customerId,
            type: 'payment',
            amount: amount,
            note: Value(note),
            createdAt: now,
            createdBy: kDevUser.id,
            synced: const Value(false),
          ),
        );
  }
}
