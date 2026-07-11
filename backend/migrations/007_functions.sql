-- =============================================================================
-- Migration 007: Database Functions
-- =============================================================================
-- Business-logic functions that are more efficient to run on the server.
-- =============================================================================

-- -------------------------------------------------------------------------
-- get_customer_balance(customer_id)
-- -------------------------------------------------------------------------
-- Returns the outstanding balance for a customer.
-- Balance = SUM(debt amounts) - SUM(payment amounts)
-- A negative value means the customer has overpaid.
-- This is the authoritative balance calculation — matches the mobile app.
create or replace function get_customer_balance(p_customer_id uuid)
returns bigint
language sql
stable
security definer
as $$
  select coalesce(
    sum(case when type = 'debt'    then  amount else 0 end) -
    sum(case when type = 'payment' then  amount else 0 end),
    0
  )
  from debt_transactions
  where customer_id = p_customer_id;
$$;

-- -------------------------------------------------------------------------
-- get_daily_sales_total(org_id, date)
-- -------------------------------------------------------------------------
-- Returns total sales amount for a specific date (in org's local context).
-- Used by the Web Dashboard "Hari Ini" summary.
create or replace function get_daily_sales_total(
  p_organization_id uuid,
  p_date date
)
returns bigint
language sql
stable
security definer
as $$
  select coalesce(sum(total_amount), 0)
  from sales
  where organization_id = p_organization_id
    and created_at::date = p_date;
$$;

-- -------------------------------------------------------------------------
-- get_daily_sales_count(org_id, date)
-- -------------------------------------------------------------------------
create or replace function get_daily_sales_count(
  p_organization_id uuid,
  p_date date
)
returns bigint
language sql
stable
security definer
as $$
  select count(*)
  from sales
  where organization_id = p_organization_id
    and created_at::date = p_date;
$$;

-- -------------------------------------------------------------------------
-- get_outstanding_kasbon_count(org_id)
-- -------------------------------------------------------------------------
-- Returns count of active customers with outstanding balance > 0.
create or replace function get_outstanding_kasbon_count(p_organization_id uuid)
returns bigint
language sql
stable
security definer
as $$
  select count(distinct customer_id)
  from (
    select
      customer_id,
      sum(case when type = 'debt'    then  amount else 0 end) -
      sum(case when type = 'payment' then  amount else 0 end) as balance
    from debt_transactions dt
    join customers c on c.id = dt.customer_id
    where dt.organization_id = p_organization_id
      and c.is_active = true
    group by customer_id
  ) sub
  where balance > 0;
$$;

-- -------------------------------------------------------------------------
-- pull_changes_since(org_id, since_timestamp)
-- -------------------------------------------------------------------------
-- Returns all records changed after a given timestamp across all sync tables.
-- Used by the sync pull operation — single call returns everything needed.
-- Results are ordered by updated_at asc so the client advances the cursor safely.
create or replace function pull_changes_since(
  p_organization_id uuid,
  p_since           timestamptz
)
returns table (
  table_name  text,
  record_id   uuid,
  operation   text,
  data        jsonb,
  updated_at  timestamptz
)
language sql
stable
security definer
as $$
  -- PRODUCTS (mutable)
  select
    'products'::text,
    id,
    case when is_active then 'upsert' else 'delete' end,
    to_jsonb(p.*),
    p.updated_at
  from products p
  where organization_id = p_organization_id
    and updated_at > p_since

  union all

  -- CUSTOMERS (mutable)
  select
    'customers'::text,
    id,
    case when is_active then 'upsert' else 'delete' end,
    to_jsonb(c.*),
    c.updated_at
  from customers c
  where organization_id = p_organization_id
    and updated_at > p_since

  union all

  -- SALES (append-only)
  select
    'sales'::text,
    id,
    'create'::text,
    to_jsonb(s.*),
    s.created_at
  from sales s
  where organization_id = p_organization_id
    and created_at > p_since

  union all

  -- SALE ITEMS (append-only)
  select
    'sale_items'::text,
    si.id,
    'create'::text,
    to_jsonb(si.*),
    si.id::text::timestamptz  -- no updated_at; use created_at of parent sale
  from sale_items si
  join sales s on s.id = si.sale_id
  where si.organization_id = p_organization_id
    and s.created_at > p_since

  union all

  -- RESTOCKS (append-only)
  select
    'restocks'::text,
    id,
    'create'::text,
    to_jsonb(r.*),
    r.created_at
  from restocks r
  where organization_id = p_organization_id
    and created_at > p_since

  union all

  -- RESTOCK ITEMS (append-only)
  select
    'restock_items'::text,
    ri.id,
    'create'::text,
    to_jsonb(ri.*),
    r.created_at
  from restock_items ri
  join restocks r on r.id = ri.restock_id
  where ri.organization_id = p_organization_id
    and r.created_at > p_since

  union all

  -- DEBT TRANSACTIONS (append-only)
  select
    'debt_transactions'::text,
    id,
    'create'::text,
    to_jsonb(dt.*),
    dt.created_at
  from debt_transactions dt
  where organization_id = p_organization_id
    and created_at > p_since

  union all

  -- STOCK MOVEMENTS (append-only)
  select
    'stock_movements'::text,
    id,
    'create'::text,
    to_jsonb(sm.*),
    sm.created_at
  from stock_movements sm
  where organization_id = p_organization_id
    and created_at > p_since

  order by updated_at asc;
$$;
