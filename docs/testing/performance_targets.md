# Performance Targets — MR SQUIRREL

All measurements are taken on mid-range hardware (Android 10+, 4GB RAM, standard 4G connection).
Dashboard targets are measured in Chrome on a 1440p display.

## Android Application

| Operation | Target | Critical Limit | Notes |
|-----------|--------|----------------|-------|
| App cold start | < 2s | 4s | Time from tap to home screen |
| Home screen render | < 1s | 2s | First frame visible |
| Product list load | < 500ms | 1s | 100 products |
| Product search | < 100ms | 300ms | Instant local filter |
| Add to cart (tap) | < 50ms | 100ms | No network required |
| Sale save | < 300ms | 500ms | SQLite write + queue |
| Restock save | < 300ms | 500ms | SQLite write + queue |
| Kasbon add debt | < 200ms | 400ms | SQLite write |
| Navigation between screens | < 200ms | 400ms | |
| Category filter | < 100ms | 200ms | Local operation |
| Selling options bottom sheet | < 100ms | 200ms | Opens instantly |

## Synchronization

| Operation | Target | Critical Limit | Notes |
|-----------|--------|----------------|-------|
| Sync 10 records | < 2s | 5s | Over 4G |
| Sync 100 records | < 10s | 20s | Over 4G |
| Sync 1,000 records | < 60s | 120s | Batch push |
| Sync 10,000 records | < 300s | 600s | Background |
| isReachable() check | < 500ms | 2s | DNS lookup |
| Initial sync (first launch) | < 30s | 60s | Empty database |
| Reconnect after offline | < 3s | 10s | Auto-trigger |
| Queue drain (pending=0) | < 15s | 30s | After reconnect |

## Web Dashboard

| Page | Target | Critical Limit | Notes |
|------|--------|----------------|-------|
| Login page | < 500ms | 1s | |
| Overview dashboard | < 2s | 4s | All 6 KPI cards |
| Products list (25 rows) | < 1.5s | 3s | First page |
| Sales list (25 rows) | < 1.5s | 3s | First page |
| Product detail | < 2s | 4s | Including selling options |
| Analytics page | < 3s | 6s | All sections independent |
| Admin devices page | < 2s | 4s | |

## Export

| Operation | Target | Critical Limit | Notes |
|-----------|--------|----------------|-------|
| Export 100 rows CSV | < 2s | 5s | Including download |
| Export 1,000 rows CSV | < 5s | 10s | |
| Export 10,000 rows CSV | < 15s | 30s | |
| Export Products (all) | < 5s | 10s | |
| Integrity check | < 10s | 20s | 8 tables |

## Offline Mode

| Scenario | Target | Critical Limit |
|----------|--------|----------------|
| App functional while offline | Immediate | N/A |
| Sale creation offline | < 300ms | 500ms |
| Queue growth (offline) | No limit | Memory only |
| Queue persistence (restart) | 100% | 100% |

## How to Measure

- Android: Use Flutter DevTools Performance tab
- Dashboard: Use Chrome DevTools Network + Performance tabs
- Sync: Use Dev Tools sync log timestamps in Android app
- Database: Use Supabase Dashboard query analyzer
