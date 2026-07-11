# Acceptance Checklist — MR SQUIRREL v1.0

Complete this checklist before every release.
Record result, tester name, and date for each item.

**Status values:** PASS | FAIL | BLOCKED | SKIP

---

## MODULE 1 — Installation & Setup

| ID | Title | P | Preconditions | Steps | Expected Result | Status | Tester | Date | Notes |
|----|-------|---|---------------|-------|-----------------|--------|--------|------|-------|
| INS-001 | Android APK installs | P0 | Android 10+ device | 1. Install APK 2. Launch app | App opens without crash | | | | |
| INS-002 | First launch seeds data | P1 | Fresh install | 1. Launch app first time | Home screen shows with sample products | | | | |
| INS-003 | App survives force close | P0 | App running | 1. Force close 2. Reopen | App opens, data intact | | | | |
| INS-004 | Supabase connection | P0 | Credentials configured | 1. Open Dev Tools | Green dot "Supabase terhubung" | | | | |
| INS-005 | Dashboard loads in Chrome | P0 | Web build deployed | 1. Open dashboard URL | Login page visible | | | | |

---

## MODULE 2 — Authentication (Dashboard)

| ID | Title | P | Preconditions | Steps | Expected Result | Status | Tester | Date | Notes |
|----|-------|---|---------------|-------|-----------------|--------|--------|------|-------|
| AUTH-001 | Valid login succeeds | P0 | Account exists in Supabase | 1. Enter valid email+password 2. Click Sign In | Redirected to /overview | | | | |
| AUTH-002 | Invalid login fails | P0 | | 1. Enter wrong password 2. Click Sign In | Error message shown, no redirect | | | | |
| AUTH-003 | Empty form validation | P1 | | 1. Leave email empty 2. Submit | Field validation error shown | | | | |
| AUTH-004 | Protected routes redirect | P0 | Not logged in | 1. Navigate to /overview directly | Redirected to /login | | | | |
| AUTH-005 | Logout works | P0 | Logged in | 1. Click Logout in sidebar | Redirected to /login, session cleared | | | | |
| AUTH-006 | Session persists on refresh | P1 | Logged in | 1. Refresh browser | Remains on current page, not logged out | | | | |

---

## MODULE 3 — Products (Android)

| ID | Title | P | Preconditions | Steps | Expected Result | Status | Tester | Date | Notes |
|----|-------|---|---------------|-------|-----------------|--------|--------|------|-------|
| PROD-001 | Product list loads | P0 | Products exist | 1. Navigate to Data Produk | Product list visible within 1s | | | | |
| PROD-002 | Create product | P0 | | 1. Tap tambah 2. Fill all fields 3. Add 1 selling option 4. Save | Product appears in list | | | | |
| PROD-003 | Edit product | P0 | Product exists | 1. Tap product 2. Edit name 3. Save | Name updated in list | | | | |
| PROD-004 | Deactivate product | P1 | Product exists | 1. Tap edit 2. Tap deactivate 3. Confirm | Product hidden from operational screens | | | | |
| PROD-005 | Search filters products | P1 | Multiple products | 1. Type product name in search | Only matching products shown | | | | |
| PROD-006 | Category filter works | P1 | Products in multiple categories | 1. Select a category chip | Only products in that category shown | | | | |
| PROD-007 | Inventory unit saved | P1 | | 1. Create product with unit=gram | Unit displays as gram on all screens | | | | |
| PROD-008 | Purchase unit saved | P1 | | 1. Create product with purchaseUnit=Karung | Purchase unit shown in restock screen | | | | |

---

## MODULE 4 — Selling Options (Android)

