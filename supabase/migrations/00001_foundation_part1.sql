-- Ochanya Gili Foundation Migration — Part 1: Core Tables
-- Run in Supabase SQL Editor

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Auto-update updated_at helper
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

-- PROFILES (FK → auth.users)
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  full_name TEXT NOT NULL DEFAULT '',
  phone TEXT,
  avatar_url TEXT,
  role TEXT NOT NULL DEFAULT 'customer' 
    CHECK (role IN ('customer','designer','production_staff','front_desk','content_manager','admin')),
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TRIGGER profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, role)
  VALUES (NEW.id, NEW.email, COALESCE(NEW.raw_user_meta_data->>'full_name',''), COALESCE(NEW.raw_user_meta_data->>'role','customer'));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);
CREATE POLICY "Admins can view all profiles" ON public.profiles FOR SELECT USING (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role IN ('admin','designer','front_desk')));

-- CATEGORIES
CREATE TABLE public.categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(), name TEXT NOT NULL, slug TEXT NOT NULL UNIQUE,
  description TEXT, image_url TEXT, parent_id UUID REFERENCES public.categories(id),
  sort_order INT NOT NULL DEFAULT 0, is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TRIGGER categories_updated_at BEFORE UPDATE ON public.categories FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Categories publicly readable" ON public.categories FOR SELECT USING (true);
CREATE POLICY "Admins manage categories" ON public.categories FOR ALL USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin','designer','content_manager')));

-- COLLECTIONS
CREATE TABLE public.collections (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(), name TEXT NOT NULL, slug TEXT NOT NULL UNIQUE,
  description TEXT, cover_image_url TEXT, hero_image_url TEXT, season TEXT, year INT,
  is_featured BOOLEAN NOT NULL DEFAULT false, is_published BOOLEAN NOT NULL DEFAULT false,
  is_archived BOOLEAN NOT NULL DEFAULT false, sort_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TRIGGER collections_updated_at BEFORE UPDATE ON public.collections FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
ALTER TABLE public.collections ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Published collections readable" ON public.collections FOR SELECT USING (is_published = true OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin','designer','content_manager')));
CREATE POLICY "Admins manage collections" ON public.collections FOR ALL USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin','designer','content_manager')));

-- PRODUCTS
CREATE TABLE public.products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(), name TEXT NOT NULL, slug TEXT NOT NULL UNIQUE,
  description TEXT, short_description TEXT,
  product_type TEXT NOT NULL DEFAULT 'ready_to_wear' CHECK (product_type IN ('ready_to_wear','made_to_order','custom','accessory')),
  category_id UUID REFERENCES public.categories(id),
  base_price DECIMAL(12,2) NOT NULL CHECK (base_price >= 0),
  compare_at_price DECIMAL(12,2) CHECK (compare_at_price IS NULL OR compare_at_price >= 0),
  materials TEXT, care_instructions TEXT, size_guide TEXT, production_time_days INT, delivery_estimate TEXT,
  is_featured BOOLEAN NOT NULL DEFAULT false, is_published BOOLEAN NOT NULL DEFAULT false,
  is_archived BOOLEAN NOT NULL DEFAULT false, sort_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TRIGGER products_updated_at BEFORE UPDATE ON public.products FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Published products readable" ON public.products FOR SELECT USING (is_published = true OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin','designer','content_manager')));
CREATE POLICY "Admins manage products" ON public.products FOR ALL USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin','designer','content_manager')));

-- PRODUCT VARIANTS
CREATE TABLE public.product_variants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(), product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  size TEXT, colour TEXT, sku TEXT UNIQUE,
  price_override DECIMAL(12,2) CHECK (price_override IS NULL OR price_override >= 0),
  stock_quantity INT NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0), is_available BOOLEAN NOT NULL DEFAULT true,
  sort_order INT NOT NULL DEFAULT 0, created_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TRIGGER product_variants_updated_at BEFORE UPDATE ON public.product_variants FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
ALTER TABLE public.product_variants ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Variants follow product visibility" ON public.product_variants FOR SELECT USING (EXISTS (SELECT 1 FROM public.products p WHERE p.id = product_id AND (p.is_published = true OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin','designer','content_manager')))));
CREATE POLICY "Admins manage variants" ON public.product_variants FOR ALL USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin','designer','content_manager')));

-- PRODUCT IMAGES
CREATE TABLE public.product_images (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(), product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL, alt_text TEXT, is_primary BOOLEAN NOT NULL DEFAULT false,
  sort_order INT NOT NULL DEFAULT 0, created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.product_images ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Product images follow product" ON public.product_images FOR SELECT USING (EXISTS (SELECT 1 FROM public.products p WHERE p.id = product_id AND (p.is_published = true OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin','designer','content_manager')))));
CREATE POLICY "Admins manage product images" ON public.product_images FOR ALL USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin','designer','content_manager')));

-- COLLECTION_PRODUCTS junction
CREATE TABLE public.collection_products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  collection_id UUID NOT NULL REFERENCES public.collections(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  sort_order INT NOT NULL DEFAULT 0, UNIQUE(collection_id, product_id)
);
ALTER TABLE public.collection_products ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Collection products readable" ON public.collection_products FOR SELECT USING (true);
CREATE POLICY "Admins manage collection products" ON public.collection_products FOR ALL USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin','designer','content_manager')));
