import 'package:flutter/material.dart';
import '../../features/product/data/models/product_category.dart';

/// Horizontal scrolling row of category chips.
///
/// One chip per ProductCategory. Selected chip is filled green.
/// Tapping the already-selected chip deselects it (shows all).
/// Presentation-only — calls [onCategorySelected] with null to deselect.
class CategoryChipBar extends StatelessWidget {
  const CategoryChipBar({
    super.key,
    required this.selected,
    required this.onCategorySelected,
  });

  final ProductCategory? selected;
  final void Function(ProductCategory?) onCategorySelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: ProductCategory.values.length,
        itemBuilder: (context, index) {
          final category = ProductCategory.values[index];
          final isSelected = selected == category;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onCategorySelected(
                  isSelected ? null : category),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary
                      : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isSelected
                        ? colorScheme.primary
                        : Colors.grey[300]!,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color:
                                colorScheme.primary.withAlpha(40),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      category.icon,
                      size: 16,
                      color: isSelected
                          ? Colors.white
                          : Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      category.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
