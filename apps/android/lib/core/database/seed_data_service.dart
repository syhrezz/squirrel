import 'package:drift/drift.dart';
import 'app_database.dart';
import '../utils/uuid_util.dart';
import '../utils/dev_user.dart';

/// Inserts realistic warung kelontong sample data on first launch.
///
/// Covers all five features:
/// - 12 products with realistic IDR prices and stock
/// - 2 restock trips (past shopping)
/// - 3 sales transactions
/// - 3 customers with debt/payment history
///
/// Only runs when the products table is empty.
/// Safe to call every app launch — idempotent.
class SeedDataService {
  const SeedDataService(this._db);
  final AppDatabase _db;

  Future<void> seedIfEmpty() async {
    final count = await _db.select(_db.products).get();
    if (count.isNotEmpty) return;
    await _seed();
  }

  Future<void> _seed() async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // -------------------------------------------------------------------------
    // Helper to generate past timestamps
    // -------------------------------------------------------------------------
    int daysAgo(int days) =>
        DateTime.now()
            .subtract(Duration(days: days))
            .millisecondsSinceEpoch;

    // -------------------------------------------------------------------------
    // PRODUCTS — 12 realistic warung kelontong items
    // -------------------------------------------------------------------------
    final products = [
      _product('Indomie Goreng',         'pcs',    3500, 2800,  48, now),
      _product('Indomie Soto',           'pcs',    3500, 2800,  36, now),
      _product('Beras (1 kg)',           'kg',    14000,12000,  50, now),
      _product('Gula Pasir (1 kg)',      'kg',    16000,14000,  20, now),
      _product('Minyak Goreng Bimoli 1L','liter', 20000,17500,  12, now),
      _product('Kecap Manis ABC 135ml',  'botol',  8500, 7000,  18, now),
      _product('Sabun Lifebuoy',         'pcs',    5000, 4000,  24, now),
      _product('Aqua 600ml',             'botol',  4000, 2800,  60, now),
      _product('Rokok Gudang Garam 12',  'bungkus',25000,22000, 20, now),
      _product('Teh Pucuk Harum 350ml',  'botol',  5000, 3500,  30, now),
      _product('Susu Kental Manis Indomilk', 'kaleng', 12000, 10000, 15, now),
      _product('Mie Sedaap Goreng',      'pcs',    3000, 2400,  40, now),
    ];

    final productIds = <String>[];
    for (final p in products) {
      await _db.into(_db.products).insert(p);
      productIds.add(p.id.value);
    }

    // Short aliases for readability
    final idIndomieGoreng  = productIds[0];
    final idIndomieKuah    = productIds[1];
    final idBeras          = productIds[2];
    final idGula           = productIds[3];
    final idMinyak         = productIds[4];
    final idKecap          = productIds[5];
    final idSabun          = productIds[6];
    final idAqua           = productIds[7];
    final idRokok          = productIds[8];
    final idTeh            = productIds[9];
    final idSusu           = productIds[10];
    final idMieSedaap      = productIds[11];

    // -------------------------------------------------------------------------
    // RESTOCK 1 — 5 days ago
    // -------------------------------------------------------------------------
    final restock1Id = UuidUtil.generate();
    final restock1Time = daysAgo(5);
    await _db.into(_db.restocks).insert(RestocksCompanion.insert(
      id: restock1Id,
      createdAt: restock1Time,
      createdBy: kDevUser.id,
      deviceId: kDevUser.deviceId,
      totalAmount: 5 * 2800 + 5 * 2800 + 10 * 12000 + 5 * 17500,
      synced: const Value(false),
    ));
    await _restockItem(restock1Id, idIndomieGoreng, 5, 2800, restock1Time);
    await _restockItem(restock1Id, idIndomieKuah,   5, 2800, restock1Time);
    await _restockItem(restock1Id, idBeras,        10,12000, restock1Time);
    await _restockItem(restock1Id, idMinyak,        5,17500, restock1Time);
    await _stockMovement(idIndomieGoreng,  5, restock1Id, 'restock', restock1Time);
    await _stockMovement(idIndomieKuah,    5, restock1Id, 'restock', restock1Time);
    await _stockMovement(idBeras,         10, restock1Id, 'restock', restock1Time);
    await _stockMovement(idMinyak,         5, restock1Id, 'restock', restock1Time);

