import 'dart:math';
import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/seed_data_service.dart';
import '../../../core/utils/uuid_util.dart';
import '../../../core/utils/dev_user.dart';

/// Statistics snapshot for the database.
class DbStats {
  const DbStats({
    required this.products,
    required this.activeProducts,
    required this.customers,
    required this.outstandingCustomers,
    required this.sales,
    required this.saleItems,
    required this.restocks,
    required this.restockItems,
    required this.debtTransactions,
    required this.stockMovements,
    required this.schemaVersion,
  });

  final int products;
  final int activeProducts;
  final int customers;
  final int outstandingCustomers;
  final int sales;
  final int saleItems;
  final int restocks;
  final int restockItems;
  final int debtTransactions;
  final int stockMovements;
  final int schemaVersion;
}

/// Result of an integrity check.
class IntegrityResult {
  const IntegrityResult({required this.passed, this.issues = const []});
  final bool passed;
  final List<String> issues;
}

/// DEV ONLY — not imported by any production code.
///
/// Provides database statistics, random data generators,
/// stress test generators, and data integrity checks.
class DevToolsDataService {
  DevToolsDataService(this._db);
  final AppDatabase _db;
  final _rand = Random();

  // -------------------------------------------------------------------------
  // Statistics
  // -------------------------------------------------------------------------

  Future<DbStats> getStats() async {
    final products = await _db.select(_db.products).get();
    final customers = await _db.select(_db.customers).get();
    final debtTxs = await _db.select(_db.debtTransactions).get();

    // Calculate outstanding customers (balance > 0)
    int outstandingCount = 0;
    for (final c in customers.where((c) => c.isActive)) {
      final txs = debtTxs.where((t) => t.customerId == c.id);
      final balance = txs.fold<int>(
        0,
        (sum, t) => t.type == 'debt' ? sum + t.amount : sum - t.amount,
      );
      if (balance > 0) outstandingCount++;
    }

    return DbStats(
      products: products.length,
      activeProducts: products.where((p) => p.isActive).length,
      customers: customers.length,
      outstandingCustomers: outstandingCount,
      sales: await _count(_db.sales),
      saleItems: await _count(_db.saleItems),
      restocks: await _count(_db.restocks),
      restockItems: await _count(_db.restockItems),
      debtTransactions: debtTxs.length,
      stockMovements: await _count(_db.stockMovements),
      schemaVersion: _db.schemaVersion,
    );
  }

  Future<int> _count(TableInfo table) async {
    final rows = await _db.customSelect(
      'SELECT COUNT(*) as c FROM ${table.actualTableName}',
    ).get();
    return rows.first.read<int>('c');
  }

  // -------------------------------------------------------------------------
  // Seed / Reset
  // -------------------------------------------------------------------------

  Future<void> seedSampleData() async {
    await SeedDataService(_db).seedIfEmpty();
  }

  Future<void> clearAllData() async {
    await _db.transaction(() async {
      await _db.delete(_db.stockMovements).go();
      await _db.delete(_db.debtTransactions).go();
      await _db.delete(_db.saleItems).go();
      await _db.delete(_db.sales).go();
      await _db.delete(_db.restockItems).go();
      await _db.delete(_db.restocks).go();
      await _db.delete(_db.customers).go();
      await _db.delete(_db.products).go();
    });
  }

  Future<void> resetDemoData() async {
    await clearAllData();
    await SeedDataService(_db).seedIfEmpty();
  }

  // -------------------------------------------------------------------------
  // Generators — realistic random Indonesian warung data
  // -------------------------------------------------------------------------

  static const _productNames = [
    'Indomie Goreng', 'Indomie Kuah', 'Indomie Soto', 'Mie Sedaap Goreng',
    'Mie Sedaap Kuah', 'Beras Premium 1kg', 'Beras Medium 1kg',
    'Gula Pasir 1kg', 'Gula Merah 250g', 'Minyak Goreng 1L',
    'Minyak Goreng 2L', 'Kecap Manis ABC', 'Kecap Asin', 'Saos Sambal',
    'Sambal Indofood', 'Aqua 600ml', 'Aqua 1.5L', 'Le Minerale 600ml',
    'Teh Pucuk 350ml', 'Teh Botol Sosro', 'Pocari Sweat', 'Sprite 390ml',
    'Fanta Merah', 'Coca Cola 390ml', 'Good Day Cappuccino',
    'Nescafe 3in1', 'Susu Ultra 250ml', 'Susu Frisian Flag 1L',
    'Susu Kental Indomilk', 'Ovomaltine', 'Sabun Lifebuoy', 'Sabun Dettol',
    'Shampoo Sunsilk', 'Shampoo Pantene', 'Pasta Gigi Pepsodent',
    'Rokok Gudang Garam 12', 'Rokok Sampoerna 16', 'Rokok Dji Sam Soe',
    'Marlboro 20', 'Snack Chitato', 'Snack Pringles', 'Biscuit Roma',
    'Wafer Tango', 'Chocolatos', 'Biskuit Oreo', 'Energen Coklat',
    'Quaker Oats', 'Tepung Segitiga Biru 1kg', 'Garam Dapur',
    'Merica Bubuk', 'Masako Ayam', 'Royco Sapi', 'Saori Oyster',
    'Kopi Kapal Api', 'Kopi Good Day', 'Teh Celup Sariwangi',
    'Kerupuk Udang', 'Kerupuk Bawang', 'Snack Qtela',
    'Sosro Teh Kotak 200ml', 'ABC Sari Kacang Hijau',
  ];

