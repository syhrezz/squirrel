import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/currency_formatter.dart';
import '../providers/kasbon_providers.dart';

/// Record a new debt entry for a customer.
///
/// Append-only — creates a new row in debt_transactions.
/// Never edits previous entries.
class RecordDebtScreen extends ConsumerStatefulWidget {
  const RecordDebtScreen({super.key, required this.customerId});
  final String customerId;

  @override
  ConsumerState<RecordDebtScreen> createState() => _RecordDebtScreenState();
}

class _RecordDebtScreenState extends ConsumerState<RecordDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = int.tryParse(_amountController.text.trim()) ?? 0;
    final success = await ref.read(kasbonEntryProvider.notifier).addDebt(
          customerId: widget.customerId,
          amount: amount,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        );
    if (mounted && success) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final entryState = ref.watch(kasbonEntryProvider);
    final customerAsync =
        ref.watch(customerDetailProvider(widget.customerId));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          customerAsync.hasValue && customerAsync.value?.name != null
              ? 'Catat Hutang — ${customerAsync.value!.name}'
              : 'Catat Hutang',
        ),
      ),
      body: entryState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Current balance display
                    _BalanceBanner(customerId: widget.customerId),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Jumlah Hutang (Rp)',
                        prefixText: 'Rp ',
                        hintText: '0',
                      ),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Jumlah wajib diisi';
                        }
                        final n = int.tryParse(v.trim());
                        if (n == null || n <= 0) {
                          return 'Jumlah harus lebih dari 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _noteController,
                      maxLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Catatan (opsional)',
                        hintText: 'Contoh: Beli beras 5kg',
                      ),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 32),

                    ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.arrow_upward_rounded),
                      label: const Text('Catat Hutang'),
                    ),

                    if (entryState.hasError) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Gagal menyimpan: ${entryState.error}',
                        style: const TextStyle(
                            color: Colors.red, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}

/// Record a new payment entry for a customer.
///
/// Append-only — creates a new row in debt_transactions.
/// Payment may exceed current balance — not blocked.
class RecordPaymentScreen extends ConsumerStatefulWidget {
  const RecordPaymentScreen({super.key, required this.customerId});
  final String customerId;

  @override
  ConsumerState<RecordPaymentScreen> createState() =>
      _RecordPaymentScreenState();
}

class _RecordPaymentScreenState
    extends ConsumerState<RecordPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = int.tryParse(_amountController.text.trim()) ?? 0;
    final success =
        await ref.read(kasbonEntryProvider.notifier).addPayment(
              customerId: widget.customerId,
              amount: amount,
              note: _noteController.text.trim().isEmpty
                  ? null
                  : _noteController.text.trim(),
            );
    if (mounted && success) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final entryState = ref.watch(kasbonEntryProvider);
    final customerAsync =
        ref.watch(customerDetailProvider(widget.customerId));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          customerAsync.hasValue && customerAsync.value?.name != null
              ? 'Catat Bayar — ${customerAsync.value!.name}'
              : 'Catat Pembayaran',
        ),
      ),
      body: entryState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _BalanceBanner(customerId: widget.customerId),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Jumlah Pembayaran (Rp)',
                        prefixText: 'Rp ',
                        hintText: '0',
                      ),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Jumlah wajib diisi';
                        }
                        final n = int.tryParse(v.trim());
                        if (n == null || n <= 0) {
                          return 'Jumlah harus lebih dari 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _noteController,
                      maxLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Catatan (opsional)',
                        hintText: 'Contoh: Bayar tunai',
                      ),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 32),

                    ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.arrow_downward_rounded),
                      label: const Text('Catat Pembayaran'),
                    ),

                    if (entryState.hasError) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Gagal menyimpan: ${entryState.error}',
                        style: const TextStyle(
                            color: Colors.red, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}

/// Shows current balance prominently above the amount input.
/// Helps operators see context before recording a transaction.
class _BalanceBanner extends ConsumerWidget {
  const _BalanceBanner({required this.customerId});
  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(customerBalanceProvider(customerId));
    final colorScheme = Theme.of(context).colorScheme;
    final balance = balanceAsync.when(
      data: (v) => v,
      loading: () => 0,
      error: (e, s) => 0,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: balance > 0
            ? colorScheme.errorContainer.withAlpha(120)
            : colorScheme.primaryContainer.withAlpha(120),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Hutang saat ini',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            balance == 0
                ? 'Lunas'
                : CurrencyFormatter.format(balance.abs()),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: balance > 0
                  ? colorScheme.error
                  : balance < 0
                      ? colorScheme.primary
                      : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