| ID | Title | P | Preconditions | Steps | Expected Result | Status | Tester | Date | Notes |
|----|-------|---|---------------|-------|-----------------|--------|--------|------|-------|
| SO-001 | Add selling option | P0 | Product in edit mode | 1. Add option "500 gram" qty=500 price=11000 2. Save | Option saved | | | | |
| SO-002 | Multiple options | P0 | | 1. Add 3 selling options 2. Save | All 3 options saved | | | | |
| SO-003 | Single option direct add | P0 | Product with 1 option | 1. Tap product in Penjualan | Added to cart immediately | | | | |
| SO-004 | Multiple options bottom sheet | P0 | Product with 2+ options | 1. Tap product in Penjualan | Bottom sheet shows all options | | | | |
| SO-005 | Select option from sheet | P0 | Bottom sheet open | 1. Tap "500 gram" | Item added to cart with correct price | | | | |
| SO-006 | Manual price option | P1 | allow_manual_price=true | 1. Tap product 2. Select option 3. Edit price | Cart uses edited price | | | | |
| SO-007 | Selling option deactivate | P2 | Option exists | 1. Edit product 2. Save with option removed | Option no longer shown in Penjualan | | | | |

---

## MODULE 5 — Unit Conversion (Android)

| ID | Title | P | Preconditions | Steps | Expected Result | Status | Tester | Date | Notes |
|----|-------|---|---------------|-------|-----------------|--------|--------|------|-------|
| UC-001 | Stock added in inventory units | P0 | Product: purchaseUnit=Dus, conversion=40 | 1. Restock 2 Dus | Stock increases by 80 pcs | | | | |
| UC-002 | Helper text visible | P1 | Above setup | 1. Add product to restock | "Menambah stok: 80 pcs" text shown | | | | |
| UC-003 | Selling deducts inventory units | P0 | Product: inventory unit=gram, option=500g | 1. Sell 1× 500gram option | Stock decreases by 500 grams | | | | |
| UC-004 | Large conversion | P1 | conversion=1000 | 1. Restock 1 unit | Stock increases by 1000 | | | | |
| UC-005 | Conversion=1 (no conversion) | P1 | conversion=1 | 1. Restock 5 pcs | Stock increases by 5 | | | | |

---

## MODULE 6 — Restock / Belanja (Android)

| ID | Title | P | Preconditions | Steps | Expected Result | Status | Tester | Date | Notes |
|----|-------|---|---------------|-------|-----------------|--------|--------|------|-------|
| RST-001 | Search for product | P0 | Products exist | 1. Type name in search | Matching products shown | | | | |
| RST-002 | Add product to list | P0 | | 1. Tap product in results | Product appears in shopping list | | | | |
| RST-003 | Set quantity | P0 | Product in list | 1. Increment quantity to 3 | Quantity shows 3 | | | | |
| RST-004 | Set purchase price | P0 | | 1. Enter price 50000 | Subtotal = 150000 | | | | |
| RST-005 | Save restock | P0 | Items in list | 1. Tap Simpan Belanja | Success snackbar, list clears | | | | |
| RST-006 | Stock updates after save | P0 | | 1. Check product stock after save | Stock increased by inventoryStockAdded | | | | |
| RST-007 | Last buy price updates | P1 | | 1. Restock at new price | Product lastBuyPrice updated | | | | |
| RST-008 | Clear list | P1 | Items in list | 1. Tap Bersihkan | List empties | | | | |
| RST-009 | Offline restock | P0 | No internet | 1. Complete restock while offline | Succeeds, queued for sync | | | | |

---

## MODULE 7 — Sales / Penjualan (Android)

