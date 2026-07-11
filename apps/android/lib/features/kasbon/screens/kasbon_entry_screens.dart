import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/currency_formatter.dart';
import '../providers/kasbon_providers.dart';

/// Formats digits with Indonesian thousands separator (dot).
/// Display: "1.000", "10.000", "1.000.000"
/// Raw value (strips dots): "1000", "10000", "1000000"
class _ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Strip all non-digits
    final digits = newValue.text.replaceAll('.', '');
    if (digits.isEmpty) {
      return newValue.copyWith(text: '');
    }
    // Format with dots as thousands separator
    final formatted = _format(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  static String _format(String digits) {
    final buffer = StringBuffer();
    final n = digits.length;
    for (var i = 0; i < n; i++) {
      if (i > 0 && (n - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  /// Strip dots to get the raw integer string for parsing.
  static int parse(String formatted) =>
      int.tryParse(formatted.replaceAll('.', '')) ?? 0;
}

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
    final amount = _ThousandsSeparatorFormatter.parse(_amountController.text.trim());
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
    final balanceAsync =
        ref.watch(customerBalanceProvider(widget.customerId));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Catat Hutang',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            if (customerAsync.hasValue && customerAsync.value != null)
              Text(
                customerAsync.value!.name,
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
          ],
        ),
      ),
      body: entryState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Balance indicator
                    balanceAsync.when(
                      data: (balance) => _BalanceBanner(
                        balance: balance,
                        type: 'debt',
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 16),

                    _FormCard(
                      children: [
                        _FieldLabel('Jumlah Hutang'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            _ThousandsSeparatorFormatter()
                          ],
                          decoration: InputDecoration(
                            hintText: '0',
                            hintStyle:
                                TextStyle(color: Colors.grey[400]),
                            prefixText: 'Rp ',
                            prefixStyle: TextStyle(
                                fontSize: 16, color: Colors.grey[600]),
                            filled: true,
                            fillColor: const Color(0xFFF9F9F9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.grey[200]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.grey[200]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: colorScheme.primary, width: 1.5),
                            ),
                          ),
                          style: const TextStyle(fontSize: 18),
                          validator: (v) {
                            final n = _ThousandsSeparatorFormatter.parse(v ?? '');
                            if (n <= 0) {
                              return 'Masukkan jumlah yang valid';
                            }
                            return null;
                          },
                          autofocus: true,
                        ),
                        const SizedBox(height: 20),
                        _FieldLabel('Keterangan'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _noteController,
                          decoration: InputDecoration(
                            hintText: 'Opsional',
                            hintStyle:
                                TextStyle(color: Colors.grey[400]),
                            prefixIcon: const Icon(Icons.notes_rounded,
                                size: 20),
                            filled: true,
                            fillColor: const Color(0xFFF9F9F9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.grey[200]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.grey[200]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: colorScheme.primary, width: 1.5),
                            ),
                          ),
                          style: const TextStyle(fontSize: 16),
                          maxLines: 2,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.arrow_upward_rounded),
                        label: const Text('Simpan Hutang'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
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
    final amount = _ThousandsSeparatorFormatter.parse(_amountController.text.trim());
    final success = await ref.read(kasbonEntryProvider.notifier).addPayment(
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
    final balanceAsync =
        ref.watch(customerBalanceProvider(widget.customerId));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Catat Bayar',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            if (customerAsync.hasValue && customerAsync.value != null)
              Text(
                customerAsync.value!.name,
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
          ],
        ),
      ),
      body: entryState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    balanceAsync.when(
                      data: (balance) => _BalanceBanner(
                        balance: balance,
                        type: 'payment',
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 16),

                    _FormCard(
                      children: [
                        _FieldLabel('Jumlah Bayar'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            _ThousandsSeparatorFormatter()
                          ],
                          decoration: InputDecoration(
                            hintText: '0',
                            hintStyle:
                                TextStyle(color: Colors.grey[400]),
                            prefixText: 'Rp ',
                            prefixStyle: TextStyle(
                                fontSize: 16, color: Colors.grey[600]),
                            filled: true,
                            fillColor: const Color(0xFFF9F9F9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.grey[200]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.grey[200]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: colorScheme.primary, width: 1.5),
                            ),
                          ),
                          style: const TextStyle(fontSize: 18),
                          validator: (v) {
                            final n = _ThousandsSeparatorFormatter.parse(v ?? '');
                            if (n <= 0) {
                              return 'Masukkan jumlah yang valid';
                            }
                            return null;
                          },
                          autofocus: true,
                        ),
                        const SizedBox(height: 20),
                        _FieldLabel('Keterangan'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _noteController,
                          decoration: InputDecoration(
                            hintText: 'Opsional',
                            hintStyle:
                                TextStyle(color: Colors.grey[400]),
                            prefixIcon: const Icon(Icons.notes_rounded,
                                size: 20),
                            filled: true,
                            fillColor: const Color(0xFFF9F9F9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.grey[200]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.grey[200]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: colorScheme.primary, width: 1.5),
                            ),
                          ),
                          style: const TextStyle(fontSize: 16),
                          maxLines: 2,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.arrow_downward_rounded),
                        label: const Text('Simpan Bayar'),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
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

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------

class _BalanceBanner extends StatelessWidget {
  const _BalanceBanner({required this.balance, required this.type});
  final int balance;
  final String type;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasDebt = balance > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: hasDebt
            ? Colors.red[50]
            : colorScheme.primaryContainer.withAlpha(100),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasDebt
              ? Colors.red[100]!
              : colorScheme.primary.withAlpha(50),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Hutang saat ini',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          Text(
            balance == 0
                ? 'Lunas'
                : CurrencyFormatter.format(balance.abs()),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: hasDebt
                  ? Colors.red[600]
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

class _FormCard extends StatelessWidget {
  const _FormCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF555555),
      ),
    );
  }
}
