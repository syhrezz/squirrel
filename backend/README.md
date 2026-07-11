# Mr Squirrel — Backend

Supabase PostgreSQL backend for the Mr Squirrel warung kelontong system.

## Directory structure

```
backend/
├── migrations/
│   ├── 001_organizations.sql      Organizations, members, auth helpers
│   ├── 002_business_tables.sql    Products, sales, restocks, customers, etc.
│   ├── 003_indexes.sql            Indexes on every FK and query column
│   ├── 004_rls_policies.sql       Row Level Security policies
│   ├── 005_sync_tables.sql        device_info, sync_log
│   ├── 006_storage.sql            Storage buckets and policies
│   └── 007_functions.sql          DB functions (balance, sales totals, pull_changes_since)
├── seed/
│   └── (empty — seeding handled via Android dev tools)
├── functions/
│   └── (edge functions — future use)
└── .env.example                   Required environment variables
```

## Applying migrations

Run migrations in order using the Supabase CLI:

```bash
supabase db push
```

Or apply manually via the Supabase dashboard SQL editor in order: 001 → 007.

## Environment variables

Copy `.env.example` to `.env` and fill in the values.
Never commit `.env` to version control.

## Multi-tenancy

Every business table has `organization_id uuid not null`.
RLS policies ensure users only see their own organization's data.
The current family shop uses organization_id `00000000-0000-0000-0000-000000000001`.

## Sync design

The `pull_changes_since(org_id, since_timestamp)` function (migration 007)
returns all changed records across all tables in a single call, ordered by
`updated_at asc`. The Android app advances its cursor after each successful pull.

Push uses direct table upserts — one Supabase request per record, grouped by table.

## RLS policy model

| Table              | SELECT | INSERT | UPDATE | DELETE |
|--------------------|--------|--------|--------|--------|
| products           | org    | org    | org    | —      |
| customers          | org    | org    | org    | —      |
| sales              | org    | org    | —      | —      |
| sale_items         | org    | org    | —      | —      |
| restocks           | org    | org    | —      | —      |
| restock_items      | org    | org    | —      | —      |
| stock_movements    | org    | org    | —      | —      |
| debt_transactions  | org    | org    | —      | —      |

Append-only tables have no UPDATE policy enforced at the database level.
