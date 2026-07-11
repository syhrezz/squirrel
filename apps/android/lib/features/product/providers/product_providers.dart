import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/providers/database_providers.dart';

/// Watches the full list of active products.
final productListProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(productRepositoryProvider).watchAll();
});

/// Watches a single product by id.
final productDetailProvider =
    StreamProvider.family<Product?, String>((ref, id) {
  return ref.watch(productRepositoryProvider).watchById(id);
});

/// Handles create/update operations and exposes async state.
///
/// In Riverpod 3.x, AsyncNotifier is auto-dispose by default.
class ProductFormNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> save({
    String? existingId,
    required String name,
    required String unit,
    String? customUnit,
    required int sellPrice,
    required int lastBuyPrice,
  }) async {
    state = const AsyncLoading();

    final companion = ProductsCompanion(
      name: Value(name),
      unit: Value(unit),
      customUnit: Value(customUnit),
      sellPrice: Value(sellPrice),
      lastBuyPrice: Value(lastBuyPrice),
    );

    state = await AsyncValue.guard(() async {
      final repo = ref.read(productRepositoryProvider);
      if (existingId == null) {
        await repo.create(companion);
      } else {
        await repo.update(existingId, companion);
      }
    });
  }

  Future<void> deactivate(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(productRepositoryProvider).deactivate(id);
    });
  }
}

final productFormProvider =
    AsyncNotifierProvider<ProductFormNotifier, void>(
  ProductFormNotifier.new,
);
