import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/database_providers.dart';
import '../data/repositories/sale_repository.dart';
import '../models/cart_item.dart';

/// Provides the [SaleRepository] backed by Drift.
final saleRepositoryProvider = Provider<SaleRepository>((ref) {
  return DriftSaleRepository(ref.watch(appDatabaseProvider));
});

/// In-memory cart state for the current transaction.
class CartState {
  const CartState({
    this.items = const [],
    this.amountPaid = 0,
  });

  final List<CartItem> items;
  final int amountPaid;

  int get totalAmount => items.fold<int>(0, (sum, i) => sum + i.subtotal);
  int get changeAmount => amountPaid - totalAmount;
  bool get canFinish => items.isNotEmpty && amountPaid >= totalAmount;

  CartState copyWith({List<CartItem>? items, int? amountPaid}) => CartState(
        items: items ?? this.items,
        amountPaid: amountPaid ?? this.amountPaid,
      );
}

/// Manages the in-memory cart for the current transaction.
///
/// Nothing is persisted until [finishTransaction] is called.
class PenjualanNotifier extends Notifier<CartState> {
  @override
  CartState build() => const CartState();

  /// Adds a product to the cart.
  /// If it already exists, increments quantity instead.
  void addProduct(CartItem newItem) {
    final items = List<CartItem>.from(state.items);
    final index = items.indexWhere((i) => i.productId == newItem.productId);
    if (index >= 0) {
      items[index] = items[index].copyWith(
        quantity: items[index].quantity + 1,
      );
    } else {
      items.add(newItem);
    }
    state = state.copyWith(items: items);
  }

  /// Increases quantity of an item by 1.
  void incrementQuantity(String productId) {
    final items = List<CartItem>.from(state.items);
    final index = items.indexWhere((i) => i.productId == productId);
    if (index < 0) return;
    items[index] = items[index].copyWith(quantity: items[index].quantity + 1);
    state = state.copyWith(items: items);
  }

  /// Decreases quantity of an item by 1.
  /// Removes the item if quantity reaches 0.
  void decrementQuantity(String productId) {
    final items = List<CartItem>.from(state.items);
    final index = items.indexWhere((i) => i.productId == productId);
    if (index < 0) return;
    if (items[index].quantity <= 1) {
      items.removeAt(index);
    } else {
      items[index] = items[index].copyWith(quantity: items[index].quantity - 1);
    }
    state = state.copyWith(items: items);
  }

  /// Removes an item from the cart entirely.
  void removeItem(String productId) {
    final items = state.items.where((i) => i.productId != productId).toList();
    state = state.copyWith(items: items);
  }

  /// Updates the amount paid by the customer.
  void setAmountPaid(int amount) {
    state = state.copyWith(amountPaid: amount);
  }

  /// Clears the cart back to empty state.
  void clear() {
    state = const CartState();
  }
}

final penjualanProvider = NotifierProvider<PenjualanNotifier, CartState>(
  PenjualanNotifier.new,
);

/// Handles the async save operation separately from cart state.
class TransactionSaveNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> save() async {
    final cart = ref.read(penjualanProvider);
    if (!cart.canFinish) return false;

    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      await ref.read(saleRepositoryProvider).createSale(
            items: cart.items,
            amountPaid: cart.amountPaid,
          );
    });
    state = result;
    return !result.hasError;
  }
}

final transactionSaveProvider =
    AsyncNotifierProvider<TransactionSaveNotifier, void>(
  TransactionSaveNotifier.new,
);
