-- =============================================================================
-- Migration 001: Organizations
-- =============================================================================
-- The organizations table is the top-level multi-tenancy boundary.
-- Every business record belongs to exactly one organization.
-- The current family shop will use a single organization row.
-- Future multi-business deployment only requires adding new rows here.
-- =============================================================================

-- Enable UUID generation
create extension if not exists "pgcrypto";

-- Organizations table
-- One row per business entity (warung/shop).
create table if not exists organizations (
  id            uuid primary key default gen_random_uuid(),
  name          text not null,
  slug          text not null unique,   -- URL-safe identifier, e.g. 'warung-maju'
  owner_email   text not null,
  is_active     boolean not null default true,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- Organization members — maps Supabase auth users to organizations.
-- A user may belong to multiple organizations (future: admin of multiple shops).
create table if not exists organization_members (
  id              uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  user_id         uuid not null references auth.users(id) on delete cascade,

  -- 'administrator' can manage products, customers, access dashboard.
  -- 'operator'      can use daily operational screens (sales, restock, kasbon).
  role            text not null check (role in ('administrator', 'operator')),

  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),

  unique (organization_id, user_id)
);

-- Helper function: returns the organization_id from the current user's JWT.
-- Used by all RLS policies to avoid repeating the JWT extraction logic.
create or replace function auth.organization_id()
returns uuid
language sql
stable
as $$
  select (auth.jwt() -> 'app_metadata' ->> 'organization_id')::uuid;
$$;

-- Helper function: returns the user role for the current session.
create or replace function auth.user_role()
returns text
language sql
stable
as $$
  select auth.jwt() -> 'app_metadata' ->> 'role';
$$;

-- Trigger: keep updated_at current on organizations
create or replace function update_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger organizations_updated_at
  before update on organizations
  for each row execute function update_updated_at();

create trigger organization_members_updated_at
  before update on organization_members
  for each row execute function update_updated_at();

-- Seed: insert the default organization for the family shop.
-- The actual UUID will be recorded in the app configuration.
insert into organizations (id, name, slug, owner_email)
values (
  '00000000-0000-0000-0000-000000000001',
  'Warung Mr Squirrel',
  'warung-mr-squirrel',
  'owner@mrsquirrel.local'
)
on conflict (id) do nothing;
