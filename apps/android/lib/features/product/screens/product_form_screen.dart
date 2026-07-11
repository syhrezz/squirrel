import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/database/app_database.dart';
import '../data/models/product_category.dart';
import '../data/models/product_unit.dart';
import '../data/repositories/product_repository.dart';
import '../providers/product_providers.dart';

/// Product add / edit form.
///
/// Sections:
/// 1. General — name, category, inventory unit
/// 2. Purchase — purchase unit, conversion, last buy price
/// 3. Selling Options — list of options with display name, qty, price
/// 4. Advanced — allow manual price
class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({super.key, this.productId});
  final String? productId;

  @override
  ConsumerState<ProductFormScreen> createState() =>
      _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _buyPriceController = TextEditingController();
  final _conversionController = TextEditingController(text: '1');
  final _inventoryUnitController = TextEditingController(text: 'pcs');
  final _purchaseUnitController = TextEditingController(text: 'pcs');

  ProductUnit _selectedUnit = ProductUnit.pcs; // legacy unit field
  ProductCategory _selectedCategory = ProductCategory.lainnya;
  bool _allowManualPrice = false;
  bool _isLoaded = false;

  // Selling options list
  final List<_OptionRow> _options = [];

  bool get _isEditing => widget.productId != null;

  @override
  void dispose() {
    _nameController.dispose();
    _buyPriceController.dispose();
    _conversionController.dispose();
    _inventoryUnitController.dispose();
    _purchaseUnitController.dispose();
    for (final o in _options) o.dispose();
    super.dispose();
  }

  void _loadProduct(Product? product) {
    if (_isLoaded || product == null) return;
    _nameController.text = product.name;
    _buyPriceController.text = product.lastBuyPrice.toString();
    _conversionController.text = product.purchaseConversion.toString();
    _inventoryUnitController.text = product.inventoryUnit;
    _purchaseUnitController.text = product.purchaseUnit;
    _selectedUnit = ProductUnit.fromValue(product.unit);
    _selectedCategory = ProductCategory.fromValue(product.category);
    _allowManualPrice = product.allowManualPrice;
    _isLoaded = true;
  }

  void _loadOptions(List<dynamic> options) {
    if (_options.isNotEmpty) return;
    for (final o in options) {
      _options.add(_OptionRow(
        id: o.id,
        initialName: o.displayName,
        initialQty: o.quantity.toString(),
        initialPrice: o.sellingPrice.toString(),
      ));
    }
    setState(() {});
  }

  void _addOption() {
    setState(() => _options.add(_OptionRow()));
  }

  void _removeOption(int index) {
    setState(() {
      _options[index].dispose();
      _options.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final conversionVal =
        int.tryParse(_conversionController.text.trim()) ?? 1;
    final buyPrice =
        int.tryParse(_buyPriceController.text.trim()) ?? 0;

    // Build selling options list
    final sellingOptions = <SellingOptionInput>[];
    for (var i = 0; i < _options.length; i++) {
      final o = _options[i];
      final qty = int.tryParse(o.qtyController.text.trim()) ?? 0;
      final price = int.tryParse(o.priceController.text.trim()) ?? 0;
      if (o.nameController.text.trim().isNotEmpty && qty > 0 && price > 0) {
        sellingOptions.add(SellingOptionInput(
          id: o.id,
          displayName: o.nameController.text.trim(),
          inventoryQuantity: qty,
          sellingPrice: price,
          displayOrder: i,
        ));
      }
    }

    // Use first selling option price as sellPrice, or lastBuyPrice if none
    final sellPrice = sellingOptions.isNotEmpty
        ? sellingOptions.first.sellingPrice
        : buyPrice;

    await ref.read(productFormProvider.notifier).save(
          existingId: widget.productId,
          name: _nameController.text.trim(),
          unit: _selectedUnit.value,
          customUnit: null,
          sellPrice: sellPrice,
          lastBuyPrice: buyPrice,
          category: _selectedCategory.value,
          inventoryUnit: _inventoryUnitController.text.trim().isEmpty
              ? 'pcs'
              : _inventoryUnitController.text.trim(),
          purchaseUnit: _purchaseUnitController.text.trim().isEmpty
              ? 'pcs'
              : _purchaseUnitController.text.trim(),
          purchaseConversion: conversionVal,
          allowManualPrice: _allowManualPrice,
          sellingOptions: sellingOptions,
        );

    if (mounted && !ref.read(productFormProvider).hasError) {
      context.pop();
    }
  }

  Future<void> _confirmDeactivate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Colors.red[600], size: 22),
            const SizedBox(width: 8),
            const Text('Nonaktifkan Produk?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Produk ini tidak akan muncul lagi di halaman penjualan.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Stok yang tersisa akan dibekukan. '
                      'Riwayat penjualan tetap tersimpan. '
                      'Produk bisa diaktifkan kembali kapan saja.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Nonaktifkan'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref
          .read(productFormProvider.notifier)
          .deactivate(widget.productId!);
      if (mounted) context.pop();
    }
  }

  InputDecoration _dec(String hint, {IconData? icon, String? prefix}) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400]),
      prefixIcon: icon != null ? Icon(icon, size: 20) : null,
      prefixText: prefix,
      prefixStyle: TextStyle(fontSize: 15, color: Colors.grey[600]),
      filled: true,
      fillColor: const Color(0xFFF9F9F9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final formState = ref.watch(productFormProvider);

    if (_isEditing) {
      final productAsync =
          ref.watch(productDetailProvider(widget.productId!));
      productAsync.whenData(_loadProduct);

      final optionsAsync =
          ref.watch(sellingOptionsProvider(widget.productId!));
      optionsAsync.whenData(_loadOptions);
    }

    final conversion =
        int.tryParse(_conversionController.text) ?? 1;
    final invUnit = _inventoryUnitController.text.trim().isEmpty
        ? 'pcs'
        : _inventoryUnitController.text.trim();
    final purUnit = _purchaseUnitController.text.trim().isEmpty
        ? 'pcs'
        : _purchaseUnitController.text.trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Text(
          _isEditing ? 'Edit Produk' : 'Tambah Produk',
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ),
      body: formState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Section 1: General ──────────────────────────────────
                  _SectionCard(
                    title: 'INFORMASI PRODUK',
                    children: [
                      _Label('Nama Produk'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        decoration: _dec('Contoh: Indomie Goreng',
                            icon: Icons.inventory_2_rounded),
                        style: const TextStyle(fontSize: 16),
                        textCapitalization: TextCapitalization.words,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Nama tidak boleh kosong'
                                : null,
                      ),
                      const SizedBox(height: 16),
                      _Label('Kategori'),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<ProductCategory>(
                        value: _selectedCategory,
                        decoration: _dec(''),
                        items: ProductCategory.values
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Row(children: [
                                    Icon(c.icon, size: 16,
                                        color: Colors.grey[600]),
                                    const SizedBox(width: 8),
                                    Text(c.label),
                                  ]),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _selectedCategory = v);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      _Label('Satuan Stok (Inventory Unit)'),
                      const SizedBox(height: 4),
                      Text(
                        'Unit internal penyimpanan stok. Contoh: pcs, gram, ml, butir',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _inventoryUnitController,
                        decoration: _dec('pcs',
                            icon: Icons.straighten_rounded),
                        style: const TextStyle(fontSize: 16),
                        onChanged: (_) => setState(() {}),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Wajib diisi'
                                : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Section 2: Purchase ─────────────────────────────────
                  _SectionCard(
                    title: 'PEMBELIAN DARI SUPPLIER',
                    children: [
                      _Label('Satuan Beli (Purchase Unit)'),
                      const SizedBox(height: 4),
                      Text(
                        'Unit yang dipakai saat beli dari supplier. Contoh: Dus, Pack, Karung',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _purchaseUnitController,
                        decoration: _dec('Dus',
                            icon: Icons.shopping_bag_rounded),
                        style: const TextStyle(fontSize: 16),
                        onChanged: (_) => setState(() {}),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Wajib diisi'
                                : null,
                      ),
                      const SizedBox(height: 16),
                      _Label('Konversi'),
                      const SizedBox(height: 4),
                      Text(
                        '1 $purUnit berisi berapa $invUnit?',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _conversionController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: _dec('1'),
                        style: const TextStyle(fontSize: 16),
                        onChanged: (_) => setState(() {}),
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          if (n == null || n < 1) {
                            return 'Minimal 1';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      // Conversion preview
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withAlpha(12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                size: 16, color: colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              '1 $purUnit = $conversion $invUnit',
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _Label('Harga Beli Terakhir'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _buyPriceController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: _dec('0', prefix: 'Rp '),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Section 3: Selling Options ──────────────────────────
                  _SectionCard(
                    title: 'OPSI JUAL',
                    children: [
                      Text(
                        'Tambahkan satu atau lebih cara jual produk ini. '
                        'Contoh untuk Gula: "500 gram", "1 kg".',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 12),
                      if (_options.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Belum ada opsi. Tambahkan minimal satu.',
                            style: TextStyle(
                                fontSize: 13, color: Colors.orange[700]),
                          ),
                        ),
                      ..._options.asMap().entries.map((entry) {
                        final i = entry.key;
                        final o = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _OptionEditor(
                            option: o,
                            index: i,
                            inventoryUnit: invUnit,
                            onRemove: () => _removeOption(i),
                            onChanged: () => setState(() {}),
                          ),
                        );
                      }),
                      OutlinedButton.icon(
                        onPressed: _addOption,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Tambah Opsi Jual'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 44),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Section 4: Advanced ─────────────────────────────────
                  _SectionCard(
                    title: 'PENGATURAN LANJUTAN',
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Harga bisa diubah saat transaksi',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'Aktifkan untuk produk dengan harga fleksibel seperti beras atau gula curah.',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[500]),
                        ),
                        value: _allowManualPrice,
                        onChanged: (v) =>
                            setState(() => _allowManualPrice = v),
                        activeColor: colorScheme.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save_rounded),
                      label: Text(_isEditing
                          ? 'Simpan Perubahan'
                          : 'Tambah Produk'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  if (formState.hasError) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Gagal menyimpan: ${formState.error}',
                      style: const TextStyle(
                          color: Colors.red, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  // Deactivate button — only shown when editing
                  if (_isEditing) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _confirmDeactivate,
                        icon: Icon(Icons.block_rounded,
                            size: 18, color: Colors.red[600]),
                        label: Text(
                          'Nonaktifkan Produk',
                          style: TextStyle(
                              color: Colors.red[600],
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: Colors.red[300]!),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Option row state holder
// ---------------------------------------------------------------------------

class _OptionRow {
  _OptionRow({
    this.id,
    String initialName = '',
    String initialQty = '',
    String initialPrice = '',
  })  : nameController =
            TextEditingController(text: initialName),
        qtyController =
            TextEditingController(text: initialQty),
        priceController =
            TextEditingController(text: initialPrice);

  final String? id;
  final TextEditingController nameController;
  final TextEditingController qtyController;
  final TextEditingController priceController;

  void dispose() {
    nameController.dispose();
    qtyController.dispose();
    priceController.dispose();
  }
}

// ---------------------------------------------------------------------------
// Option editor widget
// ---------------------------------------------------------------------------

class _OptionEditor extends StatelessWidget {
  const _OptionEditor({
    required this.option,
    required this.index,
    required this.inventoryUnit,
    required this.onRemove,
    required this.onChanged,
  });

  final _OptionRow option;
  final int index;
  final String inventoryUnit;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  InputDecoration _dec(BuildContext context, String hint,
      {String? prefix, String? suffix}) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
      prefixText: prefix,
      suffixText: suffix,
      prefixStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
      suffixStyle: TextStyle(color: Colors.grey[500], fontSize: 12),
      filled: true,
      fillColor: const Color(0xFFF9F9F9),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            BorderSide(color: colorScheme.primary, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primary.withAlpha(8),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: colorScheme.primary.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Opsi ${index + 1}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onRemove,
                child: Icon(Icons.close_rounded,
                    size: 18, color: Colors.grey[400]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: option.nameController,
            decoration:
                _dec(context, 'Nama tampilan, e.g. "500 gram"'),
            style: const TextStyle(fontSize: 14),
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: option.qtyController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly
                  ],
                  decoration: _dec(context, '0',
                      suffix: inventoryUnit),
                  style: const TextStyle(fontSize: 14),
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: option.priceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly
                  ],
                  decoration:
                      _dec(context, '0', prefix: 'Rp '),
                  style: const TextStyle(fontSize: 14),
                  onChanged: (_) => onChanged(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared small widgets
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  const _SectionCard(
      {required this.title, required this.children});
  final String title;
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
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey[500],
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.label);
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
