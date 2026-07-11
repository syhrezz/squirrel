import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/providers/database_providers.dart';
import '../data/repositories/restock_repository.dart';
import '../models/shopping_item.dart';

/// Provides the [RestockRepository] backed by Drift.
final restockRepositoryProvider = Provider<RestockRepository>((ref) {
  return DriftRestockRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(syncRepositoryProvider),
  );
});

// ---------------------------------------------------------------------------
// Restock history
// ---------------------------------------------------------------------------

class RestockWithItems {
  const RestockWithItems({required this.restock, required this.items});
  final Restock restock;
  final List<RestockItem> items;

  int get totalAmount => restock.totalAmount;
}

/// Watches all restocks ordered newest first, with their items.
final restockHistoryProvider =
    StreamProvider<List<RestockWithItems>>((ref) async* {
  final db = ref.watch(appDatabaseProvider);

  await for (final restocks in (db.select(db.restocks)
        ..orderBy([(r) => drift.OrderingTerm.desc(r.createdAt)]))
      .watch()) {
    final result = <RestockWithItems>[];
    for (final r in restocks) {
      final items = await (db.select(db.restockItems)
            ..where((i) => i.restockId.equals(r.id)))
          .get();
      result.add(RestockWithItems(restock: r, items: items));
    }
    yield result;
  }
});

/// In-memory shopping session state.
///
/// Nothing is persisted until [RestockSaveNotifier.save] is called.
class ShoppingState {
  const ShoppingState({
    this.items = const [],
  });

  final List<ShoppingItem> items;

  int get totalAmount => items.fold<int>(0, (sum, i) => sum + i.subtotal);
  bool get canSave => items.isNotEmpty && items.every(
    (i) => i.quantity > 0 && i.purchasePrice > 0,
  );

  ShoppingState copyWith({List<ShoppingItem>? items}) =>
      ShoppingState(items: items ?? this.items);
}

/// Manages the in-memory shopping session.
///
/// Nothing is persisted until [RestockSaveNotifier.save] is called.
class RestockNotifier extends Notifier<ShoppingState> {
  @override
  ShoppingState build() => const ShoppingState();

  /// Adds a product to the shopping list.
  /// If it already exists, does nothing — user edits inline.
  void addProduct(ShoppingItem item) {
    final already = state.items.any((i) => i.productId == item.productId);
    if (already) return;
    state = state.copyWith(items: [...state.items, item]);
  }

  /// Updates quantity for an item. Quantity must be > 0.
  void setQuantity(String productId, int quantity) {
    if (quantity < 0) return;
    final items = state.items.map((i) {
      if (i.productId != productId) return i;
      return i.copyWith(quantity: quantity);
    }).toList();
    state = state.copyWith(items: items);
  }

  /// Updates purchase price for an item.
  void setPurchasePrice(String productId, int price) {
    if (price < 0) return;
    final items = state.items.map((i) {
      if (i.productId != productId) return i;
      return i.copyWith(purchasePrice: price);
    }).toList();
    state = state.copyWith(items: items);
  }

  /// Increases quantity by 1.
  void incrementQuantity(String productId) {
    final items = state.items.map((i) {
      if (i.productId != productId) return i;
      return i.copyWith(quantity: i.quantity + 1);
    }).toList();
    state = state.copyWith(items: items);
  }

  /// Decreases quantity by 1. Removes item if quantity reaches 0.
  void decrementQuantity(String productId) {
    final updated = state.items
        .map((i) {
          if (i.productId != productId) return i;
          return i.copyWith(quantity: i.quantity - 1);
        })
        .where((i) => i.quantity > 0)
        .toList();
    state = state.copyWith(items: updated);
  }

  /// Removes an item from the shopping list.
  void removeItem(String productId) {
    state = state.copyWith(
      items: state.items.where((i) => i.productId != productId).toList(),
    );
  }

  /// Clears the session back to empty.
  void clear() => state = const ShoppingState();
}

final restockProvider = NotifierProvider<RestockNotifier, ShoppingState>(
  RestockNotifier.new,
);

/// Handles the async save operation.
class RestockSaveNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> save() async {
    final shopping = ref.read(restockProvider);
    if (!shopping.canSave) return false;

    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      await ref.read(restockRepositoryProvider).createRestock(
            items: shopping.items,
          );
    });
    state = result;
    return !result.hasError;
  }
}

final restockSaveProvider =
    AsyncNotifierProvider<RestockSaveNotifier, void>(
  RestockSaveNotifier.new,
);
