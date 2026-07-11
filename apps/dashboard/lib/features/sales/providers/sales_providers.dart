import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/env.dart';
import '../../../core/repositories/sales_explorer_repository.dart';
import '../models/sales_models.dart';

final _salesRepoProvider = Provider<SalesExplorerRepository>((ref) {
  return SupabaseSalesExplorerRepository(
    Supabase.instance.client,
    AppEnv.organizationId,
  );
});

// ---------------------------------------------------------------------------
// Filter state notifier
// ---------------------------------------------------------------------------

class SalesFilterNotifier extends Notifier<SalesFilter> {
  @override
  SalesFilter build() => const SalesFilter();

  void setSearch(String value) {
    state = state.copyWith(search: value, page: 0);
  }

  void setDatePreset(DateRangePreset preset) {
    state = state.copyWith(
        datePreset: preset, page: 0, clearDateRange: true);
  }

  void setSort(SalesSortField field) {
    if (state.sortField == field) {
      state = state.copyWith(
        sortDirection: state.sortDirection == SortDirection.asc
            ? SortDirection.desc
            : SortDirection.asc,
        page: 0,
      );
    } else {
      state = state.copyWith(
          sortField: field,
          sortDirection: SortDirection.desc,
          page: 0);
    }
  }

  void setPage(int page) {
    state = state.copyWith(page: page);
  }

  void setPageSize(int size) {
    state = state.copyWith(pageSize: size, page: 0);
  }

  void resetFilters() {
    state = const SalesFilter();
  }
}

final salesFilterProvider =
    NotifierProvider<SalesFilterNotifier, SalesFilter>(
        SalesFilterNotifier.new);

// ---------------------------------------------------------------------------
// Sales page — debounced fetch
// ---------------------------------------------------------------------------

final salesPageProvider =
    FutureProvider.autoDispose<SalesPageResult>((ref) async {
  final filter = ref.watch(salesFilterProvider);

  // Debounce search input by 300ms
  if (filter.search.isNotEmpty) {
    await Future.delayed(const Duration(milliseconds: 300));
    final currentFilter = ref.read(salesFilterProvider);
    if (currentFilter.search != filter.search) {
      throw Exception('debounced');
    }
  }

  return ref.read(_salesRepoProvider).getSales(filter);
});

// ---------------------------------------------------------------------------
// Sale detail
// ---------------------------------------------------------------------------

final saleDetailProvider =
    FutureProvider.autoDispose.family<SaleDetail, String>(
        (ref, saleId) {
  return ref.read(_salesRepoProvider).getSaleDetail(saleId);
});
