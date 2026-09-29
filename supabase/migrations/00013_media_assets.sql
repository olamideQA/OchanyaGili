-- Migration 00013: Media Assets Table and Policies for Studio Media Manager

CREATE TABLE IF NOT EXISTS public.media_assets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bucket TEXT NOT NULL DEFAULT 'products',
    file_path TEXT NOT NULL,
    filename TEXT NOT NULL,
    url TEXT NOT NULL,
    alt_text TEXT DEFAULT '',
    title TEXT DEFAULT '',
    mime_type TEXT DEFAULT 'image/jpeg',
    size_bytes BIGINT DEFAULT 0,
    width INT,
    height INT,
    sort_order INT DEFAULT 0,
    responsive_urls JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_media_assets_bucket_sort ON public.media_assets (bucket, sort_order ASC);

ALTER TABLE public.media_assets ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS media_assets_read_policy ON public.media_assets;
CREATE POLICY media_assets_read_policy
ON public.media_assets FOR SELECT
TO authenticated, anon
USING (true);

DROP POLICY IF EXISTS media_assets_insert_policy ON public.media_assets;
CREATE POLICY media_assets_insert_policy
ON public.media_assets FOR INSERT
TO authenticated
WITH CHECK (true);

DROP POLICY IF EXISTS media_assets_update_policy ON public.media_assets;
CREATE POLICY media_assets_update_policy
ON public.media_assets FOR UPDATE
TO authenticated
USING (true);

DROP POLICY IF EXISTS media_assets_delete_policy ON public.media_assets;
CREATE POLICY media_assets_delete_policy
ON public.media_assets FOR DELETE
TO authenticated
USING (true);
