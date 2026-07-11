-- =============================================================================
-- Migration 006: Storage Buckets
-- =============================================================================
-- Prepare storage buckets for future use.
-- Buckets are created but not yet integrated into the Android application.
-- =============================================================================

-- product-images: photos of products for the dashboard
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'product-images',
  'product-images',
  false,             -- private: require auth
  5242880,           -- 5 MB max per image
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do nothing;

-- receipts: printed receipt images for future use
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'receipts',
  'receipts',
  false,             -- private: require auth
  10485760,          -- 10 MB max
  array['image/jpeg', 'image/png', 'application/pdf']
)
on conflict (id) do nothing;

-- -------------------------------------------------------------------------
-- Storage RLS policies
-- -------------------------------------------------------------------------

-- product-images: organization members can read/write
create policy "product_images_select"
  on storage.objects for select
  using (
    bucket_id = 'product-images'
    and (storage.foldername(name))[1] = auth.organization_id()::text
  );

create policy "product_images_insert"
  on storage.objects for insert
  with check (
    bucket_id = 'product-images'
    and (storage.foldername(name))[1] = auth.organization_id()::text
  );

create policy "product_images_delete"
  on storage.objects for delete
  using (
    bucket_id = 'product-images'
    and (storage.foldername(name))[1] = auth.organization_id()::text
    and auth.user_role() = 'administrator'
  );

-- receipts: organization members can read/write their own receipts
create policy "receipts_select"
  on storage.objects for select
  using (
    bucket_id = 'receipts'
    and (storage.foldername(name))[1] = auth.organization_id()::text
  );

create policy "receipts_insert"
  on storage.objects for insert
  with check (
    bucket_id = 'receipts'
    and (storage.foldername(name))[1] = auth.organization_id()::text
  );
