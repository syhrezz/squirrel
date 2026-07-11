import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/providers/database_providers.dart';
import '../data/repositories/product_repository.dart';

/// Watches the full list of active products.
final productListProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(productRepositoryProvider).watchAll();
});

/// Watches a single product by id.
final productDetailProvider =
    StreamProvider.family<Product?, String>((ref, id) {
  return ref.watch(productRepositoryProvider).watchById(id);
});

/// Watches selling options for a product.
final sellingOptionsProvider =
    StreamProvider.family<List<ProductSellingOption>, String>(
        (ref, productId) {
  return ref.watch(productRepositoryProvider).watchSellingOptions(productId);
});

/// Handles create/update/selling-options save operations.
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
    required String category,
    required String inventoryUnit,
    required String purchaseUnit,
    required int purchaseConversion,
    required bool allowManualPrice,
    required List<SellingOptionInput> sellingOptions,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final repo = ref.read(productRepositoryProvider);

      final companion = ProductsCompanion(
        name: Value(name),
        unit: Value(unit),
        customUnit: Value(customUnit),
        sellPrice: Value(sellPrice),
        lastBuyPrice: Value(lastBuyPrice),
        category: Value(category),
        inventoryUnit: Value(inventoryUnit),
        purchaseUnit: Value(purchaseUnit),
        purchaseConversion: Value(purchaseConversion),
        allowManualPrice: Value(allowManualPrice),
      );

      late String productId;
      if (existingId == null) {
        final product = await repo.create(companion);
        productId = product.id;
      } else {
        productId = existingId;
        await repo.update(existingId, companion);
      }

      if (sellingOptions.isNotEmpty) {
        await repo.saveSellingOptions(productId, sellingOptions);
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
