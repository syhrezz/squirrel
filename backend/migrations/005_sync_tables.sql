-- =============================================================================
-- Migration 005: Sync Infrastructure Tables
-- =============================================================================
-- These tables support the sync layer.
-- They are NOT business tables — they belong to the sync system only.
-- =============================================================================

-- -------------------------------------------------------------------------
-- DEVICE INFO
-- -------------------------------------------------------------------------
-- One row per physical device.
-- Tracks the pull cursor so each device knows where to resume syncing.
create table if not exists device_info (
  device_id       text primary key,
  organization_id uuid not null references organizations(id),
  user_id         uuid not null references auth.users(id),
  device_name     text not null,
  platform        text not null check (platform in ('android', 'ios', 'web')),
  app_version     text not null,
  created_at      timestamptz not null default now(),
  last_sync_at    timestamptz,

  -- Pull cursor — server will return records updated after this timestamp.
  last_pull_timestamp timestamptz
);

create index if not exists idx_device_info_org    on device_info (organization_id);
create index if not exists idx_device_info_user   on device_info (user_id);

alter table device_info enable row level security;

-- Users can read and write only their own device records
create policy "device_info_select"
  on device_info for select
  using (user_id = auth.uid() and organization_id = auth.organization_id());

create policy "device_info_insert"
  on device_info for insert
  with check (user_id = auth.uid() and organization_id = auth.organization_id());

create policy "device_info_update"
  on device_info for update
  using (user_id = auth.uid() and organization_id = auth.organization_id())
  with check (user_id = auth.uid() and organization_id = auth.organization_id());

-- -------------------------------------------------------------------------
-- SYNC LOG
-- -------------------------------------------------------------------------
-- One row per sync session.
-- Used for diagnostics, reporting, and debugging.
create table if not exists sync_log (
  id                  uuid primary key default gen_random_uuid(),
  organization_id     uuid not null references organizations(id),
  device_id           text not null,
  user_id             uuid not null references auth.users(id),

  started_at          timestamptz not null default now(),
  finished_at         timestamptz,

  uploaded_records    int not null default 0,
  downloaded_records  int not null default 0,
  failed_records      int not null default 0,
  duration_ms         int,

  -- 'success' | 'partial' | 'failed' | 'running'
  status              text not null default 'running',
  error_message       text
);

create index if not exists idx_sync_log_org     on sync_log (organization_id);
create index if not exists idx_sync_log_device  on sync_log (device_id);
create index if not exists idx_sync_log_started on sync_log (organization_id, started_at desc);

alter table sync_log enable row level security;

create policy "sync_log_select"
  on sync_log for select
  using (organization_id = auth.organization_id());

create policy "sync_log_insert"
  on sync_log for insert
  with check (
    organization_id = auth.organization_id()
    and user_id = auth.uid()
  );

create policy "sync_log_update"
  on sync_log for update
  using (user_id = auth.uid() and organization_id = auth.organization_id())
  with check (user_id = auth.uid() and organization_id = auth.organization_id());
