# Pilot Checklist — MR SQUIRREL One-Day Retail Simulation

This checklist simulates a complete business day at a real warung kelontong.
Execute this before any pilot deployment to verify end-to-end reliability.

**Tester:** _______________
**Date:** _______________
**Device:** _______________
**Result:** PASS / FAIL

---

## PRE-PILOT SETUP

- [ ] Android app installed and running
- [ ] Supabase migrations 001–007 applied
- [ ] At least 10 products in the database with selling options
- [ ] Dashboard accessible at correct URL
- [ ] Two devices available (optional, for sync test)
- [ ] Network control available (for offline simulation)

---

## 07:30 — Persiapan Toko (Store Opening)

### Android App Launch
- [ ] Open MR SQUIRREL app
- [ ] Home screen loads within 2 seconds
- [ ] All menu items visible and tappable
- [ ] Dev Tools accessible (for testing only)

### Dashboard Check
- [ ] Log in to web dashboard
- [ ] Overview page loads
- [ ] All 6 KPI cards show data (or zero)
- [ ] No error messages

**Notes:** _______________

---

## 08:00 — Buka Toko (Store Opens)

### First Sale of the Day
- [ ] Navigate to Hitung Penjualan
- [ ] "Sering Dijual" section visible
- [ ] "Pilih Kategori" chips visible
- [ ] Tap a product — adds to cart immediately
- [ ] Cart displays product name, price, quantity
- [ ] Enter payment amount
- [ ] Kembalian calculates correctly
- [ ] Tap "Selesaikan Transaksi"
- [ ] Success snackbar appears
- [ ] Cart clears
- [ ] Queue count increases by 1 in Dev Tools

**Notes:** _______________

---

## 09:00 — Belanja Barang (Restock)

### Restock with Unit Conversion
- [ ] Navigate to Belanja Barang
- [ ] Search for a product
- [ ] Add product to shopping list
- [ ] Enter quantity (e.g. 2 Dus)
- [ ] "Menambah stok: X pcs" helper text visible
- [ ] Enter total purchase price
- [ ] Tap "Simpan Belanja"
- [ ] Success snackbar appears
- [ ] Stock for that product increases by (qty × conversion)
- [ ] Restock appears in Dev Tools sync queue

**Notes:** _______________

---

## 09:30 — Penjualan Beberapa Produk (Multiple Sales)

### Sale with Multiple Selling Options
- [ ] Tap a product that has multiple selling options
- [ ] Bottom sheet appears with options
- [ ] Tap "500 gram" option — adds to cart
- [ ] Price matches configured selling option

### Sale with Manual Price
- [ ] Tap a product with `allow_manual_price = true`
- [ ] Price input appears pre-filled
- [ ] Change the price
- [ ] Complete transaction
- [ ] Verify saved amount matches edited price

### Multiple Products in One Transaction
- [ ] Add 3+ different products to cart
- [ ] Total displays correctly
- [ ] Complete transaction
- [ ] All products removed from cart

**Notes:** _______________

---

## 10:00 — Kasbon Pelanggan

### New Customer Debt
- [ ] Navigate to Kasbon
- [ ] Tap "Tambah Pelanggan"
- [ ] Enter customer name
- [ ] Save customer
- [ ] Customer appears in list
- [ ] Tap customer → detail screen
- [ ] Tap "Catat Hutang"
- [ ] Enter amount
- [ ] Save — balance shows the debt

### Partial Payment
- [ ] Same customer
- [ ] Tap "Catat Bayar"
- [ ] Enter partial amount
- [ ] Balance decreases correctly
- [ ] Timeline shows both entries

**Notes:** _______________

---

## 10:30 — Beberapa Transaksi Lagi (More Transactions)

- [ ] Complete 5+ more sales
- [ ] Mix of: cash sales, kasbon additions, restocks
- [ ] Dev Tools sync queue shows accumulated entries

**Notes:** _______________

---

## 11:00 — Internet Terputus (Offline Mode Begins)

### Network Disconnect
- [ ] Turn off WiFi/data on Android device
- [ ] Verify: home screen still functional
- [ ] Navigate to Hitung Penjualan
- [ ] Complete a sale — should succeed immediately
- [ ] Navigate to Belanja Barang — should work
- [ ] Navigate to Kasbon — should work
- [ ] Dev Tools: sync queue growing, status "Pending"
- [ ] No error dialogs interrupting workflow

### Offline Sale
- [ ] Complete 3 sales while offline
- [ ] All succeed without delay
- [ ] Queue size = 3+ in Dev Tools

### Offline Restock
- [ ] Complete 1 restock while offline
- [ ] Succeeds immediately
- [ ] Stock updates locally

**Notes:** _______________

