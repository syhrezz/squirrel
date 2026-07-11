import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/error_retry.dart';
import '../../../shared/widgets/product_search_field.dart';
import '../providers/kasbon_providers.dart';
import '../models/customer_with_balance.dart';

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});

  @override
  ConsumerState<CustomerListScreen> createState() =>
      _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersWithBalanceProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colorScheme.primary.withAlpha(18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.people_rounded,
                  size: 18, color: colorScheme.primary),
            ),
            const SizedBox(width: 10),
            const Text(
              'Kasbon',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.person_add_rounded,
                    size: 18, color: colorScheme.primary),
              ),
              tooltip: 'Tambah Pelanggan',
              onPressed: () => context.push('/kasbon/tambah'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          ProductSearchField(
            controller: _searchController,
            onChanged: (v) =>
                setState(() => _searchQuery = v.trim().toLowerCase()),
            onClear: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
            hasQuery: _searchQuery.isNotEmpty,
          ),
          Expanded(
            child: customersAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorRetry(
                onRetry: () =>
                    ref.invalidate(customersWithBalanceProvider),
              ),
              data: (customers) {
                final filtered = _searchQuery.isEmpty
                    ? customers
                    : customers
                        .where((c) => c.customer.name
                            .toLowerCase()
                            .contains(_searchQuery))
                        .toList();

                if (customers.isEmpty) {
                  return _EmptyState(
                    onAddTap: () => context.push('/kasbon/tambah'),
                  );
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded,
                              size: 56, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'Pelanggan "$_searchQuery" tidak ditemukan.',
                            style: TextStyle(
                                fontSize: 15, color: Colors.grey[500]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _CustomerCard(
                        item: item,
                        onTap: () => context
                            .push('/kasbon/${item.customer.id}'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.item, required this.onTap});

  final CustomerWithBalance item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasDebt = item.balance > 0;
    final isCredit = item.balance < 0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: hasDebt
                        ? Colors.red[50]
                        : colorScheme.primary.withAlpha(15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    size: 22,
                    color: hasDebt
                        ? Colors.red[400]
                        : colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.customer.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      if (item.customer.phone != null &&
                          item.customer.phone!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            item.customer.phone!,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500]),
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      item.balance == 0
                          ? 'Lunas'
                          : CurrencyFormatter.format(item.balance.abs()),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: hasDebt
                            ? Colors.red[600]
                            : isCredit
                                ? colorScheme.primary
                                : Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasDebt
                          ? 'Hutang'
                          : isCredit
                              ? 'Lebih bayar'
                              : 'Tidak ada hutang',
                      style: TextStyle(
                        fontSize: 11,
                        color: hasDebt
                            ? Colors.red[400]
                            : Colors.grey[400],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded,
                    color: Colors.grey[300], size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAddTap});
  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.primary.withAlpha(12),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(Icons.people_outline_rounded,
                  size: 40,
                  color: colorScheme.primary.withAlpha(100)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Belum ada pelanggan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tambahkan pelanggan untuk mulai\nmencatat kasbon.',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onAddTap,
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Tambah Pelanggan'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
