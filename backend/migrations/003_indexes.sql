-- =============================================================================
-- Migration 003: Indexes
-- =============================================================================
-- Every FK gets an index.
-- Every column used in WHERE or ORDER BY gets an index.
-- Every sync-related column gets an index.
-- =============================================================================

-- -------------------------------------------------------------------------
-- PRODUCTS
-- -------------------------------------------------------------------------
create index if not exists idx_products_org        on products (organization_id);
create index if not exists idx_products_updated_at on products (organization_id, updated_at desc);
create index if not exists idx_products_is_active  on products (organization_id, is_active);
create index if not exists idx_products_name       on products (organization_id, name);

-- -------------------------------------------------------------------------
-- SALES
-- -------------------------------------------------------------------------
create index if not exists idx_sales_org           on sales (organization_id);
create index if not exists idx_sales_created_at    on sales (organization_id, created_at desc);
create index if not exists idx_sales_device        on sales (device_id);

-- -------------------------------------------------------------------------
-- SALE ITEMS
-- -------------------------------------------------------------------------
create index if not exists idx_sale_items_org       on sale_items (organization_id);
create index if not exists idx_sale_items_sale      on sale_items (sale_id);
create index if not exists idx_sale_items_product   on sale_items (product_id);

-- -------------------------------------------------------------------------
-- RESTOCKS
-- -------------------------------------------------------------------------
create index if not exists idx_restocks_org         on restocks (organization_id);
create index if not exists idx_restocks_created_at  on restocks (organization_id, created_at desc);
create index if not exists idx_restocks_device      on restocks (device_id);

-- -------------------------------------------------------------------------
-- RESTOCK ITEMS
-- -------------------------------------------------------------------------
create index if not exists idx_restock_items_org      on restock_items (organization_id);
create index if not exists idx_restock_items_restock  on restock_items (restock_id);
create index if not exists idx_restock_items_product  on restock_items (product_id);

-- -------------------------------------------------------------------------
-- STOCK MOVEMENTS
-- -------------------------------------------------------------------------
create index if not exists idx_stock_movements_org        on stock_movements (organization_id);
create index if not exists idx_stock_movements_product    on stock_movements (product_id);
create index if not exists idx_stock_movements_source     on stock_movements (source_id);
create index if not exists idx_stock_movements_created_at on stock_movements (organization_id, created_at desc);
create index if not exists idx_stock_movements_type       on stock_movements (source_type);

-- -------------------------------------------------------------------------
-- CUSTOMERS
-- -------------------------------------------------------------------------
create index if not exists idx_customers_org         on customers (organization_id);
create index if not exists idx_customers_updated_at  on customers (organization_id, updated_at desc);
create index if not exists idx_customers_is_active   on customers (organization_id, is_active);
create index if not exists idx_customers_name        on customers (organization_id, name);

-- -------------------------------------------------------------------------
-- DEBT TRANSACTIONS
-- -------------------------------------------------------------------------
create index if not exists idx_debt_transactions_org         on debt_transactions (organization_id);
create index if not exists idx_debt_transactions_customer    on debt_transactions (customer_id);
create index if not exists idx_debt_transactions_created_at  on debt_transactions (customer_id, created_at desc);
create index if not exists idx_debt_transactions_type        on debt_transactions (customer_id, type);

-- -------------------------------------------------------------------------
-- ORGANIZATION MEMBERS
-- -------------------------------------------------------------------------
create index if not exists idx_org_members_user   on organization_members (user_id);
create index if not exists idx_org_members_org    on organization_members (organization_id);
