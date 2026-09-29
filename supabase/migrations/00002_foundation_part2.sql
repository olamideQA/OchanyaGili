-- Ochanya Gili Foundation Migration — Part 2: Addresses, Measurements, Orders, Payments, Custom Requests

-- 1. ADDRESSES (needed before orders)
CREATE TABLE IF NOT EXISTS public.addresses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  label TEXT NOT NULL DEFAULT 'Home',
  full_name TEXT NOT NULL,
  phone TEXT,
  address_line1 TEXT NOT NULL,
  address_line2 TEXT,
  city TEXT NOT NULL,
  state TEXT NOT NULL,
  country TEXT NOT NULL DEFAULT 'Nigeria',
  postal_code TEXT,
  instructions TEXT,
  is_default BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TRIGGER addresses_updated_at BEFORE UPDATE ON public.addresses FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
ALTER TABLE public.addresses ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own addresses" ON public.addresses FOR ALL USING (profile_id = auth.uid());
CREATE POLICY "Admins view addresses" ON public.addresses FOR SELECT USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin','designer')));

-- 2. MEASUREMENT PROFILES (needed before order_items and custom_requests)
CREATE TABLE IF NOT EXISTS public.measurement_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL DEFAULT 'My Measurements',
  shoulder DECIMAL(8,2),
  bust DECIMAL(8,2),
  under_bust DECIMAL(8,2),
  waist DECIMAL(8,2),
  hip DECIMAL(8,2),
  armhole DECIMAL(8,2),
  sleeve_length DECIMAL(8,2),
  bicep DECIMAL(8,2),
  wrist DECIMAL(8,2),
  back_length DECIMAL(8,2),
  front_length DECIMAL(8,2),
  dress_length DECIMAL(8,2),
  trouser_waist DECIMAL(8,2),
  trouser_hip DECIMAL(8,2),
  trouser_length DECIMAL(8,2),
  inseam DECIMAL(8,2),
  thigh DECIMAL(8,2),
  neck DECIMAL(8,2),
  unit TEXT NOT NULL DEFAULT 'inches' CHECK (unit IN ('inches','cm')),
  is_default BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TRIGGER measurement_profiles_updated_at BEFORE UPDATE ON public.measurement_profiles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
ALTER TABLE public.measurement_profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own measurements" ON public.measurement_profiles FOR ALL USING (profile_id = auth.uid());
CREATE POLICY "Admins view measurements" ON public.measurement_profiles FOR SELECT USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin','designer')));

-- 3. ORDERS
CREATE TABLE IF NOT EXISTS public.orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_number TEXT NOT NULL UNIQUE,
  profile_id UUID NOT NULL REFERENCES public.profiles(id),
  address_id UUID REFERENCES public.addresses(id),
  status TEXT NOT NULL DEFAULT 'pending_payment' CHECK (status IN ('pending_payment','paid','confirmed','processing','in_production','ready_for_fitting','ready_for_delivery','shipped','delivered','cancelled','refunded')),
  subtotal DECIMAL(12,2) NOT NULL CHECK (subtotal >= 0),
  delivery_fee DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (delivery_fee >= 0),
  discount_amount DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (discount_amount >= 0),
  total DECIMAL(12,2) NOT NULL CHECK (total >= 0),
  payment_status TEXT NOT NULL DEFAULT 'pending' CHECK (payment_status IN ('pending','processing','successful','failed','refunded','partially_refunded')),
  payment_reference TEXT,
  payment_provider TEXT,
  notes TEXT,
  customer_notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TRIGGER orders_updated_at BEFORE UPDATE ON public.orders FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE OR REPLACE FUNCTION public.generate_order_number() RETURNS TRIGGER AS $$
BEGIN
  NEW.order_number = 'OG-' || TO_CHAR(now(),'YYYYMMDD') || '-' || LPAD(FLOOR(RANDOM()*10000)::TEXT,4,'0');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER orders_generate_number BEFORE INSERT ON public.orders FOR EACH ROW WHEN (NEW.order_number IS NULL OR NEW.order_number = '') EXECUTE FUNCTION public.generate_order_number();

ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users view own orders" ON public.orders FOR SELECT USING (profile_id = auth.uid());
CREATE POLICY "Users create orders" ON public.orders FOR INSERT WITH CHECK (profile_id = auth.uid());
CREATE POLICY "Admins view all orders" ON public.orders FOR SELECT USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin','designer','production_staff')));
CREATE POLICY "Admins update orders" ON public.orders FOR UPDATE USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin','designer','production_staff')));

-- 4. ORDER ITEMS
CREATE TABLE IF NOT EXISTS public.order_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES public.products(id),
  variant_id UUID REFERENCES public.product_variants(id),
  product_name TEXT NOT NULL,
  variant_label TEXT,
  quantity INT NOT NULL DEFAULT 1 CHECK (quantity > 0),
  unit_price DECIMAL(12,2) NOT NULL CHECK (unit_price >= 0),
  total_price DECIMAL(12,2) NOT NULL CHECK (total_price >= 0),
  measurement_profile_id UUID REFERENCES public.measurement_profiles(id),
  custom_options JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Order items follow order" ON public.order_items FOR SELECT USING (EXISTS (SELECT 1 FROM public.orders o WHERE o.id = order_id AND (o.profile_id = auth.uid() OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin','designer','production_staff')))));
CREATE POLICY "Users create order items" ON public.order_items FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM public.orders o WHERE o.id = order_id AND o.profile_id = auth.uid()));

