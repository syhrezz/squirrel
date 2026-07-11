-- =============================================================================
-- Migration 002: Business Tables
-- =============================================================================
-- Mirrors the SQLite schema exactly, with these additions:
--   • organization_id on every business table (multi-tenancy)
--   • timestamptz instead of INTEGER epoch ms for all timestamps
--   • created_at / updated_at where appropriate
--   • Append-only tables have no updated_at (records never change)
-- =============================================================================

-- -------------------------------------------------------------------------
-- PRODUCTS
-- -------------------------------------------------------------------------
-- Mutable: last-write-wins on sync (by updated_at).
-- Conflict strategy: LastWriteWins
create table if not exists products (
  id              uuid primary key,
  organization_id uuid not null references organizations(id),

  name            text not null,
  unit            text not null,
  custom_unit     text,

  -- Latest known selling price in IDR (integer, no decimals).
  sell_price      bigint not null check (sell_price >= 0),

  -- Convenience field only. Authoritative history is in restock_items.
  last_buy_price  bigint not null check (last_buy_price >= 0),

  -- Maintained by sales/restock events only. Never edited directly.
  current_stock   bigint not null default 0,

  -- Soft delete.
  is_active       boolean not null default true,

  -- Sync metadata
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  created_by      uuid not null references auth.users(id),
  updated_by      uuid not null references auth.users(id),
  device_id       text not null
);

create trigger products_updated_at
  before update on products
  for each row execute function update_updated_at();

-- -------------------------------------------------------------------------
-- SALES
-- -------------------------------------------------------------------------
-- Append-only. Never update or delete rows.
create table if not exists sales (
  id              uuid primary key,
  organization_id uuid not null references organizations(id),

  total_amount    bigint not null check (total_amount >= 0),
  amount_paid     bigint not null check (amount_paid >= 0),
  change_amount   bigint not null check (change_amount >= 0),

  -- Sync metadata
  created_at      timestamptz not null default now(),
  created_by      uuid not null references auth.users(id),
  device_id       text not null
);

-- -------------------------------------------------------------------------
-- SALE ITEMS
-- -------------------------------------------------------------------------
-- Append-only. selling_price is a snapshot — never read from products.
create table if not exists sale_items (
  id              uuid primary key,
  organization_id uuid not null references organizations(id),
  sale_id         uuid not null references sales(id),
  product_id      uuid not null references products(id),

  quantity        bigint not null check (quantity > 0),
  selling_price   bigint not null check (selling_price >= 0),  -- snapshot
  subtotal        bigint not null check (subtotal >= 0)         -- derived, stored
);

-- -------------------------------------------------------------------------
-- RESTOCKS
-- -------------------------------------------------------------------------
-- Append-only. Records one shopping trip.
create table if not exists restocks (
  id              uuid primary key,
  organization_id uuid not null references organizations(id),

  total_amount    bigint not null check (total_amount >= 0),

  -- Sync metadata
  created_at      timestamptz not null default now(),
  created_by      uuid not null references auth.users(id),
  device_id       text not null
);

-- -------------------------------------------------------------------------
-- RESTOCK ITEMS
-- -------------------------------------------------------------------------
-- Append-only. purchase_price is a snapshot — never read from products.
create table if not exists restock_items (
  id              uuid primary key,
  organization_id uuid not null references organizations(id),
  restock_id      uuid not null references restocks(id),
  product_id      uuid not null references products(id),

  quantity        bigint not null check (quantity > 0),
  purchase_price  bigint not null check (purchase_price >= 0),  -- snapshot
  subtotal        bigint not null check (subtotal >= 0)          -- derived, stored
);

-- -------------------------------------------------------------------------
-- STOCK MOVEMENTS
-- -------------------------------------------------------------------------
-- Append-only ledger. Every stock change creates a new row.
-- source_type: 'sale' | 'restock' | 'adjustment'
create table if not exists stock_movements (
  id              uuid primary key,
  organization_id uuid not null references organizations(id),
  product_id      uuid not null references products(id),

  -- Positive = stock in, negative = stock out.
  quantity_change bigint not null,

  source_type     text not null check (source_type in ('sale', 'restock', 'adjustment')),

  -- UUID of originating sale/restock/adjustment record.
  -- Not a FK because it can reference multiple tables (polymorphic).
  source_id       text not null,

  note            text,

  -- Sync metadata
  created_at      timestamptz not null default now(),
  created_by      uuid not null references auth.users(id),
  device_id       text not null
);

-- -------------------------------------------------------------------------
-- CUSTOMERS
-- -------------------------------------------------------------------------
-- Mutable: last-write-wins on sync.
-- Conflict strategy: LastWriteWins
create table if not exists customers (
  id              uuid primary key,
  organization_id uuid not null references organizations(id),

  name            text not null,
  phone           text,
  note            text,

  -- Soft delete.
  is_active       boolean not null default true,

  -- Sync metadata
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  created_by      uuid not null references auth.users(id),
  updated_by      uuid not null references auth.users(id)
);

create trigger customers_updated_at
  before update on customers
  for each row execute function update_updated_at();

-- -------------------------------------------------------------------------
-- DEBT TRANSACTIONS
-- -------------------------------------------------------------------------
-- Append-only kasbon ledger.
-- type: 'debt' | 'payment'
-- Balance is NEVER stored — always calculated from this table.
create table if not exists debt_transactions (
  id              uuid primary key,
  organization_id uuid not null references organizations(id),
  customer_id     uuid not null references customers(id),

  type            text not null check (type in ('debt', 'payment')),
  amount          bigint not null check (amount > 0),
  note            text,

  -- Sync metadata
  created_at      timestamptz not null default now(),
  created_by      uuid not null references auth.users(id)
);
