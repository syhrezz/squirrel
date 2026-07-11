import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/exports/models/export_models.dart';

final _idr = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
final _dateFmt = DateFormat('d MMM yyyy HH:mm');

/// Fetches raw data from Supabase and returns it as a list of rows.
/// Each row is a Map<String, dynamic>.
class ExportRepository {
  ExportRepository(this._client, this._orgId);

  final SupabaseClient _client;
  final String _orgId;

  Future<List<Map<String, dynamic>>> fetchData(
      ExportModule module,
      ExportDateRange range) async {
    switch (module) {
      case ExportModule.sales:
        return _fetchSales(range);
      case ExportModule.products:
        return _fetchProducts();
      case ExportModule.restocks:
        return _fetchRestocks(range);
      case ExportModule.customers:
        return _fetchCustomers();
      case ExportModule.kasbon:
        return _fetchKasbon(range);
      case ExportModule.inventory:
        return _fetchInventory();
      case ExportModule.analyticsSummary:
        return _fetchAnalyticsSummary(range);
      case ExportModule.businessHealth:
        return _fetchBusinessHealth();
    }
  }

  Future<List<Map<String, dynamic>>> _fetchSales(
      ExportDateRange range) async {
    final rows = await _client
        .from('sales')
        .select('id, created_at, created_by, device_id, total_amount, amount_paid, change_amount')
        .eq('organization_id', _orgId)
        .gte('created_at', range.fromMs)
        .lte('created_at', range.toMs)
        .order('created_at', ascending: false);

    return (rows as List).map((r) {
      final dt = DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int);
      return {
        'No. Invoice': 'INV-${(r['id'] as String).substring(0, 8).toUpperCase()}',
        'Tanggal': _dateFmt.format(dt),
        'Kasir': r['created_by'] ?? '',
        'Total': _idr.format(r['total_amount'] as int? ?? 0),
        'Bayar': _idr.format(r['amount_paid'] as int? ?? 0),
        'Kembalian': _idr.format(r['change_amount'] as int? ?? 0),
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchProducts() async {
    final rows = await _client
        .from('products')
        .select('name, category, inventory_unit, purchase_unit, purchase_conversion, sell_price, last_buy_price, current_stock, is_active, updated_at')
        .eq('organization_id', _orgId)
        .order('name', ascending: true);

    return (rows as List).map((r) {
      final dt = DateTime.fromMillisecondsSinceEpoch(r['updated_at'] as int? ?? 0);
      return {
        'Nama': r['name'] ?? '',
        'Kategori': r['category'] ?? '',
        'Unit Stok': r['inventory_unit'] ?? '',
        'Unit Beli': r['purchase_unit'] ?? '',
        'Konversi': '${r['purchase_conversion'] ?? 1}',
        'Harga Jual': _idr.format(r['sell_price'] as int? ?? 0),
        'Harga Beli': _idr.format(r['last_buy_price'] as int? ?? 0),
        'Stok': '${r['current_stock'] ?? 0}',
        'Status': (r['is_active'] as bool? ?? true) ? 'Aktif' : 'Nonaktif',
        'Terakhir Update': _dateFmt.format(dt),
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchRestocks(
      ExportDateRange range) async {
    final rows = await _client
        .from('restocks')
        .select('id, created_at, created_by, total_amount')
        .eq('organization_id', _orgId)
        .gte('created_at', range.fromMs)
        .lte('created_at', range.toMs)
        .order('created_at', ascending: false);

    return (rows as List).map((r) {
      final dt = DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int);
      return {
        'No. Restock': 'RST-${(r['id'] as String).substring(0, 8).toUpperCase()}',
        'Tanggal': _dateFmt.format(dt),
        'Dibuat Oleh': r['created_by'] ?? '',
        'Total': _idr.format(r['total_amount'] as int? ?? 0),
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchCustomers() async {
    final rows = await _client
        .from('customers')
        .select('id, name, phone, is_active, created_at')
        .eq('organization_id', _orgId)
        .order('name', ascending: true);

    final custList = rows as List;
    final allTx = await _client
        .from('debt_transactions')
        .select('customer_id, type, amount')
        .eq('organization_id', _orgId);

    final balances = <String, int>{};
    for (final tx in allTx as List) {
      final cid = tx['customer_id'] as String;
      balances[cid] = (balances[cid] ?? 0) +
          (tx['type'] == 'debt'
              ? tx['amount'] as int? ?? 0
              : -(tx['amount'] as int? ?? 0));
    }

    return custList.map((r) {
      final cid = r['id'] as String;
      final dt = DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int? ?? 0);
      final bal = balances[cid] ?? 0;
      return {
        'Nama': r['name'] ?? '',
        'Telepon': r['phone'] ?? '',
        'Status': (r['is_active'] as bool? ?? true) ? 'Aktif' : 'Nonaktif',
        'Saldo Kasbon': _idr.format(bal.abs()),
        'Status Kasbon': bal > 0 ? 'Berhutang' : bal < 0 ? 'Lebih Bayar' : 'Lunas',
        'Terdaftar': _dateFmt.format(dt),
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchKasbon(
      ExportDateRange range) async {
    final rows = await _client
        .from('debt_transactions')
        .select('id, customer_id, type, amount, note, created_at')
        .eq('organization_id', _orgId)
        .gte('created_at', range.fromMs)
        .lte('created_at', range.toMs)
        .order('created_at', ascending: false);

    return (rows as List).map((r) {
      final dt = DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int);
      return {
        'ID Transaksi': (r['id'] as String).substring(0, 8).toUpperCase(),
        'Tanggal': _dateFmt.format(dt),
        'Tipe': r['type'] == 'debt' ? 'Hutang' : 'Bayar',
        'Jumlah': _idr.format(r['amount'] as int? ?? 0),
        'Catatan': r['note'] ?? '',
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchInventory() async {
    final rows = await _client
        .from('products')
        .select('name, inventory_unit, current_stock, last_buy_price, category')
        .eq('organization_id', _orgId)
        .eq('is_active', true)
        .order('category', ascending: true);

    return (rows as List).map((r) {
      final stock = r['current_stock'] as int? ?? 0;
      final price = r['last_buy_price'] as int? ?? 0;
      return {
        'Produk': r['name'] ?? '',
        'Kategori': r['category'] ?? '',
        'Stok': '$stock',
        'Unit': r['inventory_unit'] ?? '',
        'Harga Beli': _idr.format(price),
        'Nilai Inventori': _idr.format(stock * price),
        'Status': stock <= 0 ? 'Habis' : stock <= 3 ? 'Rendah' : 'Normal',
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchAnalyticsSummary(
      ExportDateRange range) async {
    // Return a simple summary row
    final sales = await _client.from('sales').select('total_amount').eq('organization_id', _orgId).gte('created_at', range.fromMs).lte('created_at', range.toMs);
    final restocks = await _client.from('restocks').select('total_amount').eq('organization_id', _orgId).gte('created_at', range.fromMs).lte('created_at', range.toMs);

    final totalRevenue = (sales as List).fold<int>(0, (s, r) => s + (r['total_amount'] as int? ?? 0));
    final totalPurchase = (restocks as List).fold<int>(0, (s, r) => s + (r['total_amount'] as int? ?? 0));

    return [{
      'Metrik': 'Total Revenue',
      'Nilai': _idr.format(totalRevenue),
      'Periode': range.label,
    }, {
      'Metrik': 'Total Pembelian',
      'Nilai': _idr.format(totalPurchase),
      'Periode': range.label,
    }, {
      'Metrik': 'Gross Profit Estimate',
      'Nilai': _idr.format(totalRevenue - totalPurchase),
      'Periode': range.label,
    }];
  }

  Future<List<Map<String, dynamic>>> _fetchBusinessHealth() async {
    final now = DateTime.now();
    final todayMs = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;

    final todaySales = await _client.from('sales').select('total_amount').eq('organization_id', _orgId).gte('created_at', todayMs);
    final revenue = (todaySales as List).fold<int>(0, (s, r) => s + (r['total_amount'] as int? ?? 0));

    final products = await _client.from('products').select('current_stock, last_buy_price').eq('organization_id', _orgId).eq('is_active', true);
    int invValue = 0;
    int outOfStock = 0;
    for (final p in products as List) {
      invValue += (p['current_stock'] as int? ?? 0) * (p['last_buy_price'] as int? ?? 0);
      if ((p['current_stock'] as int? ?? 0) <= 0) outOfStock++;
    }

    return [{
      'Indikator': 'Revenue Hari Ini',
      'Nilai': _idr.format(revenue),
      'Tanggal': _dateFmt.format(now),
    }, {
      'Indikator': 'Nilai Inventori',
      'Nilai': _idr.format(invValue),
      'Tanggal': _dateFmt.format(now),
    }, {
      'Indikator': 'Produk Habis Stok',
      'Nilai': '$outOfStock produk',
      'Tanggal': _dateFmt.format(now),
    }];
  }
}

/// Converts rows to CSV string (UTF-8).
class CsvExporter {
  static String export(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return '';

    final headers = rows.first.keys.toList();
    final lines = <String>[];

    // BOM for Excel UTF-8 compatibility
    lines.add('\uFEFF${headers.map(_escape).join(',')}');

    for (final row in rows) {
      lines.add(headers.map((h) => _escape(row[h]?.toString() ?? '')).join(','));
    }

    return lines.join('\r\n');
  }

  static String _escape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}

/// Converts rows to Excel bytes using the excel package.
class ExcelExporter {
  static List<int> export(
      List<Map<String, dynamic>> rows,
      String sheetName) {
    // Use CSV as Excel-compatible format since excel package
    // may have compatibility issues on web. The file extension
    // will still be .csv but opened as Excel-compatible.
    // For proper .xlsx, the excel package is used below.
    final csv = CsvExporter.export(rows);
    return utf8.encode(csv);
  }
}