| ID | Title | P | Preconditions | Steps | Expected Result | Status | Tester | Date | Notes |
|----|-------|---|---------------|-------|-----------------|--------|--------|------|-------|
| SALE-001 | Discovery sections visible | P0 | Some sales history | 1. Open Hitung Penjualan | "Sering Dijual", "Pilih Kategori" visible | | | | |
| SALE-002 | Search product | P1 | | 1. Type product name | Matching products shown | | | | |
| SALE-003 | Add from category | P0 | Products with categories | 1. Tap category chip | Products shown | | | | |
| SALE-004 | Add product to cart | P0 | | 1. Tap product | Added to cart | | | | |
| SALE-005 | Increment quantity | P0 | Item in cart | 1. Tap + button | Quantity increases | | | | |
| SALE-006 | Decrement to zero removes | P1 | Qty=1 in cart | 1. Tap - | Item removed from cart | | | | |
| SALE-007 | Total calculates correctly | P0 | 2+ items | Check total | Total = sum of all subtotals | | | | |
| SALE-008 | Exact payment | P0 | | 1. Enter exact amount | Kembalian = 0 | | | | |
| SALE-009 | Overpayment | P0 | | 1. Enter more than total | Kembalian = overpayment amount | | | | |
| SALE-010 | Underpayment blocked | P0 | | 1. Enter less than total | "Selesaikan" button disabled | | | | |
| SALE-011 | Complete transaction | P0 | | 1. Enter payment 2. Tap Selesaikan | Success snackbar, cart clears | | | | |
| SALE-012 | Stock decreases | P0 | | After sale | Product stock decreased by sold qty | | | | |
| SALE-013 | Offline sale | P0 | No internet | 1. Complete sale offline | Succeeds immediately | | | | |
| SALE-014 | Zero stock prevention | P1 | Stock=0 | 1. Try to add to cart | Should warn (behavior TBD) | | | | |
| SALE-015 | Bersihkan cart | P1 | Items in cart | 1. Tap Bersihkan | Cart empties | | | | |

---

## MODULE 8 — Kasbon (Android)

| ID | Title | P | Preconditions | Steps | Expected Result | Status | Tester | Date | Notes |
|----|-------|---|---------------|-------|-----------------|--------|--------|------|-------|
| KAS-001 | Customer list loads | P0 | Customers exist | 1. Open Kasbon | Customers visible | | | | |
| KAS-002 | Search customer | P1 | | 1. Type name | Matching customers shown | | | | |
| KAS-003 | Add new customer | P0 | | 1. Tap + 2. Enter name 3. Save | Customer appears in list | | | | |
| KAS-004 | Record debt | P0 | Customer exists | 1. Tap customer 2. Catat Hutang 3. Enter amount | Balance increases | | | | |
| KAS-005 | Record payment | P0 | Customer has debt | 1. Catat Bayar 2. Enter amount | Balance decreases | | | | |
| KAS-006 | Full payment = Lunas | P0 | | 1. Pay exact balance | Status shows Lunas | | | | |
| KAS-007 | Overpayment shows negative | P1 | | 1. Pay more than balance | Balance shows negative / Lebih Bayar | | | | |
| KAS-008 | Transaction timeline | P1 | Multiple transactions | 1. View customer detail | All transactions shown newest first | | | | |
| KAS-009 | Note saved | P2 | | 1. Add debt with note | Note visible in timeline | | | | |
| KAS-010 | Deactivate customer | P1 | | 1. Deactivate | Customer hidden from list | | | | |

---

## MODULE 9 — Synchronization

