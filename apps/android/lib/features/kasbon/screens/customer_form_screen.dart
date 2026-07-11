import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/kasbon_providers.dart';

/// Add or edit a customer.
///
/// Fields: name (required), phone (optional), note (optional).
class CustomerFormScreen extends ConsumerStatefulWidget {
  const CustomerFormScreen({super.key, this.customerId});
  final String? customerId;

  @override
  ConsumerState<CustomerFormScreen> createState() =>
      _CustomerFormScreenState();
}

class _CustomerFormScreenState
    extends ConsumerState<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isLoaded = false;

  bool get _isEditing => widget.customerId != null;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _preload(AsyncValue customerAsync) {
    if (_isLoaded) return;
    if (!customerAsync.hasValue) return;
    final customer = customerAsync.value;
    if (customer == null) return;
    _nameController.text = customer.name;
    _phoneController.text = customer.phone ?? '';
    _noteController.text = customer.note ?? '';
    _isLoaded = true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(customerFormProvider.notifier).save(
          existingId: widget.customerId,
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          note: _noteController.text.trim(),
        );
    if (mounted && success) context.pop();
  }

  Future<void> _confirmDeactivate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nonaktifkan Pelanggan?'),
        content: const Text(
          'Pelanggan tidak akan muncul lagi di daftar. '
          'Riwayat kasbon tetap tersimpan.',
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
          .read(customerFormProvider.notifier)
          .deactivate(widget.customerId!);
      if (mounted) context.go('/kasbon');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final customerAsync = _isEditing
        ? ref.watch(customerDetailProvider(widget.customerId!))
        : const AsyncData(null);
    if (_isEditing) _preload(customerAsync);
    final formState = ref.watch(customerFormProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        title: Text(_isEditing ? 'Edit Pelanggan' : 'Tambah Pelanggan'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.person_off_rounded),
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
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nama Pelanggan',
                        hintText: 'Contoh: Bu Sari',
                      ),
                      style: const TextStyle(fontSize: 16),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Nama pelanggan wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Nomor HP (opsional)',
                        hintText: 'Contoh: 08123456789',
                      ),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _noteController,
                      maxLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Catatan (opsional)',
                        hintText: 'Contoh: Tetangga RT 3',
                      ),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save_rounded),
                      label: Text(
                          _isEditing ? 'Simpan Perubahan' : 'Tambah Pelanggan'),
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
                  ],
                ),
              ),
            ),
    );
  }
}
