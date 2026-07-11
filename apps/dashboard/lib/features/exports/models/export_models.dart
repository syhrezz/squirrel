import 'package:intl/intl.dart';

enum ExportFormat { csv, excel, pdf }
enum ExportStatus { pending, running, completed, failed }
enum ExportModule {
  sales,
  products,
  restocks,
  customers,
  kasbon,
  inventory,
  analyticsSummary,
  businessHealth,
}

extension ExportModuleLabel on ExportModule {
  String get label => switch (this) {
        ExportModule.sales => 'Penjualan',
        ExportModule.products => 'Produk',
        ExportModule.restocks => 'Restock Barang',
        ExportModule.customers => 'Pelanggan',
        ExportModule.kasbon => 'Kasbon',
        ExportModule.inventory => 'Inventori',
        ExportModule.analyticsSummary => 'Ringkasan Analitik',
        ExportModule.businessHealth => 'Kesehatan Bisnis',
      };

  String get description => switch (this) {
        ExportModule.sales => 'Seluruh transaksi penjualan beserta item.',
        ExportModule.products => 'Data produk, harga, dan stok.',
        ExportModule.restocks => 'Riwayat pembelian barang dari supplier.',
        ExportModule.customers => 'Data pelanggan dan saldo kasbon.',
        ExportModule.kasbon => 'Seluruh transaksi hutang dan pembayaran.',
        ExportModule.inventory => 'Status inventori dan pergerakan stok.',
        ExportModule.analyticsSummary => 'Ringkasan analitik bisnis.',
        ExportModule.businessHealth => 'Indikator kesehatan bisnis.',
      };
}

class ExportDateRange {
  const ExportDateRange({
    required this.label,
    required this.from,
    required this.to,
  });

  final String label;
  final DateTime from;
  final DateTime to;

  static ExportDateRange today() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    return ExportDateRange(
        label: 'Hari Ini',
        from: start,
        to: now);
  }

  static ExportDateRange yesterday() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day - 1);
    final end = DateTime(now.year, now.month, now.day);
    return ExportDateRange(label: 'Kemarin', from: start, to: end);
  }

  static ExportDateRange last7Days() {
    final now = DateTime.now();
    return ExportDateRange(
        label: '7 Hari Terakhir',
        from: now.subtract(const Duration(days: 7)),
        to: now);
  }

  static ExportDateRange last30Days() {
    final now = DateTime.now();
    return ExportDateRange(
        label: '30 Hari Terakhir',
        from: now.subtract(const Duration(days: 30)),
        to: now);
  }

  static ExportDateRange allTime() {
    return ExportDateRange(
        label: 'Semua Waktu',
        from: DateTime(2020),
        to: DateTime.now());
  }

  int get fromMs => from.millisecondsSinceEpoch;
  int get toMs => to.millisecondsSinceEpoch;
}

class ExportHistoryItem {
  const ExportHistoryItem({
    required this.id,
    required this.fileName,
    required this.module,
    required this.format,
    required this.exportedAt,
    required this.status,
    required this.recordCount,
    this.error,
  });

  final String id;
  final String fileName;
  final ExportModule module;
  final ExportFormat format;
  final DateTime exportedAt;
  final ExportStatus status;
  final int recordCount;
  final String? error;

  String get formattedDate =>
      DateFormat('d MMM yyyy HH:mm').format(exportedAt);
  String get formatLabel => switch (format) {
        ExportFormat.csv => 'CSV',
        ExportFormat.excel => 'Excel',
        ExportFormat.pdf => 'PDF',
      };
}
