-- Migration 00009: Quotation & Custom Order Workflow Enhancements
-- Date: 2026-09-29

-- 1. Fix RLS on public.quotes
DROP POLICY IF EXISTS "Users can view quotes for own requests" ON public.quotes;
DROP POLICY IF EXISTS "Admins can manage quotes" ON public.quotes;

CREATE POLICY "Users can view quotes for own requests" ON public.quotes
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.custom_requests cr 
      WHERE cr.id = custom_request_id 
        AND (cr.profile_id = auth.uid() OR public.get_user_role() IN ('admin', 'designer'))
    )
  );

CREATE POLICY "Admins can manage quotes" ON public.quotes
  FOR ALL
  USING (public.get_user_role() IN ('admin', 'designer'));

-- 2. Fix RLS on public.quote_items
DROP POLICY IF EXISTS "Quote items follow quote visibility" ON public.quote_items;
DROP POLICY IF EXISTS "Admins can manage quote items" ON public.quote_items;

CREATE POLICY "Quote items readable" ON public.quote_items
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.quotes q
      JOIN public.custom_requests cr ON cr.id = q.custom_request_id
      WHERE q.id = quote_id 
        AND (cr.profile_id = auth.uid() OR public.get_user_role() IN ('admin', 'designer'))
    )
  );

CREATE POLICY "Admins can manage quote items" ON public.quote_items
  FOR ALL
  USING (public.get_user_role() IN ('admin', 'designer'));

-- 3. Fix RLS on public.notifications
DROP POLICY IF EXISTS "Users can view own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can update own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Admins manage notifications" ON public.notifications;

CREATE POLICY "Users can view own notifications" ON public.notifications
  FOR SELECT
  USING (profile_id = auth.uid() OR public.get_user_role() IN ('admin', 'designer'));

CREATE POLICY "Users can update own notifications" ON public.notifications
  FOR UPDATE
  USING (profile_id = auth.uid() OR public.get_user_role() IN ('admin', 'designer'));

CREATE POLICY "System can insert notifications" ON public.notifications
  FOR INSERT
  WITH CHECK (true);

-- 4. Trigger: Prevent silently modifying an accepted quote without a new version
CREATE OR REPLACE FUNCTION public.prevent_editing_accepted_quote()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.status = 'accepted' AND NEW.status = 'accepted' AND (
    OLD.total != NEW.total OR OLD.subtotal != NEW.subtotal OR OLD.deposit_amount != NEW.deposit_amount
  ) THEN
    RAISE EXCEPTION 'Accepted quotations cannot be altered. A new quote version must be issued.';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tr_prevent_editing_accepted_quote ON public.quotes;
CREATE TRIGGER tr_prevent_editing_accepted_quote
  BEFORE UPDATE ON public.quotes
  FOR EACH ROW
  EXECUTE FUNCTION public.prevent_editing_accepted_quote();

-- 5. Trigger: Automated audit logging of custom request status transitions
CREATE OR REPLACE FUNCTION public.log_custom_request_status_change()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    INSERT INTO public.custom_request_status_history (custom_request_id, from_status, to_status, changed_by, notes)
    VALUES (NEW.id, OLD.status, NEW.status, auth.uid(), NEW.designer_notes);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Trigger: Automated customer notification on custom request status changes