    // -------------------------------------------------------------------------
    // RESTOCK 2 — 2 days ago
    // -------------------------------------------------------------------------
    final restock2Id = UuidUtil.generate();
    final restock2Time = daysAgo(2);
    await _db.into(_db.restocks).insert(RestocksCompanion.insert(
      id: restock2Id,
      createdAt: restock2Time,
      createdBy: kDevUser.id,
      deviceId: kDevUser.deviceId,
      totalAmount: 24 * 2800 + 12 * 3500 + 10 * 7000 + 20 * 22000,
      synced: const Value(false),
    ));
    await _restockItem(restock2Id, idAqua,       24, 2800, restock2Time);
    await _restockItem(restock2Id, idTeh,        12, 3500, restock2Time);
    await _restockItem(restock2Id, idKecap,      10, 7000, restock2Time);
    await _restockItem(restock2Id, idRokok,      20,22000, restock2Time);
    await _stockMovement(idAqua,  24, restock2Id, 'restock', restock2Time);
    await _stockMovement(idTeh,   12, restock2Id, 'restock', restock2Time);
    await _stockMovement(idKecap, 10, restock2Id, 'restock', restock2Time);
    await _stockMovement(idRokok, 20, restock2Id, 'restock', restock2Time);

    // -------------------------------------------------------------------------
    // SALES — 3 transactions
    // -------------------------------------------------------------------------

    // Sale 1 — yesterday morning
    final sale1Id  = UuidUtil.generate();
    final sale1Time = daysAgo(1) - const Duration(hours: 3).inMilliseconds;
    final sale1Total = 3 * 3500 + 2 * 4000; // 3x Indomie + 2x Aqua = 18500
    await _db.into(_db.sales).insert(SalesCompanion.insert(
      id: sale1Id,
      createdAt: sale1Time,
      createdBy: kDevUser.id,
      deviceId: kDevUser.deviceId,
      totalAmount: sale1Total,
      amountPaid: 20000,
      changeAmount: 20000 - sale1Total,
      synced: const Value(false),
    ));
    await _saleItem(sale1Id, idIndomieGoreng, 3, 3500, sale1Time);
    await _saleItem(sale1Id, idAqua,          2, 4000, sale1Time);
    await _stockMovement(idIndomieGoreng, -3, sale1Id, 'sale', sale1Time);
    await _stockMovement(idAqua,          -2, sale1Id, 'sale', sale1Time);

    // Sale 2 — this morning
    final sale2Id   = UuidUtil.generate();
    final sale2Time = daysAgo(0) - const Duration(hours: 2).inMilliseconds;
    final sale2Total = 1 * 16000 + 1 * 20000 + 2 * 3500; // Gula + Minyak + 2 Indomie = 43000
    await _db.into(_db.sales).insert(SalesCompanion.insert(
      id: sale2Id,
      createdAt: sale2Time,
      createdBy: kDevUser.id,
      deviceId: kDevUser.deviceId,
      totalAmount: sale2Total,
      amountPaid: 50000,
      changeAmount: 50000 - sale2Total,
      synced: const Value(false),
    ));
    await _saleItem(sale2Id, idGula,         1, 16000, sale2Time);
    await _saleItem(sale2Id, idMinyak,       1, 20000, sale2Time);
    await _saleItem(sale2Id, idIndomieKuah,  2,  3500, sale2Time);
    await _stockMovement(idGula,       -1, sale2Id, 'sale', sale2Time);
    await _stockMovement(idMinyak,     -1, sale2Id, 'sale', sale2Time);
    await _stockMovement(idIndomieKuah,-2, sale2Id, 'sale', sale2Time);

