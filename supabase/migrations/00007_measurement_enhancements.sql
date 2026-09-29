-- Migration 00007: Measurement Enhancements & Dynamic Garment Requirements
-- Date: 2026-09-29

-- 1. Add required_measurements column to products table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'products' AND column_name = 'required_measurements'
  ) THEN
    ALTER TABLE public.products ADD COLUMN required_measurements JSONB DEFAULT '[]'::jsonb;
  END IF;
END $$;

-- 2. Add notes column to measurement_profiles table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'measurement_profiles' AND column_name = 'notes'
  ) THEN
    ALTER TABLE public.measurement_profiles ADD COLUMN notes TEXT;
  END IF;
END $$;

-- 3. Fix RLS on measurement_profiles to prevent recursion and enable full customer & admin access
DROP POLICY IF EXISTS "Users manage own measurements" ON public.measurement_profiles;
DROP POLICY IF EXISTS "Admins view measurements" ON public.measurement_profiles;
DROP POLICY IF EXISTS "Staff manage measurements" ON public.measurement_profiles;

CREATE POLICY "Users manage own measurements" ON public.measurement_profiles
  FOR ALL
  USING (
    profile_id = auth.uid() 
    OR public.get_user_role() IN ('admin', 'designer', 'production_staff')
  )
  WITH CHECK (
    profile_id = auth.uid() 
    OR public.get_user_role() IN ('admin', 'designer', 'production_staff')
  );

-- 4. Single default profile enforcement trigger
CREATE OR REPLACE FUNCTION public.handle_default_measurement_profile()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.is_default = true THEN
    UPDATE public.measurement_profiles
    SET is_default = false
    WHERE profile_id = NEW.profile_id AND id != NEW.id AND is_default = true;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS tr_default_measurement_profile ON public.measurement_profiles;
CREATE TRIGGER tr_default_measurement_profile
  BEFORE INSERT OR UPDATE OF is_default ON public.measurement_profiles
  FOR EACH ROW
  WHEN (NEW.is_default = true)
  EXECUTE FUNCTION public.handle_default_measurement_profile();

-- 5. Set default required_measurements for existing made_to_order and custom garments
UPDATE public.products
SET required_measurements = '["shoulder", "bust", "under_bust", "waist", "hip", "front_length", "dress_length"]'::jsonb
WHERE slug = 'sovereign-peplum-evening-gown';

UPDATE public.products
SET required_measurements = '["shoulder", "bust", "under_bust", "waist", "hip", "armhole", "sleeve_length", "bicep", "wrist", "back_length", "front_length", "dress_length", "trouser_waist", "trouser_hip", "trouser_length", "inseam", "thigh", "neck"]'::jsonb
WHERE slug = 'bespoke-royal-ceremonial-ensemble';

-- 6. Insert second made_to_order garment (Tailored Crepe Cigarette Trousers) for testing dynamic adaptation
INSERT INTO public.products (
  name, slug, short_description, description, product_type,
  base_price, materials, care_instructions,
  production_time_days, delivery_estimate, is_featured, is_published, sort_order,
  required_measurements
) VALUES (
  'High-Waisted Silk Crepe Cigarette Trousers',
  'high-waisted-silk-crepe-cigarette-trousers',
  'Sharply tailored high-rise trousers with satin waistband and side tuxedo stripe.',
  'Precision-cut bespoke trousers engineered to lengthen the silhouette. Custom-crafted to your unique waist, hip, inseam and thigh measurements.',
  'made_to_order',
  145000.00,
  '100% Wool Crepe with Silk Satin trim.',
  'Specialist dry clean only.',
  10, '10 – 14 Days Atelier Craftsmanship & Delivery',
  true, true, 3,
  '["trouser_waist", "trouser_hip", "trouser_length", "inseam", "thigh"]'::jsonb
) ON CONFLICT (slug) DO UPDATE SET 
  required_measurements = '["trouser_waist", "trouser_hip", "trouser_length", "inseam", "thigh"]'::jsonb,
  is_published = true;

-- 7. Permissions grants
GRANT ALL ON public.measurement_profiles TO anon, authenticated;
GRANT ALL ON public.products TO anon, authenticated;
