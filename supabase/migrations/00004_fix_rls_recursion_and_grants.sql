-- Migration 00004: Fix RLS Infinite Recursion on Profiles and Grant Public Table Access
-- Date: 2026-09-29

-- 1. Helper function to safely get user role without RLS recursion
CREATE OR REPLACE FUNCTION public.get_user_role()
RETURNS TEXT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid();
$$;

-- 2. Helper function to check if current user has admin/staff access
CREATE OR REPLACE FUNCTION public.is_admin_or_staff()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = auth.uid() AND role IN ('admin', 'designer', 'content_manager', 'front_desk', 'production_staff')
  );
$$;

-- 3. Fix profiles RLS to prevent recursion
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;

CREATE POLICY "Users can view own profile or admins view all" ON public.profiles FOR SELECT
  USING (auth.uid() = id OR public.get_user_role() IN ('admin','designer','front_desk'));

-- 4. Fix products RLS to use get_user_role
DROP POLICY IF EXISTS "Published products readable" ON public.products;
DROP POLICY IF EXISTS "Admins manage products" ON public.products;

CREATE POLICY "Published products readable" ON public.products FOR SELECT
  USING (is_published = true OR public.get_user_role() IN ('admin','designer','content_manager'));

CREATE POLICY "Admins manage products" ON public.products FOR ALL
  USING (public.get_user_role() IN ('admin','designer','content_manager'));

-- 5. Fix product_variants RLS
DROP POLICY IF EXISTS "Variants follow product visibility" ON public.product_variants;
DROP POLICY IF EXISTS "Admins manage variants" ON public.product_variants;

CREATE POLICY "Variants follow product visibility" ON public.product_variants FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.products p 
      WHERE p.id = product_variants.product_id 
        AND (p.is_published = true OR public.get_user_role() IN ('admin','designer','content_manager'))
    )
  );

CREATE POLICY "Admins manage variants" ON public.product_variants FOR ALL
  USING (public.get_user_role() IN ('admin','designer','content_manager'));

-- 6. Fix product_images RLS
DROP POLICY IF EXISTS "Product images follow product" ON public.product_images;
DROP POLICY IF EXISTS "Admins manage product images" ON public.product_images;

CREATE POLICY "Product images follow product" ON public.product_images FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.products p 
      WHERE p.id = product_images.product_id 
        AND (p.is_published = true OR public.get_user_role() IN ('admin','designer','content_manager'))
    )
  );

CREATE POLICY "Admins manage product images" ON public.product_images FOR ALL
  USING (public.get_user_role() IN ('admin','designer','content_manager'));

-- 7. Fix collections RLS
DROP POLICY IF EXISTS "Published collections readable" ON public.collections;
DROP POLICY IF EXISTS "Admins manage collections" ON public.collections;

CREATE POLICY "Published collections readable" ON public.collections FOR SELECT
  USING (is_published = true OR public.get_user_role() IN ('admin','designer','content_manager'));

CREATE POLICY "Admins manage collections" ON public.collections FOR ALL
  USING (public.get_user_role() IN ('admin','designer','content_manager'));

-- 8. Fix lookbook RLS
DROP POLICY IF EXISTS "Published lookbooks readable" ON public.lookbook;
DROP POLICY IF EXISTS "Admins manage lookbooks" ON public.lookbook;

CREATE POLICY "Published lookbook readable" ON public.lookbook FOR SELECT
  USING (is_published = true OR public.get_user_role() IN ('admin','designer','content_manager'));

CREATE POLICY "Admins manage lookbook" ON public.lookbook FOR ALL
  USING (public.get_user_role() IN ('admin','designer','content_manager'));

-- 9. Permissions grants
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL ROUTINES IN SCHEMA public TO anon, authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO anon, authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO anon, authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON ROUTINES TO anon, authenticated;
