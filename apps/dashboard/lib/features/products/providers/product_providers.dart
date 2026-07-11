import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/env.dart';
import '../../../core/repositories/product_explorer_repository.dart';
import '../models/product_models.dart';

final _productRepoProvider =
    Provider<ProductExplorerRepository>((ref) {
  return SupabaseProductExplorerRepository(
    Supabase.instance.client,
    AppEnv.organizationId,
  );
});

// ---------------------------------------------------------------------------
// Filter notifier
// ---------------------------------------------------------------------------

class ProductFilterNotifier extends Notifier<ProductFilter> {
  @override
  ProductFilter build() => const ProductFilter();

  void setSearch(String v) =>
      state = state.copyWith(search: v, page: 0);
  void setCategory(String v) =>
      state = state.copyWith(category: v, page: 0);
  void setStatus(ProductStatusFilter v) =>
      state = state.copyWith(status: v, page: 0);
  void setStockFilter(ProductStockFilter v) =>
      state = state.copyWith(stockFilter: v, page: 0);
  void setPage(int v) => state = state.copyWith(page: v);
  void setPageSize(int v) =>
      state = state.copyWith(pageSize: v, page: 0);
  void setSort(ProductSortField field) {
    if (state.sortField == field) {
      state = state.copyWith(
          sortAscending: !state.sortAscending, page: 0);
    } else {
      state = state.copyWith(
          sortField: field,
          sortAscending: false,
          page: 0);
    }
  }

  void resetFilters() => state = const ProductFilter();
}

final productFilterProvider =
    NotifierProvider<ProductFilterNotifier, ProductFilter>(
        ProductFilterNotifier.new);

// ---------------------------------------------------------------------------
// Products page
// ---------------------------------------------------------------------------

final productsPageProvider =
    FutureProvider.autoDispose<ProductPageResult>((ref) async {
  final filter = ref.watch(productFilterProvider);
  if (filter.search.isNotEmpty) {
    await Future.delayed(const Duration(milliseconds: 300));
    if (ref.read(productFilterProvider).search !=
        filter.search) {
      throw Exception('debounced');
    }
  }
  return ref.read(_productRepoProvider).getProducts(filter);
});

// ---------------------------------------------------------------------------
// Product detail + related data
// ---------------------------------------------------------------------------

final productDetailProvider =
    FutureProvider.autoDispose
        .family<ProductExplorerDetail, String>((ref, id) {
  return ref.read(_productRepoProvider).getProductDetail(id);
});

final productRecentSalesProvider =
    FutureProvider.autoDispose
        .family<List<RecentProductSale>, String>((ref, id) {
  return ref
      .read(_productRepoProvider)
      .getRecentSales(id, limit: 20);
});

final productRecentRestocksProvider =
    FutureProvider.autoDispose
        .family<List<RecentProductRestock>, String>((ref, id) {
  return ref
      .read(_productRepoProvider)
      .getRecentRestocks(id, limit: 20);
});

final productInventoryTimelineProvider =
    FutureProvider.autoDispose
        .family<List<InventoryTimelinePoint>, String>((ref, id) {
  return ref
      .read(_productRepoProvider)
      .getInventoryTimeline(id);
});