| ID | Title | P | Preconditions | Steps | Expected Result | Status | Tester | Date | Notes |
|----|-------|---|---------------|-------|-----------------|--------|--------|------|-------|
| SYNC-001 | Auto sync on app start | P0 | Internet available | 1. Cold start app | Sync starts within 5 seconds | | | | |
| SYNC-002 | Periodic sync | P1 | App running 30+ min | Wait 30 minutes | Sync fires automatically | | | | |
| SYNC-003 | Manual sync trigger | P0 | Dev Tools open | 1. Tap Sinkronisasi Sekarang | Sync runs, queue updates | | | | |
| SYNC-004 | Offline create syncs on reconnect | P0 | Offline | 1. Create product offline 2. Reconnect | Product appears in Supabase | | | | |
| SYNC-005 | Queue survives app restart | P0 | Pending items in queue | 1. Force close app 2. Reopen | Queue preserved, items still pending | | | | |
| SYNC-006 | Syncing→pending reset | P0 | | 1. Kill app during sync 2. Reopen | Items reset to pending, not stuck in syncing | | | | |
| SYNC-007 | Retry backoff | P1 | Items failing | Check next_retry_at | Each failure increases retry delay exponentially | | | | |
| SYNC-008 | No duplicates | P0 | After sync | Check Supabase | Same UUID appears only once per table | | | | |
| SYNC-009 | Products push before sale_items | P0 | New product + sale | 1. Sync | No FK violation errors | | | | |
| SYNC-010 | Large queue (1000 records) | P1 | 1000+ queue entries | 1. Generate via Dev Tools 2. Sync | All records sync within 5 minutes | | | | |
| SYNC-011 | Two devices simultaneous | P1 | Two devices | 1. Both create products offline 2. Both reconnect | Both products in Supabase, no conflicts | | | | |
| SYNC-012 | Device offline 24+ hours | P1 | | 1. Offline 24h 2. Create 10 records 3. Reconnect | All 10 records sync | | | | |
| SYNC-013 | Conflict resolution LWW | P2 | Same product edited on 2 devices | 1. Both edit same product 2. Sync | Newer updated_at wins | | | | |
| SYNC-014 | Append-only tables never update | P0 | | Attempt to update a sale in Supabase directly | Rejected by RLS policy | | | | |
| SYNC-015 | organization_id in every payload | P0 | | Inspect Supabase rows after sync | Every row has correct organization_id | | | | |

---

## MODULE 10 — Dashboard General

| ID | Title | P | Preconditions | Steps | Expected Result | Status | Tester | Date | Notes |
|----|-------|---|---------------|-------|-----------------|--------|--------|------|-------|
| DASH-001 | All pages load | P0 | Logged in | 1. Navigate to every sidebar item | No errors, no blank screens | | | | |
| DASH-002 | Sidebar navigation | P0 | | 1. Click every sidebar item | Correct page loads | | | | |
| DASH-003 | Back navigation | P1 | On detail page | 1. Click back arrow | Returns to list page | | | | |
| DASH-004 | Row click navigates to detail | P0 | List page | 1. Click any row | Detail page loads | | | | |
| DASH-005 | Refresh button works | P1 | Any list page | 1. Click Refresh | Data reloads | | | | |
| DASH-006 | Search debounces | P1 | | 1. Type quickly | No request until 300ms pause | | | | |
| DASH-007 | Pagination works | P1 | More than 25 records | 1. Click next page | Next 25 records load | | | | |
| DASH-008 | Page size change | P2 | | 1. Change to 50/page | Table reloads with 50 rows | | | | |
| DASH-009 | Sort ascending | P1 | | 1. Click column header | Rows sorted ascending | | | | |
| DASH-010 | Sort descending | P1 | Already sorted asc | 1. Click same header | Rows sorted descending | | | | |
| DASH-011 | Filter resets | P1 | Filter active | 1. Click Reset | All filters cleared, all records shown | | | | |
| DASH-012 | Empty state shown | P2 | No records for filter | 1. Filter with no results | Empty state message shown | | | | |
| DASH-013 | Error state shows retry | P1 | Supabase offline | 1. Navigate to any page | Error message + Retry button shown | | | | |

---

## MODULE 11 — Analytics

