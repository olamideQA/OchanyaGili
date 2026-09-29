-- Ochanya Gili Foundation Migration — Part 3: Quotes, Appointments, CMS, Inventory, Analytics & Audit

-- 1. QUOTES
CREATE TABLE public.quotes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  custom_request_id UUID NOT NULL REFERENCES public.custom_requests(id) ON DELETE CASCADE,
  version INT NOT NULL DEFAULT 1,
  subtotal DECIMAL(12,2) NOT NULL CHECK (subtotal >= 0),
  total DECIMAL(12,2) NOT NULL CHECK (total >= 0),
  deposit_percentage DECIMAL(5,2) NOT NULL DEFAULT 50.00 CHECK (deposit_percentage >= 0 AND deposit_percentage <= 100),
  deposit_amount DECIMAL(12,2) NOT NULL CHECK (deposit_amount >= 0),
  balance_amount DECIMAL(12,2) NOT NULL CHECK (balance_amount >= 0),
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'sent', 'accepted', 'rejected', 'revised', 'expired')),
  valid_until TIMESTAMPTZ,
  notes TEXT,
  created_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TRIGGER quotes_updated_at BEFORE UPDATE ON public.quotes FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

ALTER TABLE public.quotes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view quotes for own requests" ON public.quotes FOR SELECT
  USING (EXISTS (SELECT 1 FROM public.custom_requests cr WHERE cr.id = custom_request_id AND cr.profile_id = auth.uid()));
CREATE POLICY "Admins can manage quotes" ON public.quotes FOR ALL
  USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'designer')));

-- 2. QUOTE ITEMS
CREATE TABLE public.quote_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  quote_id UUID NOT NULL REFERENCES public.quotes(id) ON DELETE CASCADE,
  description TEXT NOT NULL,
  quantity INT NOT NULL DEFAULT 1 CHECK (quantity > 0),
  unit_price DECIMAL(12,2) NOT NULL CHECK (unit_price >= 0),
  total_price DECIMAL(12,2) NOT NULL CHECK (total_price >= 0),
  sort_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.quote_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Quote items follow quote visibility" ON public.quote_items FOR SELECT
  USING (EXISTS (SELECT 1 FROM public.quotes q JOIN public.custom_requests cr ON cr.id = q.custom_request_id WHERE q.id = quote_id AND (cr.profile_id = auth.uid() OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'designer')))));
CREATE POLICY "Admins can manage quote items" ON public.quote_items FOR ALL
  USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'designer')));

-- 3. APPOINTMENT TYPES
CREATE TABLE public.appointment_types (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  description TEXT,
  duration_minutes INT NOT NULL DEFAULT 60,
  buffer_minutes INT NOT NULL DEFAULT 15,
  booking_fee DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (booking_fee >= 0),
  is_active BOOLEAN NOT NULL DEFAULT true,
  sort_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.appointment_types ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Appointment types are publicly readable" ON public.appointment_types FOR SELECT USING (is_active = true);
CREATE POLICY "Admins can manage appointment types" ON public.appointment_types FOR ALL
  USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'designer', 'front_desk')));

-- 4. APPOINTMENTS
CREATE TABLE public.appointments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id UUID NOT NULL REFERENCES public.profiles(id),
  appointment_type_id UUID NOT NULL REFERENCES public.appointment_types(id),
  scheduled_date DATE NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'completed', 'cancelled', 'no_show')),
  booking_fee_paid BOOLEAN NOT NULL DEFAULT false,
  payment_id UUID REFERENCES public.payments(id),
  notes TEXT,
  designer_notes TEXT,
  custom_request_id UUID REFERENCES public.custom_requests(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(scheduled_date, start_time)
);
CREATE TRIGGER appointments_updated_at BEFORE UPDATE ON public.appointments FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own appointments" ON public.appointments FOR SELECT USING (profile_id = auth.uid());
CREATE POLICY "Users can create appointments" ON public.appointments FOR INSERT WITH CHECK (profile_id = auth.uid());
CREATE POLICY "Admins can manage appointments" ON public.appointments FOR ALL
  USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'designer', 'front_desk')));

-- 5. WISHLIST
CREATE TABLE public.wishlist (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(profile_id, product_id)
);
ALTER TABLE public.wishlist ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own wishlist" ON public.wishlist FOR ALL USING (profile_id = auth.uid());

-- 6. NOTIFICATIONS
CREATE TABLE public.notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  type TEXT NOT NULL DEFAULT 'general' CHECK (type IN ('general', 'order', 'custom_request', 'appointment', 'payment', 'promotion')),
  reference_type TEXT,
  reference_id UUID,
  is_read BOOLEAN NOT NULL DEFAULT false,
  channel TEXT NOT NULL DEFAULT 'in_app' CHECK (channel IN ('in_app', 'email', 'push')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own notifications" ON public.notifications FOR SELECT USING (profile_id = auth.uid());
CREATE POLICY "Users can update own notifications" ON public.notifications FOR UPDATE USING (profile_id = auth.uid());

-- 7. JOURNAL POSTS
CREATE TABLE public.journal_posts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  excerpt TEXT,
  content TEXT,
  cover_image_url TEXT,
  author_id UUID REFERENCES public.profiles(id),
  is_published BOOLEAN NOT NULL DEFAULT false,
  published_at TIMESTAMPTZ,
  tags TEXT[],
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TRIGGER journal_posts_updated_at BEFORE UPDATE ON public.journal_posts FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
ALTER TABLE public.journal_posts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Published journal posts are publicly readable" ON public.journal_posts FOR SELECT
  USING (is_published = true OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'designer', 'content_manager')));
