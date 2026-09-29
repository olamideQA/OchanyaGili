-- Migration 00010: Appointments System (Loop 9)
-- Designer availability config, slot engine support, concurrent booking prevention

-- ============================================================
-- 1. Designer Availability Configuration Table
-- ============================================================
CREATE TABLE IF NOT EXISTS public.designer_availability (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  day_of_week integer NOT NULL CHECK (day_of_week BETWEEN 0 AND 6), -- 0=Sunday, 6=Saturday
  start_time time NOT NULL DEFAULT '09:00',
  end_time time NOT NULL DEFAULT '17:00',
  is_available boolean NOT NULL DEFAULT true,
  max_appointments integer NOT NULL DEFAULT 8,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(day_of_week)
);

ALTER TABLE public.designer_availability ENABLE ROW LEVEL SECURITY;

-- Designers/admins can manage availability
CREATE POLICY "Admins manage availability" ON public.designer_availability
  FOR ALL USING (public.get_user_role() IN ('admin', 'designer'))
  WITH CHECK (public.get_user_role() IN ('admin', 'designer'));

-- Everyone can read availability (for booking calendar)
CREATE POLICY "Anyone can view availability" ON public.designer_availability
  FOR SELECT USING (true);

-- Seed default availability: Mon-Fri 9am-5pm, Sat 10am-2pm, Sun closed
INSERT INTO public.designer_availability (day_of_week, start_time, end_time, is_available, max_appointments) VALUES
  (0, '09:00', '17:00', false, 0),  -- Sunday (closed)
  (1, '09:00', '17:00', true, 8),   -- Monday
  (2, '09:00', '17:00', true, 8),   -- Tuesday
  (3, '09:00', '17:00', true, 8),   -- Wednesday
  (4, '09:00', '17:00', true, 8),   -- Thursday
  (5, '09:00', '17:00', true, 8),   -- Friday
  (6, '10:00', '14:00', true, 4)    -- Saturday (half day)
ON CONFLICT (day_of_week) DO NOTHING;

-- ============================================================
-- 2. Seed Default Appointment Types
-- ============================================================
INSERT INTO public.appointment_types (name, slug, description, duration_minutes, buffer_minutes, booking_fee, is_active, sort_order) VALUES
  ('Style Consultation', 'consultation', 'One-on-one consultation with our head designer to discuss your vision, preferences, and wardrobe needs.', 60, 15, 15000, true, 0),
  ('Measurement Session', 'measurement', 'Professional body measurement session with our master tailor. All 18 anatomical points captured for a perfect fit.', 45, 10, 10000, true, 1),
  ('Garment Fitting', 'fitting', 'Try on your in-progress garment for adjustments. Pins, draping, and modifications are done on the spot.', 60, 15, 0, true, 2),
  ('Custom Design Consultation', 'custom-design', 'Deep-dive session for bespoke commissions. Bring your inspirations, fabrics, and sketches for a collaborative design session.', 90, 20, 25000, true, 3)
ON CONFLICT DO NOTHING;

-- ============================================================
-- 3. Unique Constraint for Concurrent Booking Prevention
-- ============================================================
-- Allow pending_payment in appointments status check constraint
ALTER TABLE public.appointments DROP CONSTRAINT IF EXISTS appointments_status_check;
ALTER TABLE public.appointments ADD CONSTRAINT appointments_status_check 
  CHECK ((status = ANY (ARRAY['pending'::text, 'pending_payment'::text, 'confirmed'::text, 'completed'::text, 'cancelled'::text, 'no_show'::text])));

-- Prevent two appointments at the exact same date+time
CREATE UNIQUE INDEX IF NOT EXISTS idx_appointments_no_double_booking
  ON public.appointments (scheduled_date, start_time)
  WHERE status NOT IN ('cancelled');