---

## 12:00 — App Restart while Offline

### Crash Recovery Test
- [ ] Force close the app (swipe away from task manager)
- [ ] Reopen app
- [ ] Verify: all data still present
- [ ] Dev Tools: sync queue preserved (still shows pending entries)
- [ ] Complete another sale — succeeds
- [ ] Queue size has increased correctly

**Notes:** _______________

---

## 13:00 — Internet Kembali (Reconnect)

### Sync on Reconnect
- [ ] Turn WiFi/data back on
- [ ] Wait up to 5 seconds
- [ ] Dev Tools: sync starts automatically
- [ ] Dev Tools "Sinkronisasi Sekarang" button works
- [ ] After sync: queue drains to 0
- [ ] Dev Tools sync log shows successful session(s)
- [ ] Last Sync Time updates

### Verify in Supabase
- [ ] Open Supabase dashboard
- [ ] Table Editor → `sales` — offline sales appear
- [ ] Table Editor → `restocks` — offline restock appears
- [ ] Table Editor → `products` — stock levels updated

**Notes:** _______________

---

## 14:00 — Dashboard Check Mid-Day

### Web Dashboard Review
- [ ] Refresh Overview page
- [ ] Today's revenue reflects all morning transactions
- [ ] Transaction count is correct
- [ ] Navigate to Sales — today's transactions visible
- [ ] Navigate to Products — stock levels updated
- [ ] Navigate to Customers — kasbon customer visible

**Notes:** _______________

---

## 15:00 — Perubahan Harga (Price Change)

### Update Product Selling Options
- [ ] Navigate to Data Produk
- [ ] Edit a product
- [ ] Change selling price for one option
- [ ] Save
- [ ] Navigate to Hitung Penjualan
- [ ] Product shows new price immediately
- [ ] Complete sale at new price
- [ ] Verify saved sale uses new price

**Notes:** _______________

---

## 15:30 — Multi-Device Test (Optional)

### Two Devices Syncing
- [ ] Device A: creates a product
- [ ] Device B: after sync, product is visible
- [ ] Device A: records a sale
- [ ] Device B: after sync, sale visible in Dev Tools log
- [ ] No duplicate records

**Notes:** _______________

---

## 16:00 — Export Laporan (Export Report)

### Dashboard Export
- [ ] Navigate to Dashboard → Export Center
- [ ] Select "30 Hari Terakhir" date range
- [ ] Click "Export CSV" for Penjualan
- [ ] File downloads
- [ ] Open in Excel — headers in Indonesian, data readable
- [ ] Export Products as Excel
- [ ] File downloads and opens correctly

**Notes:** _______________

---

## 16:30 — Analytics Review

### Dashboard Analytics
- [ ] Navigate to Analytics
- [ ] Business Insights section loads
- [ ] Business Health KPI cards load
- [ ] Sales Performance chart renders
- [ ] Inventory Health shows correct product counts
- [ ] Kasbon Health shows outstanding amount

**Notes:** _______________

---

## 17:00 — Backup

### Local Backup
- [ ] Navigate to Dashboard → Backup & Recovery
- [ ] Summary cards show correct data
- [ ] Click "Export & Download"
- [ ] Progress indicator appears
- [ ] File downloads as JSON
- [ ] Open file — valid JSON with all tables present

### Integrity Check
- [ ] Click "Verifikasi Sekarang"
- [ ] All tables show row counts
- [ ] Status shows LULUS (PASS)
- [ ] No issues listed

**Notes:** _______________

---

## 17:30 — Administrasi

### Admin Panel Check
- [ ] Navigate to Admin
- [ ] All 6 summary cards load
- [ ] Devices page: Android device visible
- [ ] Sync Health: sessions visible, success rate shown
- [ ] Organization page: business info correct
- [ ] System Info: version numbers correct

**Notes:** _______________

---

## 18:00 — Tutup Toko (End of Day)

### Final Dashboard Review
- [ ] Overview shows complete day's data
- [ ] Revenue matches sum of all sales
- [ ] Transaction count is correct
- [ ] Kasbon balances are accurate
- [ ] All queues empty
- [ ] No pending sync entries

### Android Dev Tools Final Check
- [ ] Sync Queue: 0 pending
- [ ] Sync Queue: 0 failed
- [ ] Last Sync: within last hour
- [ ] Data Integrity: PASS

**Notes:** _______________

---

## PILOT RESULT

- [ ] **PASS** — All steps completed successfully
- [ ] **FAIL** — Issues found (list below)
- [ ] **PARTIAL** — Most steps passed, minor issues noted

**Issues Found:**
1.
2.
3.

**Overall Assessment:**
_______________

**Signed:** _________________________ **Date:** ___________