CREATE OR REPLACE FUNCTION public.notify_custom_request_status_change()
RETURNS TRIGGER AS $$
DECLARE
  notif_title TEXT;
  notif_body TEXT;
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    CASE NEW.status
      WHEN 'under_review' THEN
        notif_title := 'Bespoke Request Under Review';
        notif_body := 'Your custom creation request ' || NEW.request_number || ' is being reviewed by our master tailor.';
      WHEN 'design_discussion' THEN
        notif_title := 'Design Consultation Scheduled';
        notif_body := 'Our designer is ready to discuss sketches and fabric choices for ' || NEW.request_number || '.';
      WHEN 'quote_sent' THEN
        notif_title := 'Atelier Quotation Ready';
        notif_body := 'An itemized quotation has been prepared for commission ' || NEW.request_number || '. Please review and approve.';
      WHEN 'customer_approved' THEN
        notif_title := 'Quotation Approved';
        notif_body := 'You approved the quote for ' || NEW.request_number || '. Settle your deposit to commence atelier fabrication.';
      WHEN 'payment' THEN
        notif_title := 'Deposit Settled';
        notif_body := 'Payment confirmed for commission ' || NEW.request_number || '. Premium textiles are being allocated.';
      WHEN 'production' THEN
        notif_title := 'Atelier Construction Started';
        notif_body := 'Master craftsmen have begun hand-cutting and tailoring for ' || NEW.request_number || '.';
      WHEN 'fitting' THEN
        notif_title := 'Fitting Ready';
        notif_body := 'Your bespoke piece ' || NEW.request_number || ' is prepared for your fitting in Abuja or private salon.';
      WHEN 'alteration' THEN
        notif_title := 'Precision Alterations';
        notif_body := 'Final tailor refinements are being applied to ' || NEW.request_number || '.';
      WHEN 'ready' THEN
        notif_title := 'Creation Completed';
        notif_body := 'Commission ' || NEW.request_number || ' has completed quality assurance and is ready for dispatch.';
      WHEN 'delivered' THEN
        notif_title := 'Creation Delivered';
        notif_body := 'Commission ' || NEW.request_number || ' has been delivered. Wear with distinction.';
      ELSE
        notif_title := 'Commission Status Update';
        notif_body := 'Your bespoke request ' || NEW.request_number || ' has progressed to ' || NEW.status || '.';
    END CASE;

    INSERT INTO public.notifications (profile_id, title, body, type, reference_type, reference_id)
    VALUES (NEW.profile_id, notif_title, notif_body, 'custom_request', 'custom_request', NEW.id);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS tr_notify_custom_request_status_change ON public.custom_requests;
CREATE TRIGGER tr_notify_custom_request_status_change
  AFTER UPDATE OF status ON public.custom_requests
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_custom_request_status_change();

-- 7. Server-side RPC to record deposit payment for approved custom request
CREATE OR REPLACE FUNCTION public.settle_custom_request_deposit(
  p_custom_request_id UUID,
  p_quote_id UUID,
  p_payment_reference TEXT,
  p_amount_paid DECIMAL(12,2)
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_req RECORD;
  v_quote RECORD;
BEGIN
  -- 1. Fetch custom request
  SELECT * INTO v_req FROM public.custom_requests WHERE id = p_custom_request_id;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Custom request not found');
  END IF;

  -- 2. Validate request is approved
  IF v_req.status != 'customer_approved' AND v_req.status != 'quote_sent' THEN
    RETURN jsonb_build_object('success', false, 'error', 'Payment locked: Quotation must be customer approved first');
  END IF;

  -- 3. Fetch quote
  SELECT * INTO v_quote FROM public.quotes WHERE id = p_quote_id AND custom_request_id = p_custom_request_id;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Quotation not found');
  END IF;

  -- 4. Mark quote as accepted
  UPDATE public.quotes 
  SET status = 'accepted', updated_at = now()
  WHERE id = p_quote_id;

  -- 5. Advance custom request status to 'production' (or 'payment')
  UPDATE public.custom_requests
  SET 
    status = 'production',
    designer_notes = 'Deposit of NGN ' || p_amount_paid::text || ' settled (Ref: ' || p_payment_reference || '). Sent to master cutting.',
    updated_at = now()
  WHERE id = p_custom_request_id;

  RETURN jsonb_build_object(
    'success', true,
    'custom_request_id', p_custom_request_id,
    'quote_id', p_quote_id,
    'amount_paid', p_amount_paid,
    'reference', p_payment_reference,
    'new_status', 'production'
  );
END;
$$;

-- 8. Grants
GRANT ALL ON public.quotes TO anon, authenticated;
GRANT ALL ON public.quote_items TO anon, authenticated;
GRANT ALL ON public.notifications TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.settle_custom_request_deposit TO anon, authenticated;