CREATE POLICY "Admins can manage journal posts" ON public.journal_posts FOR ALL
  USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'designer', 'content_manager')));

-- 8. LOOKBOOK & LOOKBOOK ITEMS
CREATE TABLE public.lookbook (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  description TEXT,
  cover_image_url TEXT,
  full_image_url TEXT,
  designer_notes TEXT,
  collection_id UUID REFERENCES public.collections(id),
  model_name TEXT,
  photographer TEXT,
  is_published BOOLEAN NOT NULL DEFAULT false,
  sort_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TRIGGER lookbook_updated_at BEFORE UPDATE ON public.lookbook FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
ALTER TABLE public.lookbook ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Published lookbook entries are publicly readable" ON public.lookbook FOR SELECT
  USING (is_published = true OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'designer', 'content_manager')));
CREATE POLICY "Admins can manage lookbook" ON public.lookbook FOR ALL
  USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'designer', 'content_manager')));

CREATE TABLE public.lookbook_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  lookbook_id UUID NOT NULL REFERENCES public.lookbook(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  sort_order INT NOT NULL DEFAULT 0,
  UNIQUE(lookbook_id, product_id)
);
ALTER TABLE public.lookbook_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Lookbook items publicly readable" ON public.lookbook_items FOR SELECT USING (true);
CREATE POLICY "Admins can manage lookbook items" ON public.lookbook_items FOR ALL
  USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'designer', 'content_manager')));

-- 9. INVENTORY & TRANSACTIONS
CREATE TABLE public.inventory (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  sku TEXT UNIQUE,
  description TEXT,
  quantity DECIMAL(12,2) NOT NULL DEFAULT 0,
  unit TEXT NOT NULL DEFAULT 'pieces',
  cost_per_unit DECIMAL(12,2) CHECK (cost_per_unit IS NULL OR cost_per_unit >= 0),
  supplier TEXT,
  reorder_threshold DECIMAL(12,2) NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TRIGGER inventory_updated_at BEFORE UPDATE ON public.inventory FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
ALTER TABLE public.inventory ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admins can manage inventory" ON public.inventory FOR ALL
  USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'designer', 'production_staff')));

CREATE TABLE public.inventory_transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  inventory_id UUID NOT NULL REFERENCES public.inventory(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('in', 'out', 'adjustment')),
  quantity DECIMAL(12,2) NOT NULL,
  reference_type TEXT,
  reference_id UUID,
  notes TEXT,
  performed_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.inventory_transactions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admins can manage inventory transactions" ON public.inventory_transactions FOR ALL
  USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'designer', 'production_staff')));

-- 10. DISCOUNTS
CREATE TABLE public.discounts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  code TEXT NOT NULL UNIQUE,
  description TEXT,
  type TEXT NOT NULL CHECK (type IN ('percentage', 'fixed')),
  value DECIMAL(12,2) NOT NULL CHECK (value >= 0),
  min_order_amount DECIMAL(12,2) CHECK (min_order_amount IS NULL OR min_order_amount >= 0),
  max_uses INT,
  used_count INT NOT NULL DEFAULT 0,
  starts_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TRIGGER discounts_updated_at BEFORE UPDATE ON public.discounts FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
ALTER TABLE public.discounts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Active discounts are publicly readable" ON public.discounts FOR SELECT
  USING (is_active = true AND (expires_at IS NULL OR expires_at > now()));
CREATE POLICY "Admins can manage discounts" ON public.discounts FOR ALL
  USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'designer')));

-- 11. SETTINGS & CMS CONTENT
CREATE TABLE public.settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  key TEXT NOT NULL UNIQUE,
  value JSONB NOT NULL DEFAULT '{}',
  description TEXT,
  updated_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TRIGGER settings_updated_at BEFORE UPDATE ON public.settings FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
ALTER TABLE public.settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Settings are publicly readable" ON public.settings FOR SELECT USING (true);
CREATE POLICY "Admins can manage settings" ON public.settings FOR ALL
  USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'designer', 'content_manager')));

-- 12. AUDIT LOGS, DESIGNER NOTES & ANALYTICS
CREATE TABLE public.audit_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  actor_id UUID REFERENCES public.profiles(id),
  action TEXT NOT NULL,
  entity TEXT NOT NULL,
  entity_id UUID,
  metadata JSONB,
  ip_address TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admins can view audit logs" ON public.audit_logs FOR SELECT
  USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));
CREATE POLICY "System can insert audit logs" ON public.audit_logs FOR INSERT WITH CHECK (true);

CREATE TABLE public.designer_notes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  entity_type TEXT NOT NULL CHECK (entity_type IN ('customer', 'order', 'custom_request', 'appointment')),
  entity_id UUID NOT NULL,
  content TEXT NOT NULL,
  created_by UUID NOT NULL REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TRIGGER designer_notes_updated_at BEFORE UPDATE ON public.designer_notes FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
ALTER TABLE public.designer_notes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Only admin and designer can access designer notes" ON public.designer_notes FOR ALL
  USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'designer')));

CREATE TABLE public.analytics_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_name TEXT NOT NULL,
  profile_id UUID REFERENCES public.profiles(id),
  session_id TEXT,
  properties JSONB,
  page_url TEXT,
  referrer TEXT,
  device_type TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.analytics_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can log analytics events" ON public.analytics_events FOR INSERT WITH CHECK (true);
CREATE POLICY "Admins can view analytics" ON public.analytics_events FOR SELECT
  USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'designer')));
