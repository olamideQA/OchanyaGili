-- Migration 00015: Push Notifications and Device Tokens for Mobile Foundation (Loop 17)
CREATE TABLE IF NOT EXISTS public.user_devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    device_token TEXT NOT NULL,
    platform TEXT NOT NULL CHECK (platform IN ('android', 'ios', 'web')),
    device_name TEXT,
    app_version TEXT,
    is_active BOOLEAN DEFAULT true,
    last_active_at TIMESTAMPTZ DEFAULT now(),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    CONSTRAINT uq_user_device UNIQUE (profile_id, device_token)
);

-- Indices
CREATE INDEX IF NOT EXISTS idx_user_devices_profile ON public.user_devices(profile_id);
CREATE INDEX IF NOT EXISTS idx_user_devices_token ON public.user_devices(device_token);

-- Enable RLS
ALTER TABLE public.user_devices ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can manage their own devices"
ON public.user_devices
FOR ALL
TO authenticated
USING (auth.uid() = profile_id)
WITH CHECK (auth.uid() = profile_id);

CREATE POLICY "Staff can view devices for notification dispatch"
ON public.user_devices
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid()
        AND role IN ('admin', 'designer', 'front_desk', 'production_staff')
    )
);

-- Grant access
GRANT ALL ON public.user_devices TO authenticated;
GRANT ALL ON public.user_devices TO service_role;
