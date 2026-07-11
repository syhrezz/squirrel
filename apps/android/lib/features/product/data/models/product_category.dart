import 'package:flutter/material.dart';

/// Product category for discovery browsing in the sales screen.
///
/// Stored as TEXT in SQLite — never as integer index.
enum ProductCategory {
  minuman('minuman', 'Minuman', Icons.local_drink_outlined),
  makanan('makanan', 'Makanan', Icons.restaurant_outlined),
  rokok('rokok', 'Rokok', Icons.smoking_rooms_outlined),
  bumbuDapur('bumbu_dapur', 'Bumbu Dapur', Icons.set_meal_outlined),
  berasDanPokok('beras_dan_pokok', 'Beras & Pokok', Icons.grain_outlined),
  kebutuhanRumah('kebutuhan_rumah', 'Kebutuhan Rumah', Icons.home_outlined),
  perawatanTubuh('perawatan_tubuh', 'Perawatan Tubuh', Icons.spa_outlined),
  lainnya('lainnya', 'Lainnya', Icons.category_outlined);

  const ProductCategory(this.value, this.label, this.icon);

  final String value;
  final String label;
  final IconData icon;

  static ProductCategory fromValue(String value) {
    return ProductCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ProductCategory.lainnya,
    );
  }
}
