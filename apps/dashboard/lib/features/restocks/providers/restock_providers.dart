import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/env.dart';
import '../../../core/repositories/restock_explorer_repository.dart';
import '../models/restock_models.dart';

final _restockRepoProvider =
    Provider<RestockExplorerRepository>((ref) {
  return SupabaseRestockExplorerRepository(
    Supabase.instance.client,
    AppEnv.organizationId,
  );
});

// ---------------------------------------------------------------------------
// Filter notifier
// ---------------------------------------------------------------------------

class RestockFilterNotifier extends Notifier<RestockFilter> {
  @override
  RestockFilter build() => const RestockFilter();

  void setSearch(String v) =>
      state = state.copyWith(search: v, page: 0);
  void setPreset(RestockDatePreset v) =>
      state = state.copyWith(datePreset: v, page: 0);
  void setSort(RestockSortField f) {
    if (state.sortField == f) {
      state = state.copyWith(
        sortDir: state.sortDir == RestockSortDir.asc
            ? RestockSortDir.desc
            : RestockSortDir.asc,
        page: 0,
      );
    } else {
      state = state.copyWith(
          sortField: f, sortDir: RestockSortDir.desc, page: 0);
    }
  }

  void setPage(int v) => state = state.copyWith(page: v);
  void setPageSize(int v) =>
      state = state.copyWith(pageSize: v, page: 0);
  void reset() => state = const RestockFilter();
}

final restockFilterProvider =
    NotifierProvider<RestockFilterNotifier, RestockFilter>(
        RestockFilterNotifier.new);

// ---------------------------------------------------------------------------
// Restocks page
// ---------------------------------------------------------------------------

final restocksPageProvider =
    FutureProvider.autoDispose<RestockPageResult>((ref) async {
  final filter = ref.watch(restockFilterProvider);
  if (filter.search.isNotEmpty) {
    await Future.delayed(const Duration(milliseconds: 300));
    if (ref.read(restockFilterProvider).search !=
        filter.search) {
      throw Exception('debounced');
    }
  }
  return ref.read(_restockRepoProvider).getRestocks(filter);
});

// ---------------------------------------------------------------------------
// Detail
// ---------------------------------------------------------------------------

final restockDetailProvider =
    FutureProvider.autoDispose
        .family<RestockDetail, String>((ref, id) {
  return ref.read(_restockRepoProvider).getRestockDetail(id);
});

final purchaseHistoryProvider =
    FutureProvider.autoDispose
        .family<List<PurchaseHistoryPoint>, String>((ref, pid) {
  return ref.read(_restockRepoProvider).getPurchaseHistory(pid);
});

final purchaseSummaryProvider =
    FutureProvider.autoDispose<PurchaseSummary>((ref) {
  final filter = ref.watch(restockFilterProvider);
  return ref
      .read(_restockRepoProvider)
      .getPurchaseSummary(filter);
});
