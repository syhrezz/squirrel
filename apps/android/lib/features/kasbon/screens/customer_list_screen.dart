import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/error_retry.dart';
import '../../../shared/widgets/product_search_field.dart';
import '../providers/kasbon_providers.dart';
import '../models/customer_with_balance.dart';

/// Customer list screen for Kasbon feature.
///
/// Displays all active customers with their outstanding balance
/// and most recent activity date. Sorted by latest activity first.
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
        title: const Text('Kasbon'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            tooltip: 'Tambah Pelanggan',
            onPressed: () => context.push('/kasbon/tambah'),
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
                  return _EmptyCustomerList(
                    onAddTap: () => context.push('/kasbon/tambah'),
                  );
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Pelanggan "$_searchQuery" tidak ditemukan.',
                        style: const TextStyle(
                            fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, indent: 16, endIndent: 16),
                  itemBuilder: (context, index) =>
                      _CustomerTile(item: filtered[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerTile extends StatelessWidget {
  const _CustomerTile({required this.item});
  final CustomerWithBalance item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final balance = item.balance;
    final hasDebt = balance > 0;

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: hasDebt
            ? colorScheme.errorContainer
            : colorScheme.primaryContainer,
        radius: 22,
        child: Text(
          item.customer.name.isNotEmpty
              ? item.customer.name[0].toUpperCase()
              : '?',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: hasDebt
                ? colorScheme.onErrorContainer
                : colorScheme.onPrimaryContainer,
          ),
        ),
      ),
      title: Text(
        item.customer.name,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: item.lastActivityAt != null
          ? Text(
              _formatDate(item.lastActivityAt!),
              style: const TextStyle(fontSize: 13),
            )
          : const Text(
              'Belum ada transaksi',
              style: TextStyle(fontSize: 13),
            ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            CurrencyFormatter.format(balance.abs()),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: balance > 0
                  ? colorScheme.error
                  : balance < 0
                      ? colorScheme.primary
                      : Colors.grey[600],
            ),
          ),
          Text(
            balance > 0
                ? 'Hutang'
                : balance < 0
                    ? 'Lebih bayar'
                    : 'Lunas',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      onTap: () =>
          context.push('/kasbon/${item.customer.id}'),
    );
  }

  String _formatDate(int epochMs) {
    final dt = DateTime.fromMillisecondsSinceEpoch(epochMs);
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _EmptyCustomerList extends StatelessWidget {
  const _EmptyCustomerList({required this.onAddTap});
  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum ada pelanggan.',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAddTap,
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Tambah Pelanggan'),
            ),
          ],
        ),
      ),
    );
  }
}
