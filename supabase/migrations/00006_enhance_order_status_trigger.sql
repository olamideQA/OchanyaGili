-- Migration 00006: Capture transition notes in order_status_history trigger
-- Date: 2026-09-29

CREATE OR REPLACE FUNCTION public.log_order_status_change() RETURNS TRIGGER AS $$
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    INSERT INTO public.order_status_history (order_id, from_status, to_status, changed_by, notes)
    VALUES (NEW.id, OLD.status, NEW.status, auth.uid(), NEW.notes);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
