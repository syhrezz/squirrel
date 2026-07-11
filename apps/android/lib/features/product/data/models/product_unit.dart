/// Product unit options for the fixed dropdown.
///
/// Using a string-backed enum so stored values are human-readable
/// and future migrations won't break existing SQLite data.
enum ProductUnit {
  pcs('Pcs'),
  bungkus('Bungkus'),
  pack('Pack'),
  dus('Dus'),
  botol('Botol'),
  kaleng('Kaleng'),
  sachet('Sachet'),
  kg('Kg'),
  gram('Gram'),
  liter('Liter'),
  ml('Ml'),
  meter('Meter'),
  lembar('Lembar'),
  pasang('Pasang'),
  lainnya('Lainnya');

  const ProductUnit(this.label);

  /// Display label shown in the UI.
  final String label;

  /// The value stored in SQLite.
  String get value => name;

  /// Parse from stored SQLite string value.
  static ProductUnit fromValue(String value) {
    return ProductUnit.values.firstWhere(
      (u) => u.value == value,
      orElse: () => ProductUnit.lainnya,
    );
  }
}