| ID | Title | P | Preconditions | Steps | Expected Result | Status | Tester | Date | Notes |
|----|-------|---|---------------|-------|-----------------|--------|--------|------|-------|
| ANA-001 | Page loads | P0 | | 1. Navigate to /analytics | All sections load independently | | | | |
| ANA-002 | Business Insights shown | P0 | | | Insights appear with priority badges | | | | |
| ANA-003 | Business Health KPIs | P0 | Sales data | | 6 metric cards show real data | | | | |
| ANA-004 | Revenue chart renders | P1 | 30 days sales | | Line chart visible | | | | |
| ANA-005 | Inventory section correct | P0 | Products exist | | Out of stock / low stock count correct | | | | |
| ANA-006 | Kasbon section shows outstanding | P0 | Kasbon records | | Outstanding amount matches sum | | | | |
| ANA-007 | Section failure isolated | P1 | One section fails | | Other sections still load | | | | |
| ANA-008 | Refresh button reloads all | P1 | | 1. Click Refresh | All sections reload | | | | |

---

## MODULE 12 — Administration

| ID | Title | P | Preconditions | Steps | Expected Result | Status | Tester | Date | Notes |
|----|-------|---|---------------|-------|-----------------|--------|--------|------|-------|
| ADM-001 | Admin home loads | P0 | | Navigate to /admin | 6 summary cards visible | | | | |
| ADM-002 | Devices page | P0 | Device synced | Navigate to /admin/devices | Android device listed with status | | | | |
| ADM-003 | Sync health loads | P0 | | Navigate to /admin/sync | Sessions table and KPIs visible | | | | |
| ADM-004 | Period filter | P1 | | 1. Switch from 7d to 30d | Data updates | | | | |
| ADM-005 | Organization page | P1 | | Navigate to /admin/organization | Business name and system info shown | | | | |
| ADM-006 | Coming soon dialogs | P2 | | 1. Click Invite User | "Coming Soon" dialog appears | | | | |

---

## MODULE 13 — Export

| ID | Title | P | Preconditions | Steps | Expected Result | Status | Tester | Date | Notes |
|----|-------|---|---------------|-------|-----------------|--------|--------|------|-------|
| EXP-001 | Export CSV — Sales | P0 | Sales data | 1. Select date range 2. Click Export CSV | File downloads | | | | |
| EXP-002 | CSV opens in Excel | P0 | Downloaded file | 1. Open in Excel | Headers in row 1, data in rows 2+ | | | | |
| EXP-003 | Indonesian characters | P1 | Products with Indonesian names | Export Products | Names render correctly in Excel | | | | |
| EXP-004 | Export all modules | P1 | Data in all modules | Export each one | All 8 modules export successfully | | | | |
| EXP-005 | Export history recorded | P2 | After export | Check history table | Filename, date, record count shown | | | | |
| EXP-006 | PDF disabled | P1 | | 1. Click PDF button | Button is disabled, tooltip shown | | | | |
| EXP-007 | Empty export | P2 | Filter with no results | 1. Set future date range 2. Export | Empty CSV with headers only | | | | |
| EXP-008 | Currency formatted | P1 | | Open exported CSV | Amounts show as "Rp12.500" format | | | | |

---

## MODULE 14 — Backup

| ID | Title | P | Preconditions | Steps | Expected Result | Status | Tester | Date | Notes |
|----|-------|---|---------------|-------|-----------------|--------|--------|------|-------|
| BAK-001 | Page loads | P0 | | Navigate to /backup | Summary cards visible | | | | |
| BAK-002 | Local backup downloads | P0 | | 1. Click Export & Download | JSON file downloads | | | | |
| BAK-003 | Backup is valid JSON | P0 | Downloaded file | 1. Open in text editor | Valid JSON with all tables | | | | |
| BAK-004 | Integrity check passes | P0 | Clean database | 1. Click Verifikasi | LULUS shown, table counts visible | | | | |
| BAK-005 | Integrity check detects issues | P1 | Orphan records exist | 1. Click Verifikasi | GAGAL shown with issue description | | | | |
| BAK-006 | Restore dialog shows warning | P1 | | 1. Click Restore | Warning dialog with red danger styling | | | | |

---

## MODULE 15 — Offline Mode

