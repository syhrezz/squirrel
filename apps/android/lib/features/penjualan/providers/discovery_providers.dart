import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/database/app_database.dart';
import '../../../shared/providers/database_providers.dart';
import '../../product/data/models/product_category.dart';

/// A product with its total sold quantity over the last 30 days.
class FrequentProduct {
  const FrequentProduct({
    required this.product,
    required this.totalSold,
  });
  final Product product;
  final int totalSold;
}

/// Top 8 products by quantity sold in the last 30 days.
///
/// Pure historical data — no AI, no prediction.
/// Empty list if no sales history exists.
final frequentlySoldProvider =
    FutureProvider<List<FrequentProduct>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final since = DateTime.now()
          .subtract(const Duration(days: 30))
          .millisecondsSinceEpoch;

  // Get all sale_items from sales in the last 30 days
  final recentSaleIds = await (db.select(db.sales)
        ..where((s) => s.createdAt.isBiggerOrEqualValue(since)))
      .map((s) => s.id)
      .get();

  if (recentSaleIds.isEmpty) return [];

  // Sum quantities per product
  final allItems = await (db.select(db.saleItems)
        ..where((si) => si.saleId.isIn(recentSaleIds)))
      .get();

  final quantityMap = <String, int>{};
  for (final item in allItems) {
    quantityMap[item.productId] =
        (quantityMap[item.productId] ?? 0) + item.quantity;
  }

  if (quantityMap.isEmpty) return [];

  // Sort by quantity descending, take top 8
  final sorted = quantityMap.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final top8 = sorted.take(8).toList();

  // Fetch product rows
  final results = <FrequentProduct>[];
  for (final entry in top8) {
    final product = await (db.select(db.products)
          ..where((p) =>
              p.id.equals(entry.key) & p.isActive.equals(true)))
        .getSingleOrNull();
    if (product != null) {
      results.add(FrequentProduct(
          product: product, totalSold: entry.value));
    }
  }

  return results;
});

/// Last 10 unique products sold on this device, most recent first.
///
/// Derived from sale_items joined with sales, ordered by sale timestamp.
final recentlySoldProvider =
    FutureProvider<List<Product>>((ref) async {
  final db = ref.watch(appDatabaseProvider);

  // Get recent sales ordered by time desc
  final recentSales = await (db.select(db.sales)
        ..orderBy([(s) => drift.OrderingTerm.desc(s.createdAt)])
        ..limit(50))
      .get();

  if (recentSales.isEmpty) return [];

  // Walk through sales and collect unique product ids in order
  final seenIds = <String>{};
  final uniqueProductIds = <String>[];

  for (final sale in recentSales) {
    if (uniqueProductIds.length >= 10) break;
    final items = await (db.select(db.saleItems)
          ..where((si) => si.saleId.equals(sale.id)))
        .get();
    for (final item in items) {
      if (!seenIds.contains(item.productId)) {
        seenIds.add(item.productId);
        uniqueProductIds.add(item.productId);
      }
      if (uniqueProductIds.length >= 10) break;
    }
  }

  // Fetch product rows in order
  final products = <Product>[];
  for (final id in uniqueProductIds) {
    final p = await (db.select(db.products)
          ..where((p) =>
              p.id.equals(id) & p.isActive.equals(true)))
        .getSingleOrNull();
    if (p != null) products.add(p);
  }

  return products;
});

/// All active products in a given category.
/// Family parameter is the category value string (e.g. 'minuman').
final productsByCategoryProvider =
    FutureProvider.family<List<Product>, String>(
        (ref, categoryValue) async {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.products)
        ..where((p) =>
            p.isActive.equals(true) &
            p.category.equals(categoryValue))
        ..orderBy([(p) => drift.OrderingTerm.asc(p.name)]))
      .get();
});