  static const _units = [
    'pcs', 'pcs', 'pcs', 'bungkus', 'bungkus',
    'kg', 'liter', 'botol', 'kaleng', 'sachet',
  ];

  static const _customerNames = [
    'Bu Ani', 'Pak Budi', 'Mbak Cici', 'Pak Dedi', 'Bu Eni',
    'Pak Fauzi', 'Bu Gita', 'Pak Hendra', 'Bu Ika', 'Pak Joko',
    'Bu Kartini', 'Pak Lukman', 'Bu Mira', 'Pak Nano', 'Bu Opik',
    'Pak Purnomo', 'Bu Qori', 'Pak Rizal', 'Bu Sari', 'Pak Tono',
    'Bu Umi', 'Pak Veri', 'Bu Wati', 'Pak Xian', 'Bu Yani',
    'Pak Zaki', 'Bu Aminah', 'Pak Bambang', 'Bu Citra', 'Pak Darto',
    'Bu Endang', 'Pak Fajar', 'Bu Gina', 'Pak Halim', 'Bu Indah',
    'Pak Jaya', 'Bu Karina', 'Pak Latif', 'Bu Maryam', 'Pak Nugroho',
  ];

  int _daysAgo(int days) =>
      DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;

  int _randDaysAgo(int maxDays) => _daysAgo(_rand.nextInt(maxDays));

  int _roundedPrice(int min, int max) {
    final raw = min + _rand.nextInt(max - min);
    return (raw / 500).round() * 500;
  }