-- ============================================================
-- 4. RPC: Concurrent-Safe Booking
-- ============================================================
CREATE OR REPLACE FUNCTION public.book_appointment(
  p_profile_id uuid,
  p_appointment_type_slug text,
  p_scheduled_date date,
  p_start_time time,
  p_notes text DEFAULT NULL,
  p_custom_request_id uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_type_id uuid;
  v_duration_minutes integer;
  v_buffer_minutes integer;
  v_booking_fee numeric;
  v_end_time time;
  v_day_of_week integer;
  v_avail_start time;
  v_avail_end time;
  v_is_available boolean;
  v_max_appts integer;
  v_current_count integer;
  v_conflict_count integer;
  v_appointment_id uuid;
BEGIN
  -- 1. Resolve appointment type
  SELECT id, duration_minutes, buffer_minutes, booking_fee
  INTO v_type_id, v_duration_minutes, v_buffer_minutes, v_booking_fee
  FROM public.appointment_types
  WHERE slug = p_appointment_type_slug AND is_active = true;

  IF v_type_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Invalid or inactive appointment type');
  END IF;

  -- 2. Calculate end time
  v_end_time := p_start_time + (v_duration_minutes || ' minutes')::interval;

  -- 3. Check designer availability for that day
  v_day_of_week := EXTRACT(DOW FROM p_scheduled_date)::integer;

  SELECT start_time, end_time, is_available, max_appointments
  INTO v_avail_start, v_avail_end, v_is_available, v_max_appts
  FROM public.designer_availability
  WHERE day_of_week = v_day_of_week;

  IF NOT v_is_available THEN
    RETURN jsonb_build_object('success', false, 'error', 'The atelier is closed on this day');
  END IF;

  -- 4. Check within working hours
  IF p_start_time < v_avail_start OR v_end_time > v_avail_end THEN
    RETURN jsonb_build_object('success', false, 'error', 'Requested time is outside working hours (' || v_avail_start::text || ' - ' || v_avail_end::text || ')');
  END IF;

  -- 5. Check max appointments per day
  SELECT COUNT(*) INTO v_current_count
  FROM public.appointments
  WHERE scheduled_date = p_scheduled_date AND status NOT IN ('cancelled');

  IF v_current_count >= v_max_appts THEN
    RETURN jsonb_build_object('success', false, 'error', 'Maximum appointments reached for this day (' || v_max_appts || ')');
  END IF;

  -- 6. Check for time slot conflicts (including buffer)
  SELECT COUNT(*) INTO v_conflict_count
  FROM public.appointments a
  JOIN public.appointment_types at ON a.appointment_type_id = at.id
  WHERE a.scheduled_date = p_scheduled_date
    AND a.status NOT IN ('cancelled')
    AND (
      -- New appointment overlaps existing (with buffer)
      (p_start_time < (a.end_time + (at.buffer_minutes || ' minutes')::interval)::time
       AND v_end_time > (a.start_time - (v_buffer_minutes || ' minutes')::interval)::time)
    );

  IF v_conflict_count > 0 THEN
    RETURN jsonb_build_object('success', false, 'error', 'This time slot conflicts with an existing appointment (including buffer time)');
  END IF;

  -- 7. Insert the appointment (DB unique index provides last-line defense against concurrent inserts)
  INSERT INTO public.appointments (
    profile_id, appointment_type_id, scheduled_date, start_time, end_time,
    status, booking_fee_paid, notes, custom_request_id
  ) VALUES (
    p_profile_id, v_type_id, p_scheduled_date, p_start_time, v_end_time,
    CASE WHEN v_booking_fee > 0 THEN 'pending_payment' ELSE 'confirmed' END,
    CASE WHEN v_booking_fee <= 0 THEN true ELSE false END,
    p_notes, p_custom_request_id
  )
  RETURNING id INTO v_appointment_id;

  -- 8. Create notification
  INSERT INTO public.notifications (profile_id, title, body, type, reference_type, reference_id)
  VALUES (
    p_profile_id,
    'Appointment Booked',
    'Your ' || p_appointment_type_slug || ' appointment is scheduled for ' || p_scheduled_date::text || ' at ' || p_start_time::text || '.',
    'appointment',
    'appointment',
    v_appointment_id
  );

  RETURN jsonb_build_object(
    'success', true,
    'appointment_id', v_appointment_id,
    'scheduled_date', p_scheduled_date,
    'start_time', p_start_time,
    'end_time', v_end_time,
    'booking_fee', v_booking_fee,
    'status', CASE WHEN v_booking_fee > 0 THEN 'pending_payment' ELSE 'confirmed' END
  );

EXCEPTION
  WHEN unique_violation THEN
    RETURN jsonb_build_object('success', false, 'error', 'This time slot was just booked by another client. Please select a different time.');
END;
$$;

-- ============================================================
-- 5. RPC: Get Available Slots for a Date
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_available_slots(
  p_date date,
  p_appointment_type_slug text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_day_of_week integer;
  v_avail_start time;
  v_avail_end time;
  v_is_available boolean;
  v_max_appts integer;
  v_duration integer;
  v_buffer integer;
  v_current_count integer;
  v_slot_time time;
  v_slot_end time;
  v_conflict boolean;
  v_slots jsonb := '[]'::jsonb;
BEGIN
  -- Get day config
  v_day_of_week := EXTRACT(DOW FROM p_date)::integer;

  SELECT start_time, end_time, is_available, max_appointments
  INTO v_avail_start, v_avail_end, v_is_available, v_max_appts
  FROM public.designer_availability
  WHERE day_of_week = v_day_of_week;

  IF NOT v_is_available THEN
    RETURN jsonb_build_object('available', false, 'reason', 'Atelier closed', 'slots', '[]'::jsonb);
  END IF;

  -- Check if max reached
  SELECT COUNT(*) INTO v_current_count
  FROM public.appointments
  WHERE scheduled_date = p_date AND status NOT IN ('cancelled');

  IF v_current_count >= v_max_appts THEN
    RETURN jsonb_build_object('available', false, 'reason', 'Fully booked', 'slots', '[]'::jsonb);
  END IF;

  -- Get appointment type config
  SELECT duration_minutes, buffer_minutes
  INTO v_duration, v_buffer
  FROM public.appointment_types
  WHERE slug = p_appointment_type_slug AND is_active = true;

  IF v_duration IS NULL THEN
    RETURN jsonb_build_object('available', false, 'reason', 'Invalid appointment type', 'slots', '[]'::jsonb);
  END IF;

  -- Generate time slots at 30-minute intervals
  v_slot_time := v_avail_start;

  WHILE v_slot_time + (v_duration || ' minutes')::interval <= v_avail_end LOOP
    v_slot_end := (v_slot_time + (v_duration || ' minutes')::interval)::time;

    -- Check for conflicts
    SELECT EXISTS (
      SELECT 1 FROM public.appointments a
      JOIN public.appointment_types at ON a.appointment_type_id = at.id
      WHERE a.scheduled_date = p_date
        AND a.status NOT IN ('cancelled')
        AND (
          v_slot_time < (a.end_time + (at.buffer_minutes || ' minutes')::interval)::time
          AND v_slot_end > (a.start_time - (v_buffer || ' minutes')::interval)::time
        )
    ) INTO v_conflict;

    IF NOT v_conflict THEN
      v_slots := v_slots || jsonb_build_object(
        'start_time', v_slot_time::text,
        'end_time', v_slot_end::text
      );
    END IF;

    v_slot_time := (v_slot_time + '30 minutes'::interval)::time;
  END LOOP;

  RETURN jsonb_build_object('available', true, 'slots', v_slots, 'booked_count', v_current_count, 'max_appointments', v_max_appts);
END;
$$;

-- ============================================================
-- 6. RPC: Settle Appointment Booking Fee
-- ============================================================
CREATE OR REPLACE FUNCTION public.settle_appointment_booking_fee(
  p_appointment_id uuid,
  p_payment_reference text,
  p_amount_paid numeric
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_appt record;
  v_booking_fee numeric;
BEGIN
  -- Fetch appointment
  SELECT a.*, at.booking_fee
  INTO v_appt
  FROM public.appointments a
  JOIN public.appointment_types at ON a.appointment_type_id = at.id
  WHERE a.id = p_appointment_id;

  IF v_appt IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Appointment not found');
  END IF;

  IF v_appt.booking_fee_paid THEN
    RETURN jsonb_build_object('success', false, 'error', 'Booking fee already paid');
  END IF;

  v_booking_fee := v_appt.booking_fee;

  IF p_amount_paid < v_booking_fee THEN
    RETURN jsonb_build_object('success', false, 'error', 'Insufficient payment amount. Required: ' || v_booking_fee::text);
  END IF;

  -- Update appointment
  UPDATE public.appointments
  SET booking_fee_paid = true,
      status = 'confirmed',
      updated_at = now()
  WHERE id = p_appointment_id;

  -- Notify
  INSERT INTO public.notifications (profile_id, title, body, type, reference_type, reference_id)
  VALUES (
    v_appt.profile_id,
    'Booking Fee Confirmed',
    'Your booking fee of NGN ' || v_booking_fee::text || ' has been received. Your appointment on ' || v_appt.scheduled_date::text || ' at ' || v_appt.start_time::text || ' is now confirmed.',
    'payment',
    'appointment',
    p_appointment_id
  );

  RETURN jsonb_build_object(
    'success', true,
    'appointment_id', p_appointment_id,
    'status', 'confirmed',
    'reference', p_payment_reference
  );
END;
$$;

-- ============================================================
-- 7. Update RLS on appointments table
-- ============================================================
-- Drop existing policies if any
DROP POLICY IF EXISTS "Customers manage own appointments" ON public.appointments;
DROP POLICY IF EXISTS "Admins manage all appointments" ON public.appointments;

-- Customers can view and create their own appointments
CREATE POLICY "Customers manage own appointments" ON public.appointments
  FOR ALL USING (
    profile_id = auth.uid()
    OR public.get_user_role() IN ('admin', 'designer', 'front_desk')
  )
  WITH CHECK (
    profile_id = auth.uid()
    OR public.get_user_role() IN ('admin', 'designer', 'front_desk')
  );