| ID | Title | P | Preconditions | Steps | Expected Result | Status | Tester | Date | Notes |
|----|-------|---|---------------|-------|-----------------|--------|--------|------|-------|
| OFF-001 | App functions offline | P0 | No internet | 1. Turn off network | All screens still navigable | | | | |
| OFF-002 | Sales work offline | P0 | | 1. Complete sale offline | Succeeds without delay | | | | |
| OFF-003 | Restock works offline | P0 | | 1. Complete restock offline | Succeeds without delay | | | | |
| OFF-004 | Kasbon works offline | P0 | | 1. Add debt offline | Succeeds without delay | | | | |
| OFF-005 | Queue grows offline | P0 | | 1. 5 operations offline | Dev Tools: 5+ items queued | | | | |
| OFF-006 | No error dialogs offline | P0 | | 1. Use app offline for 5 min | No unexpected error popups | | | | |
| OFF-007 | Queue drains on reconnect | P0 | Items queued | 1. Reconnect internet | Queue empties within 30s | | | | |

---

## MODULE 16 — Search & Filter

| ID | Title | P | Preconditions | Steps | Expected Result | Status | Tester | Date | Notes |
|----|-------|---|---------------|-------|-----------------|--------|--------|------|-------|
| SRH-001 | Product search | P0 | | 1. Type "Indomie" | Only Indomie products shown | | | | |
| SRH-002 | Customer search | P0 | | 1. Type customer name | Only matching customers shown | | | | |
| SRH-003 | Sale search by cashier | P1 | | 1. Type cashier name | Matching sales shown | | | | |
| SRH-004 | Date filter today | P1 | | 1. Click Hari Ini | Only today's records | | | | |
| SRH-005 | Date filter 30 days | P1 | | 1. Click 30 Hari | Last 30 days of records | | | | |
| SRH-006 | Balance filter | P1 | | 1. Click Ada Hutang | Only customers with debt | | | | |
| SRH-007 | Stock filter | P1 | | 1. Click Stok Rendah | Only products with 1-3 stock | | | | |
| SRH-008 | Reset filter | P1 | Filter active | 1. Click Reset | All records visible | | | | |

---

## MODULE 17 — Data Integrity (Android)

| ID | Title | P | Preconditions | Steps | Expected Result | Status | Tester | Date | Notes |
|----|-------|---|---------------|-------|-----------------|--------|--------|------|-------|
| INT-001 | Integrity check passes | P0 | Clean database | Dev Tools → Run Check | 0 issues | | | | |
| INT-002 | Sale total matches items | P0 | After creating sale | Manual check | sale.totalAmount = sum(sale_items.subtotal) | | | | |
| INT-003 | Restock total matches items | P0 | After restock | Manual check | restock.totalAmount = sum(restock_items.subtotal) | | | | |
| INT-004 | Stock movements match stock | P1 | After operations | Integrity check | current_stock = sum(stock_movements) for products with movements | | | | |
| INT-005 | No negative stock | P0 | After sales | Check products | No product has current_stock < 0 | | | | |

---

## MODULE 18 — Recovery

| ID | Title | P | Preconditions | Steps | Expected Result | Status | Tester | Date | Notes |
|----|-------|---|---------------|-------|-----------------|--------|--------|------|-------|
| REC-001 | Syncing reset on startup | P0 | App killed during sync | 1. Kill app during sync 2. Reopen 3. Check Dev Tools | Items back to "pending", not stuck in "syncing" | | | | |
| REC-002 | Failed records retry | P0 | Failed items in queue | 1. Wait for retry timer | Items retry after backoff period | | | | |
| REC-003 | Queue survives restart | P0 | Pending items | 1. Force close 2. Reopen | Queue items still present | | | | |
| REC-004 | Partial sync recovers | P1 | Mid-sync disconnect | 1. Disconnect during sync 2. Reconnect | Remaining items sync on next attempt | | | | |

---

*Checklist version: 1.0 — MR SQUIRREL QA*
*Total test cases: 144*