  Future<void> generateProducts(int count) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final names = List<String>.from(_productNames)..shuffle(_rand);
    for (var i = 0; i < count; i++) {
      final name = i < names.length
          ? names[i]
          : '${names[i % names.length]} (${i ~/ names.length + 1})';
      final buyPrice = _roundedPrice(1500, 25000);
      final sellPrice = buyPrice + _roundedPrice(500, 3000);
      final unit = _units[_rand.nextInt(_units.length)];
      await _db.into(_db.products).insert(ProductsCompanion.insert(
        id: UuidUtil.generate(),
        name: name,
        unit: unit,
        sellPrice: sellPrice,
        lastBuyPrice: buyPrice,
        currentStock: Value(_rand.nextInt(100)),
        createdAt: now,
        updatedAt: now,
        createdBy: kDevUser.id,
        updatedBy: kDevUser.id,
        deviceId: kDevUser.deviceId,
        synced: const Value(false),
      ));
    }
  }

  Future<void> generateSales(int count) async {
    final products = await (_db.select(_db.products)
          ..where((p) => p.isActive.equals(true)))
        .get();
    if (products.isEmpty) return;

    for (var i = 0; i < count; i++) {
      final saleId = UuidUtil.generate();
      final saleTime = _randDaysAgo(90);
      final itemCount = 1 + _rand.nextInt(5);
      final items = <Product>[];
      final shuffled = List<Product>.from(products)..shuffle(_rand);
      items.addAll(shuffled.take(itemCount));

      int total = 0;
      for (final p in items) {
        final qty = 1 + _rand.nextInt(4);
        total += p.sellPrice * qty;
      }
      final paid = total + _rand.nextInt(5) * 1000;

      await _db.into(_db.sales).insert(SalesCompanion.insert(
        id: saleId,
        createdAt: saleTime,
        createdBy: kDevUser.id,
        deviceId: kDevUser.deviceId,
        totalAmount: total,
        amountPaid: paid,
        changeAmount: paid - total,
        synced: const Value(false),
      ));

      for (final p in items) {
        final qty = 1 + _rand.nextInt(4);
        await _db.into(_db.saleItems).insert(SaleItemsCompanion.insert(
          id: UuidUtil.generate(),
          saleId: saleId,
          productId: p.id,
          quantity: qty,
          sellingPrice: p.sellPrice,
          subtotal: p.sellPrice * qty,
        ));
      }
    }
  }

  Future<void> generateCustomers(int count) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final names = List<String>.from(_customerNames)..shuffle(_rand);
    for (var i = 0; i < count; i++) {
      final name = i < names.length
          ? names[i]
          : '${names[i % names.length]} ${i ~/ names.length + 2}';
      await _db.into(_db.customers).insert(CustomersCompanion.insert(
        id: UuidUtil.generate(),
        name: name,
        phone: Value('08${_rand.nextInt(9000000000) + 1000000000}'),
        createdAt: now,
        updatedAt: now,
        createdBy: kDevUser.id,
        updatedBy: kDevUser.id,
        synced: const Value(false),
      ));
    }
  }

  Future<void> generateDebtTransactions(int count) async {
    final customers = await (_db.select(_db.customers)
          ..where((c) => c.isActive.equals(true)))
        .get();
    if (customers.isEmpty) return;

    for (var i = 0; i < count; i++) {
      final customer = customers[_rand.nextInt(customers.length)];
      final isDebt = _rand.nextBool();
      final amount = _roundedPrice(5000, 100000);
      await _db.into(_db.debtTransactions).insert(
        DebtTransactionsCompanion.insert(
          id: UuidUtil.generate(),
          customerId: customer.id,
          type: isDebt ? 'debt' : 'payment',
          amount: amount,
          note: Value(isDebt ? 'Hutang belanja' : 'Bayar hutang'),
          createdAt: _randDaysAgo(90),
          createdBy: kDevUser.id,
          synced: const Value(false),
        ),
      );
    }
  }

  Future<void> generateRestocks(int count) async {
    final products = await _db.select(_db.products).get();
    if (products.isEmpty) return;

    for (var i = 0; i < count; i++) {
      final restockId = UuidUtil.generate();
      final restockTime = _randDaysAgo(90);
      final itemCount = 1 + _rand.nextInt(6);
      final shuffled = List<Product>.from(products)..shuffle(_rand);
      final items = shuffled.take(itemCount).toList();

      int total = 0;
      for (final p in items) {
        total += p.lastBuyPrice * (1 + _rand.nextInt(10));
      }

      await _db.into(_db.restocks).insert(RestocksCompanion.insert(
        id: restockId,
        createdAt: restockTime,
        createdBy: kDevUser.id,
        deviceId: kDevUser.deviceId,
        totalAmount: total,
        synced: const Value(false),
      ));

      for (final p in items) {
        final qty = 1 + _rand.nextInt(10);
        await _db.into(_db.restockItems).insert(RestockItemsCompanion.insert(
          id: UuidUtil.generate(),
          restockId: restockId,
          productId: p.id,
          quantity: qty,
          purchasePrice: p.lastBuyPrice,
          subtotal: p.lastBuyPrice * qty,
        ));
      }
    }
  }

  // -------------------------------------------------------------------------
  // Stress test generators
  // -------------------------------------------------------------------------

  Future<void> generateLowStockProducts() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    for (var i = 0; i < 10; i++) {
      await _db.into(_db.products).insert(ProductsCompanion.insert(
        id: UuidUtil.generate(),
        name: 'Produk Stok Rendah ${i + 1}',
        unit: 'pcs',
        sellPrice: 5000,
        lastBuyPrice: 4000,
        currentStock: const Value(1),
        createdAt: now,
        updatedAt: now,
        createdBy: kDevUser.id,
        updatedBy: kDevUser.id,
        deviceId: kDevUser.deviceId,
        synced: const Value(false),
      ));
    }
  }

  Future<void> generateZeroStockProducts() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    for (var i = 0; i < 10; i++) {
      await _db.into(_db.products).insert(ProductsCompanion.insert(
        id: UuidUtil.generate(),
        name: 'Produk Stok Kosong ${i + 1}',
        unit: 'pcs',
        sellPrice: 5000,
        lastBuyPrice: 4000,
        currentStock: const Value(0),
        createdAt: now,
        updatedAt: now,
        createdBy: kDevUser.id,
        updatedBy: kDevUser.id,
        deviceId: kDevUser.deviceId,
        synced: const Value(false),
      ));
    }
  }

  Future<void> generateInactiveProducts() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    for (var i = 0; i < 10; i++) {
      await _db.into(_db.products).insert(ProductsCompanion.insert(
        id: UuidUtil.generate(),
        name: 'Produk Nonaktif ${i + 1}',
        unit: 'pcs',
        sellPrice: 5000,
        lastBuyPrice: 4000,
        isActive: const Value(false),
        createdAt: now,
        updatedAt: now,
        createdBy: kDevUser.id,
        updatedBy: kDevUser.id,
        deviceId: kDevUser.deviceId,
        synced: const Value(false),
      ));
    }
  }

  Future<void> generateLargeKasbonHistory() async {
    final custId = UuidUtil.generate();
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.into(_db.customers).insert(CustomersCompanion.insert(
      id: custId,
      name: 'Pelanggan Kasbon Panjang',
      phone: const Value('08111111111'),
      createdAt: now,
      updatedAt: now,
      createdBy: kDevUser.id,
      updatedBy: kDevUser.id,
      synced: const Value(false),
    ));
    for (var i = 0; i < 50; i++) {
      await _db.into(_db.debtTransactions).insert(
        DebtTransactionsCompanion.insert(
          id: UuidUtil.generate(),
          customerId: custId,
          type: i.isEven ? 'debt' : 'payment',
          amount: _roundedPrice(5000, 50000),
          note: Value(i.isEven ? 'Hutang ke-${i + 1}' : 'Bayar ke-${i + 1}'),
          createdAt: _randDaysAgo(90),
          createdBy: kDevUser.id,
          synced: const Value(false),
        ),
      );
    }
  }

  Future<void> generateOverpaidCustomers() async {
    final custId = UuidUtil.generate();
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.into(_db.customers).insert(CustomersCompanion.insert(
      id: custId,
      name: 'Pelanggan Lebih Bayar',
      createdAt: now,
      updatedAt: now,
      createdBy: kDevUser.id,
      updatedBy: kDevUser.id,
      synced: const Value(false),
    ));
    await _db.into(_db.debtTransactions).insert(
      DebtTransactionsCompanion.insert(
        id: UuidUtil.generate(),
        customerId: custId,
        type: 'debt',
        amount: 30000,
        createdAt: _daysAgo(5),
        createdBy: kDevUser.id,
        synced: const Value(false),
      ),
    );
    await _db.into(_db.debtTransactions).insert(
      DebtTransactionsCompanion.insert(
        id: UuidUtil.generate(),
        customerId: custId,
        type: 'payment',
        amount: 50000,
        note: const Value('Lebih bayar'),
        createdAt: _daysAgo(1),
        createdBy: kDevUser.id,
        synced: const Value(false),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Data integrity checks
  // -------------------------------------------------------------------------

  Future<IntegrityResult> runIntegrityChecks() async {
    final issues = <String>[];

    // 1. No negative stock
    final products = await _db.select(_db.products).get();
    final negativeStock = products.where((p) => p.currentStock < 0);
    for (final p in negativeStock) {
      issues.add('Stok negatif: ${p.name} (${p.currentStock})');
    }

    // 2. Orphan sale_items (sale_id references non-existent sale)
    final sales = await _db.select(_db.sales).get();
    final saleIds = sales.map((s) => s.id).toSet();
    final saleItems = await _db.select(_db.saleItems).get();
    for (final item in saleItems) {
      if (!saleIds.contains(item.saleId)) {
        issues.add('Orphan sale_item: ${item.id} → sale ${item.saleId}');
      }
    }

    // 3. Orphan restock_items
    final restocks = await _db.select(_db.restocks).get();
    final restockIds = restocks.map((r) => r.id).toSet();
    final restockItems = await _db.select(_db.restockItems).get();
    for (final item in restockItems) {
      if (!restockIds.contains(item.restockId)) {
        issues.add('Orphan restock_item: ${item.id} → restock ${item.restockId}');
      }
    }

    // 4. Orphan debt_transactions (customer_id references non-existent customer)
    final customers = await _db.select(_db.customers).get();
    final customerIds = customers.map((c) => c.id).toSet();
    final debtTxs = await _db.select(_db.debtTransactions).get();
    for (final tx in debtTxs) {
      if (!customerIds.contains(tx.customerId)) {
        issues.add('Orphan debt_transaction: ${tx.id} → customer ${tx.customerId}');
      }
    }

    // 5. Orphan stock_movements (product_id references non-existent product)
    final productIds = products.map((p) => p.id).toSet();
    final movements = await _db.select(_db.stockMovements).get();
    for (final m in movements) {
      if (!productIds.contains(m.productId)) {
        issues.add('Orphan stock_movement: ${m.id} → product ${m.productId}');
      }
    }

    // 6. Duplicate UUIDs in products
    final seenIds = <String>{};
    for (final p in products) {
      if (!seenIds.add(p.id)) {
        issues.add('Duplicate product UUID: ${p.id}');
      }
    }

    return IntegrityResult(
      passed: issues.isEmpty,
      issues: issues,
    );
  }
}
