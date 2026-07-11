import 'package:flutter/material.dart';

/// A search TextField for local product filtering.
///
/// Visual redesign: filled Material 3 style (consistent with the
/// global InputDecorationTheme), rounded corners, softer feel.
class ProductSearchField extends StatelessWidget {
  const ProductSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.hasQuery,
  });

  final TextEditingController controller;
  final void Function(String) onChanged;
  final VoidCallback onClear;
  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Cari produk...',
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.grey[500],
            size: 22,
          ),
          suffixIcon: hasQuery
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: Colors.grey[600],
                  onPressed: onClear,
                )
              : null,
          // Inherit filled style from global InputDecorationTheme
        ),
        style: const TextStyle(fontSize: 16),
        textInputAction: TextInputAction.search,
      ),
    );
  }
}
