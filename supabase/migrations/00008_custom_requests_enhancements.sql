-- Migration 00008: Custom Requests Storage & RLS Enhancements
-- Date: 2026-09-29

-- 1. Ensure storage bucket for custom requests is public and readable
UPDATE storage.buckets 
SET public = true 
WHERE id = 'custom_requests';

-- 2. Storage upload policies for custom_requests bucket
DROP POLICY IF EXISTS "Public Access to custom_requests" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users upload custom_requests" ON storage.objects;
DROP POLICY IF EXISTS "Admins manage custom_requests storage" ON storage.objects;

CREATE POLICY "Public Access to custom_requests" ON storage.objects
  FOR SELECT
  USING (bucket_id = 'custom_requests');

CREATE POLICY "Authenticated users upload custom_requests" ON storage.objects
  FOR INSERT
  WITH CHECK (bucket_id = 'custom_requests');

CREATE POLICY "Admins manage custom_requests storage" ON storage.objects
  FOR ALL
  USING (bucket_id = 'custom_requests');

-- 3. Fix RLS on public.custom_requests
DROP POLICY IF EXISTS "Users view own requests" ON public.custom_requests;
DROP POLICY IF EXISTS "Users create requests" ON public.custom_requests;
DROP POLICY IF EXISTS "Admins manage requests" ON public.custom_requests;

CREATE POLICY "Users view own requests" ON public.custom_requests
  FOR SELECT
  USING (
    profile_id = auth.uid() 
    OR public.get_user_role() IN ('admin', 'designer', 'production_staff')
  );

CREATE POLICY "Users create requests" ON public.custom_requests
  FOR INSERT
  WITH CHECK (profile_id = auth.uid());

CREATE POLICY "Admins manage requests" ON public.custom_requests
  FOR ALL
  USING (public.get_user_role() IN ('admin', 'designer', 'production_staff'));

-- 4. Fix RLS on public.custom_request_images
DROP POLICY IF EXISTS "Request images follow request" ON public.custom_request_images;
DROP POLICY IF EXISTS "Users add images to own requests" ON public.custom_request_images;
DROP POLICY IF EXISTS "Admins manage request images" ON public.custom_request_images;

CREATE POLICY "Request images readable" ON public.custom_request_images
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.custom_requests cr 
      WHERE cr.id = custom_request_id 
        AND (cr.profile_id = auth.uid() OR public.get_user_role() IN ('admin', 'designer', 'production_staff'))
    )
  );

CREATE POLICY "Users add images to own requests" ON public.custom_request_images
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.custom_requests cr 
      WHERE cr.id = custom_request_id AND cr.profile_id = auth.uid()
    )
  );

CREATE POLICY "Admins manage request images" ON public.custom_request_images
  FOR ALL
  USING (public.get_user_role() IN ('admin', 'designer', 'production_staff'));

-- 5. Fix RLS on public.custom_request_status_history
DROP POLICY IF EXISTS "Status history follows request" ON public.custom_request_status_history;
DROP POLICY IF EXISTS "System insert request history" ON public.custom_request_status_history;

CREATE POLICY "Status history readable" ON public.custom_request_status_history
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.custom_requests cr 
      WHERE cr.id = custom_request_id 
        AND (cr.profile_id = auth.uid() OR public.get_user_role() IN ('admin', 'designer', 'production_staff'))
    )
  );

CREATE POLICY "System insert request history" ON public.custom_request_status_history
  FOR INSERT
  WITH CHECK (true);

-- 6. Permissions grants
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON public.custom_requests TO anon, authenticated;
GRANT ALL ON public.custom_request_images TO anon, authenticated;
GRANT ALL ON public.custom_request_status_history TO anon, authenticated;