-- 5. ORDER STATUS HISTORY (append-only)
CREATE TABLE IF NOT EXISTS public.order_status_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  from_status TEXT,
  to_status TEXT NOT NULL,
  changed_by UUID REFERENCES public.profiles(id),
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE OR REPLACE FUNCTION public.log_order_status_change() RETURNS TRIGGER AS $$
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    INSERT INTO public.order_status_history (order_id, from_status, to_status, changed_by)
    VALUES (NEW.id, OLD.status, NEW.status, auth.uid());
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
CREATE TRIGGER orders_status_change AFTER UPDATE ON public.orders FOR EACH ROW EXECUTE FUNCTION public.log_order_status_change();
ALTER TABLE public.order_status_history ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Order history follows order" ON public.order_status_history FOR SELECT USING (EXISTS (SELECT 1 FROM public.orders o WHERE o.id = order_id AND (o.profile_id = auth.uid() OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin','designer','production_staff')))));
CREATE POLICY "System insert status history" ON public.order_status_history FOR INSERT WITH CHECK (true);

-- 6. PAYMENTS
CREATE TABLE IF NOT EXISTS public.payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id UUID REFERENCES public.orders(id),
  profile_id UUID NOT NULL REFERENCES public.profiles(id),
  amount DECIMAL(12,2) NOT NULL CHECK (amount > 0),
  currency TEXT NOT NULL DEFAULT 'NGN',
  provider TEXT NOT NULL DEFAULT 'paystack',
  provider_reference TEXT,
  provider_status TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','processing','successful','failed','refunded','partially_refunded')),
  payment_type TEXT NOT NULL DEFAULT 'order' CHECK (payment_type IN ('order','deposit','balance','booking_fee')),
  metadata JSONB,
  verified_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TRIGGER payments_updated_at BEFORE UPDATE ON public.payments FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users view own payments" ON public.payments FOR SELECT USING (profile_id = auth.uid());
CREATE POLICY "Admins view all payments" ON public.payments FOR SELECT USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin','designer')));

-- 7. CUSTOM REQUESTS
CREATE TABLE IF NOT EXISTS public.custom_requests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  request_number TEXT NOT NULL UNIQUE,
  profile_id UUID NOT NULL REFERENCES public.profiles(id),
  occasion TEXT,
  direction TEXT,
  inspiration_text TEXT,
  inspiration_links TEXT[],
  fabric TEXT,
  colour TEXT,
  measurement_profile_id UUID REFERENCES public.measurement_profiles(id),
  special_instructions TEXT,
  status TEXT NOT NULL DEFAULT 'requested' CHECK (status IN ('requested','under_review','design_discussion','quote_sent','customer_approved','payment','production','fitting','alteration','ready','delivered')),
  assigned_to UUID REFERENCES public.profiles(id),
  designer_notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE OR REPLACE FUNCTION public.generate_request_number() RETURNS TRIGGER AS $$
BEGIN
  NEW.request_number = 'CR-' || TO_CHAR(now(),'YYYYMMDD') || '-' || LPAD(FLOOR(RANDOM()*10000)::TEXT,4,'0');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER custom_requests_generate_number BEFORE INSERT ON public.custom_requests FOR EACH ROW WHEN (NEW.request_number IS NULL OR NEW.request_number = '') EXECUTE FUNCTION public.generate_request_number();
CREATE TRIGGER custom_requests_updated_at BEFORE UPDATE ON public.custom_requests FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
ALTER TABLE public.custom_requests ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users view own requests" ON public.custom_requests FOR SELECT USING (profile_id = auth.uid());
CREATE POLICY "Users create requests" ON public.custom_requests FOR INSERT WITH CHECK (profile_id = auth.uid());
CREATE POLICY "Admins manage requests" ON public.custom_requests FOR ALL USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin','designer')));

-- 8. CUSTOM REQUEST IMAGES
CREATE TABLE IF NOT EXISTS public.custom_request_images (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  custom_request_id UUID NOT NULL REFERENCES public.custom_requests(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  alt_text TEXT,
  sort_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.custom_request_images ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Request images follow request" ON public.custom_request_images FOR SELECT USING (EXISTS (SELECT 1 FROM public.custom_requests cr WHERE cr.id = custom_request_id AND (cr.profile_id = auth.uid() OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin','designer')))));
CREATE POLICY "Users add images to own requests" ON public.custom_request_images FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM public.custom_requests cr WHERE cr.id = custom_request_id AND cr.profile_id = auth.uid()));

-- 9. CUSTOM REQUEST STATUS HISTORY (append-only)
CREATE TABLE IF NOT EXISTS public.custom_request_status_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  custom_request_id UUID NOT NULL REFERENCES public.custom_requests(id) ON DELETE CASCADE,
  from_status TEXT,
  to_status TEXT NOT NULL,
  changed_by UUID REFERENCES public.profiles(id),
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE OR REPLACE FUNCTION public.log_custom_request_status_change() RETURNS TRIGGER AS $$
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    INSERT INTO public.custom_request_status_history (custom_request_id, from_status, to_status, changed_by)
    VALUES (NEW.id, OLD.status, NEW.status, auth.uid());
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
CREATE TRIGGER custom_requests_status_change AFTER UPDATE ON public.custom_requests FOR EACH ROW EXECUTE FUNCTION public.log_custom_request_status_change();
ALTER TABLE public.custom_request_status_history ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Status history follows request" ON public.custom_request_status_history FOR SELECT USING (EXISTS (SELECT 1 FROM public.custom_requests cr WHERE cr.id = custom_request_id AND (cr.profile_id = auth.uid() OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin','designer')))));
CREATE POLICY "System insert request history" ON public.custom_request_status_history FOR INSERT WITH CHECK (true);