    // Sale 3 — 3 days ago
    final sale3Id   = UuidUtil.generate();
    final sale3Time = daysAgo(3);
    final sale3Total = 1 * 25000 + 2 * 5000 + 1 * 8500; // Rokok + 2 Teh + Kecap = 43500
    await _db.into(_db.sales).insert(SalesCompanion.insert(
      id: sale3Id,
      createdAt: sale3Time,
      createdBy: kDevUser.id,
      deviceId: kDevUser.deviceId,
      totalAmount: sale3Total,
      amountPaid: 50000,
      changeAmount: 50000 - sale3Total,
      synced: const Value(false),
    ));
    await _saleItem(sale3Id, idRokok,  1, 25000, sale3Time);
    await _saleItem(sale3Id, idTeh,    2,  5000, sale3Time);
    await _saleItem(sale3Id, idKecap,  1,  8500, sale3Time);
    await _stockMovement(idRokok, -1, sale3Id, 'sale', sale3Time);
    await _stockMovement(idTeh,   -2, sale3Id, 'sale', sale3Time);
    await _stockMovement(idKecap, -1, sale3Id, 'sale', sale3Time);

    // Sale 4 — 6 days ago (uses remaining products)
    final sale4Id   = UuidUtil.generate();
    final sale4Time = daysAgo(6);
    final sale4Total = 1 * 5000 + 1 * 12000 + 2 * 3000; // Sabun + Susu + 2xMieSedaap = 23000
    await _db.into(_db.sales).insert(SalesCompanion.insert(
      id: sale4Id,
      createdAt: sale4Time,
      createdBy: kDevUser.id,
      deviceId: kDevUser.deviceId,
      totalAmount: sale4Total,
      amountPaid: 25000,
      changeAmount: 25000 - sale4Total,
      synced: const Value(false),
    ));
    await _saleItem(sale4Id, idSabun,    1,  5000, sale4Time);
    await _saleItem(sale4Id, idSusu,     1, 12000, sale4Time);
    await _saleItem(sale4Id, idMieSedaap,2,  3000, sale4Time);
    await _stockMovement(idSabun,    -1, sale4Id, 'sale', sale4Time);
    await _stockMovement(idSusu,     -1, sale4Id, 'sale', sale4Time);
    await _stockMovement(idMieSedaap,-2, sale4Id, 'sale', sale4Time);

    // -------------------------------------------------------------------------
    // CUSTOMERS + KASBON
    // -------------------------------------------------------------------------

    // Customer 1: Bu Sari — owes money, partially paid
    final buSariId = UuidUtil.generate();
    await _db.into(_db.customers).insert(CustomersCompanion.insert(
      id: buSariId,
      name: 'Bu Sari',
      phone: const Value('085712345678'),
      note: const Value('Tetangga RT 2, sering beli beras'),
      createdAt: daysAgo(14),
      updatedAt: daysAgo(14),
      createdBy: kDevUser.id,
      updatedBy: kDevUser.id,
      synced: const Value(false),
    ));
    await _debt(buSariId,    35000, 'Beli beras 2.5 kg + minyak',  daysAgo(10));
    await _debt(buSariId,    14000, 'Beli gula 1 kg',               daysAgo(7));
    await _payment(buSariId, 20000, 'Bayar sebagian',               daysAgo(4));
    await _debt(buSariId,    10500, 'Indomie 3 bungkus + Aqua',     daysAgo(1));

    // Customer 2: Pak Budi — fully paid off
    final pakBudiId = UuidUtil.generate();
    await _db.into(_db.customers).insert(CustomersCompanion.insert(
      id: pakBudiId,
      name: 'Pak Budi',
      phone: const Value('08123456789'),
      createdAt: daysAgo(20),
      updatedAt: daysAgo(20),
      createdBy: kDevUser.id,
      updatedBy: kDevUser.id,
      synced: const Value(false),
    ));
    await _debt(pakBudiId,    50000, 'Rokok seminggu',     daysAgo(8));
    await _payment(pakBudiId, 50000, 'Lunas',              daysAgo(2));

