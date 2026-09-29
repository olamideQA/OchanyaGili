-- Migration 00016: Customization Studio & Dynamic Storefront (Header, Footer, Menus, Theme, Pages)

-- 1. Create custom_pages table
CREATE TABLE IF NOT EXISTS public.custom_pages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    content TEXT NOT NULL,
    meta_description TEXT,
    is_published BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Indices
CREATE INDEX IF NOT EXISTS idx_custom_pages_slug ON public.custom_pages(slug);
CREATE INDEX IF NOT EXISTS idx_custom_pages_published ON public.custom_pages(is_published);

-- RLS
ALTER TABLE public.custom_pages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can view published custom pages"
ON public.custom_pages
FOR SELECT
TO anon, authenticated
USING (is_published = true);

CREATE POLICY "Staff can manage all custom pages"
ON public.custom_pages
FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid()
        AND role IN ('admin', 'designer', 'content_manager')
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid()
        AND role IN ('admin', 'designer', 'content_manager')
    )
);

GRANT ALL ON public.custom_pages TO authenticated;
GRANT SELECT ON public.custom_pages TO anon;
GRANT ALL ON public.custom_pages TO service_role;
