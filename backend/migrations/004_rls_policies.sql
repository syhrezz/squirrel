-- =============================================================================
-- Migration 004: Row Level Security
-- =============================================================================
-- (Depends on 001_organizations.sql and 002_business_tables.sql)
--
-- RLS ensures every row is scoped to exactly one organization.
-- The organization_id is resolved from the JWT app_metadata claim
-- using the auth.organization_id() helper defined in migration 001.
--
-- Policy model:
--   SELECT  — any authenticated member of the organization.
--   INSERT  — any authenticated member of the organization.
--   UPDATE  — only on MUTABLE tables (products, customers).
--             Append-only tables have NO update policy by design.
--   DELETE  — disabled on all tables (soft delete or immutable).
-- =============================================================================

alter table products            enable row level security;
alter table sales               enable row level security;
alter table sale_items          enable row level security;
alter table restocks            enable row level security;
alter table restock_items       enable row level security;
alter table stock_movements     enable row level security;
alter table customers           enable row level security;
alter table debt_transactions   enable row level security;
alter table organizations       enable row level security;
alter table organization_members enable row level security;

-- ---------------------------------------------------------------------------
-- PRODUCTS (mutable)
-- ---------------------------------------------------------------------------
create policy "products_select" on products
  for select using (organization_id = auth.organization_id());

create policy "products_insert" on products
  for insert with check (organization_id = auth.organization_id());

create policy "products_update" on products
  for update
  using     (organization_id = auth.organization_id())
  with check (organization_id = auth.organization_id());

-- ---------------------------------------------------------------------------
-- SALES (append-only — no update policy)
-- ---------------------------------------------------------------------------
create policy "sales_select" on sales
  for select using (organization_id = auth.organization_id());

create policy "sales_insert" on sales
  for insert with check (organization_id = auth.organization_id());

-- ---------------------------------------------------------------------------
-- SALE ITEMS (append-only)
-- ---------------------------------------------------------------------------
create policy "sale_items_select" on sale_items
  for select using (organization_id = auth.organization_id());

create policy "sale_items_insert" on sale_items
  for insert with check (organization_id = auth.organization_id());

-- ---------------------------------------------------------------------------
-- RESTOCKS (append-only)
-- ---------------------------------------------------------------------------
create policy "restocks_select" on restocks
  for select using (organization_id = auth.organization_id());

create policy "restocks_insert" on restocks
  for insert with check (organization_id = auth.organization_id());

-- ---------------------------------------------------------------------------
-- RESTOCK ITEMS (append-only)
-- ---------------------------------------------------------------------------
create policy "restock_items_select" on restock_items
  for select using (organization_id = auth.organization_id());

create policy "restock_items_insert" on restock_items
  for insert with check (organization_id = auth.organization_id());

-- ---------------------------------------------------------------------------
-- STOCK MOVEMENTS (append-only)
-- ---------------------------------------------------------------------------
create policy "stock_movements_select" on stock_movements
  for select using (organization_id = auth.organization_id());

create policy "stock_movements_insert" on stock_movements
  for insert with check (organization_id = auth.organization_id());

-- ---------------------------------------------------------------------------
-- CUSTOMERS (mutable)
-- ---------------------------------------------------------------------------
create policy "customers_select" on customers
  for select using (organization_id = auth.organization_id());

create policy "customers_insert" on customers
  for insert with check (organization_id = auth.organization_id());

create policy "customers_update" on customers
  for update
  using     (organization_id = auth.organization_id())
  with check (organization_id = auth.organization_id());

-- ---------------------------------------------------------------------------
-- DEBT TRANSACTIONS (append-only)
-- ---------------------------------------------------------------------------
create policy "debt_transactions_select" on debt_transactions
  for select using (organization_id = auth.organization_id());

create policy "debt_transactions_insert" on debt_transactions
  for insert with check (organization_id = auth.organization_id());

-- ---------------------------------------------------------------------------
-- ORGANIZATIONS
-- ---------------------------------------------------------------------------
create policy "organizations_select" on organizations
  for select using (id = auth.organization_id());

-- ---------------------------------------------------------------------------
-- ORGANIZATION MEMBERS
-- ---------------------------------------------------------------------------
create policy "org_members_select" on organization_members
  for select using (
    organization_id = auth.organization_id()
    or user_id = auth.uid()
  );
