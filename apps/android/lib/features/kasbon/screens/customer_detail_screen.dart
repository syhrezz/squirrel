import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/database/app_database.dart';
import '../providers/kasbon_providers.dart';

/// Customer detail screen.
///
/// Shows customer info, outstanding balance, and full transaction timeline.
/// Two action buttons: Record Debt, Record Payment.
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
        title: customerAsync.when(
          data: (c) => Text(c?.name ?? ''),
          loading: () => const Text(''),
          error: (_, s) => const Text('Pelanggan'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Edit Pelanggan',
            onPressed: () =>
                context.push('/kasbon/$customerId/edit'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Balance header card
          _BalanceHeader(
            customerId: customerId,
            balanceAsync: balanceAsync,
            customerAsync: customerAsync,
          ),

          // Timeline
          Expanded(
            child: txAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Gagal memuat transaksi: $e'),
              ),
              data: (transactions) {
                if (transactions.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_long_rounded,
                            size: 56,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Belum ada transaksi kasbon.',
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: transactions.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) =>
                      _TransactionCard(tx: transactions[index]),
                );
              },
            ),
          ),

          // Action buttons
          _ActionButtons(customerId: customerId),
        ],
      ),
    );
  }
}

class _BalanceHeader extends StatelessWidget {
  const _BalanceHeader({
    required this.customerId,
    required this.balanceAsync,
    required this.customerAsync,
  });

  final String customerId;
  final AsyncValue<int> balanceAsync;
  final AsyncValue<Customer?> customerAsync;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final balance = balanceAsync.when(
      data: (v) => v,
      loading: () => 0,
      error: (e, s) => 0,
    );
    final hasDebt = balance > 0;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: hasDebt
                    ? colorScheme.errorContainer
                    : colorScheme.primaryContainer,
                child: Text(
                  () {
                    final c = customerAsync.hasValue ? customerAsync.value : null;
                    return (c?.name.isNotEmpty == true)
                        ? c!.name[0].toUpperCase()
                        : '?';
                  }(),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: hasDebt
                        ? colorScheme.onErrorContainer
                        : colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerAsync.hasValue
                          ? (customerAsync.value?.name ?? '')
                          : '',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (customerAsync.hasValue &&
                        customerAsync.value?.phone != null)
                      Text(
                        customerAsync.value!.phone!,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: hasDebt
                  ? colorScheme.errorContainer.withAlpha(120)
                  : colorScheme.primaryContainer.withAlpha(120),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  balance > 0
                      ? 'Hutang Saat Ini'
                      : balance < 0
                          ? 'Lebih Bayar'
                          : 'Status',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  balance == 0
                      ? 'Lunas'
                      : CurrencyFormatter.format(balance.abs()),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                    color: hasDebt
                        ? colorScheme.error
                        : balance < 0
                            ? colorScheme.primary
                            : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
        '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDebt
                  ? colorScheme.errorContainer
                  : colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isDebt
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              size: 20,
              color: isDebt
                  ? colorScheme.onErrorContainer
                  : colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDebt ? 'Hutang' : 'Pembayaran',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (tx.note != null && tx.note!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    tx.note!,
                    style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  dateStr,
                  style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Text(
            '${isDebt ? '+' : '-'}${CurrencyFormatter.format(tx.amount)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDebt ? colorScheme.error : colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.customerId});
  final String customerId;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () =>
                  context.push('/kasbon/$customerId/bayar'),
              icon: const Icon(Icons.arrow_downward_rounded),
              label: const Text('Catat Bayar'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () =>
                  context.push('/kasbon/$customerId/hutang'),
              icon: const Icon(Icons.arrow_upward_rounded),
              label: const Text('Catat Hutang'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
