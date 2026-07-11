import 'package:intl/intl.dart';

/// Formats integer IDR amounts for display.
///
/// Input:  12500
/// Output: "Rp12.500"
///
/// All monetary values in this app are stored as integers (IDR, no decimals).
class CurrencyFormatter {
  CurrencyFormatter._();

  static final _formatter = NumberFormat('#,###', 'id_ID');

  /// Formats an integer amount as IDR display string.
  /// Example: 12500 → "Rp12.500"
  static String format(int amount) {
    // Indonesian locale uses dot as thousands separator
    return 'Rp${_formatter.format(amount)}';
  }

  /// Parses a display string back to integer.
  /// Example: "Rp12.500" → 12500
  /// Returns null if the string cannot be parsed.
  static int? parse(String value) {
    final cleaned = value.replaceAll('Rp', '').replaceAll('.', '').trim();
    return int.tryParse(cleaned);
  }
}
