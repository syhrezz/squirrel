import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/providers/database_providers.dart';
import '../data/repositories/customer_repository.dart';
import '../data/repositories/kasbon_repository.dart';
import '../models/customer_with_balance.dart';

// ---------------------------------------------------------------------------
// Repository providers
// ---------------------------------------------------------------------------

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return DriftCustomerRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(syncRepositoryProvider),
  );
});

final kasbonRepositoryProvider = Provider<KasbonRepository>((ref) {
  return DriftKasbonRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(syncRepositoryProvider),
  );
});

// ---------------------------------------------------------------------------
// Data providers
// ---------------------------------------------------------------------------

/// All active customers with their calculated balances, sorted by latest activity.
final customersWithBalanceProvider =
    StreamProvider<List<CustomerWithBalance>>((ref) {
  return ref.watch(kasbonRepositoryProvider).watchCustomersWithBalance();
});

/// A single customer by id.
final customerDetailProvider =
    StreamProvider.family<Customer?, String>((ref, id) {
  return ref.watch(customerRepositoryProvider).watchById(id);
});

/// All debt transactions for one customer, newest first.
final debtTransactionsProvider =
    StreamProvider.family<List<DebtTransaction>, String>((ref, customerId) {
  return ref.watch(kasbonRepositoryProvider).watchTransactions(customerId);
});

/// Calculated balance for one customer.
final customerBalanceProvider =
    StreamProvider.family<int, String>((ref, customerId) {
  return ref.watch(kasbonRepositoryProvider).watchBalance(customerId);
});

// ---------------------------------------------------------------------------
// Customer form notifier
// ---------------------------------------------------------------------------

class CustomerFormNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> save({
    String? existingId,
    required String name,
    String? phone,
    String? note,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final repo = ref.read(customerRepositoryProvider);
      final companion = CustomersCompanion(
        name: Value(name),
        phone: Value(phone != null && phone.isNotEmpty ? phone : null),
        note: Value(note != null && note.isNotEmpty ? note : null),
      );
      if (existingId == null) {
        await repo.create(companion);
      } else {
        await repo.update(existingId, companion);
      }
    });
    state = result;
    return !result.hasError;
  }

  Future<void> deactivate(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(customerRepositoryProvider).deactivate(id));
  }
}

final customerFormProvider =
    AsyncNotifierProvider<CustomerFormNotifier, void>(
  CustomerFormNotifier.new,
);

// ---------------------------------------------------------------------------
// Kasbon entry notifier
// ---------------------------------------------------------------------------

class KasbonEntryNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> addDebt({
    required String customerId,
    required int amount,
    String? note,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() =>
        ref.read(kasbonRepositoryProvider).addDebt(
              customerId: customerId,
              amount: amount,
              note: note,
            ));
    state = result;
    return !result.hasError;
  }

  Future<bool> addPayment({
    required String customerId,
    required int amount,
    String? note,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() =>
        ref.read(kasbonRepositoryProvider).addPayment(
              customerId: customerId,
              amount: amount,
              note: note,
            ));
    state = result;
    return !result.hasError;
  }
}

final kasbonEntryProvider =
    AsyncNotifierProvider<KasbonEntryNotifier, void>(
  KasbonEntryNotifier.new,
);