    // Customer 3: Mbak Dewi — has a larger outstanding balance
    final mbakDewiId = UuidUtil.generate();
    await _db.into(_db.customers).insert(CustomersCompanion.insert(
      id: mbakDewiId,
      name: 'Mbak Dewi',
      note: const Value('Warung seberang jalan'),
      createdAt: daysAgo(30),
      updatedAt: daysAgo(30),
      createdBy: kDevUser.id,
      updatedBy: kDevUser.id,
      synced: const Value(false),
    ));
    await _debt(mbakDewiId,    75000, 'Belanja bulanan',          daysAgo(15));
    await _debt(mbakDewiId,    30000, 'Sabun + susu + kecap',     daysAgo(9));
    await _payment(mbakDewiId, 50000, 'Transfer BCA',             daysAgo(5));
    await _debt(mbakDewiId,    25000, 'Mie + Aqua + rokok',       daysAgo(2));
  }

  // -------------------------------------------------------------------------
  // Helper builders
  // -------------------------------------------------------------------------

  ProductsCompanion _product(
    String name,
    String unit,
    int sellPrice,
    int lastBuyPrice,
    int stock,
    int now,
  ) {
    return ProductsCompanion.insert(
      id: UuidUtil.generate(),
      name: name,
      unit: unit,
      sellPrice: sellPrice,
      lastBuyPrice: lastBuyPrice,
      currentStock: Value(stock),
      createdAt: now,
      updatedAt: now,
      createdBy: kDevUser.id,
      updatedBy: kDevUser.id,
      deviceId: kDevUser.deviceId,
      synced: const Value(false),
    );
  }

  Future<void> _restockItem(
    String restockId,
    String productId,
    int qty,
    int price,
    int createdAt,
  ) async {
    await _db.into(_db.restockItems).insert(RestockItemsCompanion.insert(
      id: UuidUtil.generate(),
      restockId: restockId,
      productId: productId,
      quantity: qty,
      purchasePrice: price,
      subtotal: qty * price,
    ));
  }

  Future<void> _saleItem(
    String saleId,
    String productId,
    int qty,
    int price,
    int createdAt,
  ) async {
    await _db.into(_db.saleItems).insert(SaleItemsCompanion.insert(
      id: UuidUtil.generate(),
      saleId: saleId,
      productId: productId,
      quantity: qty,
      sellingPrice: price,
      subtotal: qty * price,
    ));
  }

  Future<void> _stockMovement(
    String productId,
    int change,
    String sourceId,
    String sourceType,
    int createdAt,
  ) async {
    await _db.into(_db.stockMovements).insert(StockMovementsCompanion.insert(
      id: UuidUtil.generate(),
      productId: productId,
      quantityChange: change,
      sourceType: sourceType,
      sourceId: sourceId,
      createdAt: createdAt,
      createdBy: kDevUser.id,
      deviceId: kDevUser.deviceId,
      synced: const Value(false),
    ));
  }

  Future<void> _debt(
    String customerId,
    int amount,
    String note,
    int createdAt,
  ) async {
    await _db.into(_db.debtTransactions).insert(
      DebtTransactionsCompanion.insert(
        id: UuidUtil.generate(),
        customerId: customerId,
        type: 'debt',
        amount: amount,
        note: Value(note),
        createdAt: createdAt,
        createdBy: kDevUser.id,
        synced: const Value(false),
      ),
    );
  }

  Future<void> _payment(
    String customerId,
    int amount,
    String note,
    int createdAt,
  ) async {
    await _db.into(_db.debtTransactions).insert(
      DebtTransactionsCompanion.insert(
        id: UuidUtil.generate(),
        customerId: customerId,
        type: 'payment',
        amount: amount,
        note: Value(note),
        createdAt: createdAt,
        createdBy: kDevUser.id,
        synced: const Value(false),
      ),
    );
  }
}
