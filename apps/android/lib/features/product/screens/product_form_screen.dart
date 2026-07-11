import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/models/product_unit.dart';
import '../providers/product_providers.dart';

/// Product add / edit form — internal administration tooling.
///
/// This screen is NOT part of the operator workflow.
/// Operators will never see this screen during daily operations.
///
/// When [productId] is null, creates a new product.
/// When [productId] is provided, loads and edits the existing product.
class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({super.key, this.productId});

  final String? productId;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _sellPriceController = TextEditingController();
  final _buyPriceController = TextEditingController();
  final _customUnitController = TextEditingController();

  ProductUnit _selectedUnit = ProductUnit.pcs;
  bool _isLoaded = false;

  bool get _isEditing => widget.productId != null;

  @override
  void dispose() {
    _nameController.dispose();
    _sellPriceController.dispose();
    _buyPriceController.dispose();
    _customUnitController.dispose();
    super.dispose();
  }

  void _loadProduct(AsyncValue productAsync) {
    if (_isLoaded) return;
    if (!productAsync.hasValue) return;
    final product = productAsync.value;
    if (product == null) return;

    _nameController.text = product.name;
    _sellPriceController.text = product.sellPrice.toString();
    _buyPriceController.text = product.lastBuyPrice.toString();
    _selectedUnit = ProductUnit.fromValue(product.unit);
    if (product.customUnit != null) {
      _customUnitController.text = product.customUnit!;
    }
    _isLoaded = true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final sellPrice = int.tryParse(_sellPriceController.text.trim()) ?? 0;
    final buyPrice = int.tryParse(_buyPriceController.text.trim()) ?? 0;

    await ref.read(productFormProvider.notifier).save(
          existingId: widget.productId,
          name: _nameController.text.trim(),
          unit: _selectedUnit.value,
          customUnit: _selectedUnit == ProductUnit.lainnya
              ? _customUnitController.text.trim()
              : null,
          sellPrice: sellPrice,
          lastBuyPrice: buyPrice,
        );

    if (mounted) context.pop();
  }

  Future<void> _confirmDeactivate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nonaktifkan Produk?'),
        content: const Text(
          'Produk tidak akan ditampilkan lagi. '
          'Data penjualan yang sudah ada tidak akan terhapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Nonaktifkan',
              style: TextStyle(color: Colors.red),
            ),
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

  @override
  Widget build(BuildContext context) {
    // Watch product for pre-fill when editing
    final productAsync = _isEditing
        ? ref.watch(productDetailProvider(widget.productId!))
        : const AsyncData(null);

    if (_isEditing) _loadProduct(productAsync);

    final formState = ref.watch(productFormProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        title: Text(_isEditing ? 'Edit Produk' : 'Tambah Produk'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Nonaktifkan',
              onPressed: _confirmDeactivate,
            ),
        ],
      ),
      body: formState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Name
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nama Produk',
                        hintText: 'Contoh: Indomie Goreng',
                      ),
                      style: const TextStyle(fontSize: 16),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Nama produk wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),

                    // Unit dropdown
                    DropdownButtonFormField<ProductUnit>(
                      initialValue: _selectedUnit,
                      decoration: const InputDecoration(labelText: 'Satuan'),
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                      items: ProductUnit.values
                          .map(
                            (u) => DropdownMenuItem(
                              value: u,
                              child: Text(u.label),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedUnit = v);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Custom unit — only visible when lainnya is selected
                    if (_selectedUnit == ProductUnit.lainnya) ...[
                      TextFormField(
                        controller: _customUnitController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Satuan Lainnya',
                          hintText: 'Contoh: Ikat, Buah',
                        ),
                        style: const TextStyle(fontSize: 16),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Nama satuan wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Sell price
                    TextFormField(
                      controller: _sellPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Harga Jual (Rp)',
                        hintText: 'Contoh: 3500',
                        prefixText: 'Rp ',
                      ),
                      style: const TextStyle(fontSize: 16),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Harga jual wajib diisi';
                        final n = int.tryParse(v.trim());
                        if (n == null || n <= 0) return 'Harga jual harus lebih dari 0';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Buy price
                    TextFormField(
                      controller: _buyPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Harga Beli Terakhir (Rp)',
                        hintText: 'Contoh: 2500',
                        prefixText: 'Rp ',
                        helperText:
                            'Harga beli aktual akan dicatat saat restock.',
                      ),
                      style: const TextStyle(fontSize: 16),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Harga beli wajib diisi';
                        final n = int.tryParse(v.trim());
                        if (n == null || n < 0) return 'Harga beli tidak valid';
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Save button
                    ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save),
                      label: Text(_isEditing ? 'Simpan Perubahan' : 'Tambah Produk'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),

                    // Show error if save failed
                    if (formState.hasError) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Gagal menyimpan: ${formState.error}',
                        style: const TextStyle(color: Colors.red, fontSize: 14),
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
