import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/database/app_database.dart';
import '../providers/kasbon_providers.dart';

class CustomerDetailScreen extends ConsumerWidget {
  const CustomerDetailScreen({super.key, required this.customerId});
  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(customerDetailProvider(customerId));
    final balanceAsync = ref.watch(customerBalanceProvider(customerId));
    final txAsync = ref.watch(debtTransactionsProvider(customerId));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: customerAsync.when(
          data: (c) => Text(
            c?.name ?? '',
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: Color(0xFF1A1A1A),
            ),
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const Text('Pelanggan'),
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
                child: Icon(Icons.edit_rounded,
                    size: 18, color: colorScheme.primary),
              ),
              tooltip: 'Edit Pelanggan',
              onPressed: () =>
                  context.push('/kasbon/$customerId/edit'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _BalanceCard(
            balanceAsync: balanceAsync,
            customerAsync: customerAsync,
          ),
          Expanded(
            child: txAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Gagal memuat transaksi: $e',
                    style: TextStyle(color: Colors.grey[500])),
              ),
              data: (transactions) {
                if (transactions.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long_rounded,
                              size: 56, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada transaksi.',
                            style: TextStyle(
                                fontSize: 15, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding:
                      const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _TransactionCard(tx: tx),
                    );
                  },
                );
              },
            ),
          ),
          _ActionBar(customerId: customerId),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.balanceAsync,
    required this.customerAsync,
  });

  final AsyncValue<int> balanceAsync;
  final AsyncValue<Customer?> customerAsync;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return balanceAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (balance) {
        final hasDebt = balance > 0;
        final isCredit = balance < 0;

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: hasDebt
                      ? Colors.red[50]
                      : colorScheme.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  hasDebt
                      ? Icons.arrow_upward_rounded
                      : Icons.check_circle_rounded,
                  size: 24,
                  color: hasDebt
                      ? Colors.red[400]
                      : colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sisa Hutang',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      balance == 0
                          ? 'Lunas'
                          : CurrencyFormatter.format(balance.abs()),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: hasDebt
                            ? Colors.red[600]
                            : isCredit
                                ? colorScheme.primary
                                : Colors.grey[600],
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (balance != 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: hasDebt ? Colors.red[50] : Colors.green[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    hasDebt ? 'Berhutang' : 'Lebih bayar',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: hasDebt
                          ? Colors.red[600]
                          : colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.tx});
  final DebtTransaction tx;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDebt = tx.type == 'debt';
    final dt = DateTime.fromMillisecondsSinceEpoch(tx.createdAt);
    final dateStr =
        '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isDebt ? Colors.red[50] : Colors.green[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isDebt
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              size: 18,
              color: isDebt ? Colors.red[400] : Colors.green[600],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDebt ? 'Hutang' : 'Bayar',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                if (tx.note != null && tx.note!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      tx.note!,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[500]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    dateStr,
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey[400]),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isDebt ? '+' : '-'} ${CurrencyFormatter.format(tx.amount)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDebt ? Colors.red[600] : colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.customerId});
  final String customerId;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () =>
                  context.push('/kasbon/$customerId/bayar'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                side: BorderSide(color: colorScheme.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Catat Bayar',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () =>
                  context.push('/kasbon/$customerId/hutang'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Catat Hutang',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
