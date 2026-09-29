-- Migration 00014: Storage Bucket Policies for Staff Media Management

DROP POLICY IF EXISTS "Staff can upload to products" ON storage.objects;
CREATE POLICY "Staff can upload to products"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id IN ('products', 'collections', 'lookbook', 'journal'));

DROP POLICY IF EXISTS "Staff can update products storage" ON storage.objects;
CREATE POLICY "Staff can update products storage"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id IN ('products', 'collections', 'lookbook', 'journal'));

DROP POLICY IF EXISTS "Staff can delete from products storage" ON storage.objects;
CREATE POLICY "Staff can delete from products storage"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id IN ('products', 'collections', 'lookbook', 'journal'));
