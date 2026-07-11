import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/kasbon_providers.dart';

class CustomerFormScreen extends ConsumerStatefulWidget {
  const CustomerFormScreen({super.key, this.customerId});
  final String? customerId;

  @override
  ConsumerState<CustomerFormScreen> createState() =>
      _CustomerFormScreenState();
}

class _CustomerFormScreenState extends ConsumerState<CustomerFormScreen> {
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Nonaktifkan'),
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
    final formState = ref.watch(customerFormProvider);

    if (_isEditing) {
      final customerAsync =
          ref.watch(customerDetailProvider(widget.customerId!));
      _preload(customerAsync);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Text(
          _isEditing ? 'Edit Pelanggan' : 'Tambah Pelanggan',
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: Color(0xFF1A1A1A),
          ),
        ),
        actions: [
          if (_isEditing)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: Icon(Icons.person_off_rounded,
                    color: Colors.red[400], size: 22),
                tooltip: 'Nonaktifkan',
                onPressed: _confirmDeactivate,
              ),
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
                  children: [
                    _FormCard(
                      children: [
                        _FieldLabel('Nama Pelanggan'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          decoration: _inputDecoration(
                              'Wajib diisi', Icons.person_rounded),
                          style: const TextStyle(fontSize: 16),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Nama tidak boleh kosong'
                                  : null,
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 20),
                        _FieldLabel('Nomor HP'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _phoneController,
                          decoration: _inputDecoration(
                              'Opsional', Icons.phone_rounded),
                          style: const TextStyle(fontSize: 16),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 20),
                        _FieldLabel('Catatan'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _noteController,
                          decoration: _inputDecoration(
                              'Contoh: Tetangga RT 3',
                              Icons.notes_rounded),
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
                        icon: const Icon(Icons.save_rounded),
                        label: Text(_isEditing
                            ? 'Simpan Perubahan'
                            : 'Tambah Pelanggan'),
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
                  ],
                ),
              ),
            ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400]),
      prefixIcon: Icon(icon, size: 20),
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
        borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary, width: 1.5),
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
