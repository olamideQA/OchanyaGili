-- Migration 00005: Payment Verification and Server-Side Transition RPC
-- Date: 2026-09-29

CREATE OR REPLACE FUNCTION public.verify_and_mark_order_paid(
  p_order_number TEXT,
  p_payment_reference TEXT,
  p_provider TEXT DEFAULT 'paystack',
  p_amount DECIMAL DEFAULT 0,
  p_metadata JSONB DEFAULT '{}'::jsonb
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_order RECORD;
  v_payment_id UUID;
BEGIN
  -- 1. Find the order
  SELECT * INTO v_order FROM public.orders WHERE order_number = p_order_number;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Order not found');
  END IF;

  -- 2. Verify payment hasn't already been processed
  IF v_order.status = 'paid' THEN
    RETURN jsonb_build_object('success', true, 'message', 'Order already marked paid', 'order_id', v_order.id);
  END IF;

  -- 3. Verify amount covers order total
  IF p_amount > 0 AND p_amount < v_order.total THEN
    RETURN jsonb_build_object('success', false, 'error', 'Payment amount insufficient for order total');
  END IF;

  -- 4. Update the order
  UPDATE public.orders
  SET 
    status = 'paid',
    payment_status = 'successful',
    payment_reference = p_payment_reference,
    payment_provider = p_provider,
    updated_at = now()
  WHERE id = v_order.id;

  -- 5. Insert verified payment record
  INSERT INTO public.payments (
    order_id,
    profile_id,
    amount,
    currency,
    provider,
    provider_reference,
    provider_status,
    status,
    payment_type,
    metadata,
    verified_at
  ) VALUES (
    v_order.id,
    v_order.profile_id,
    COALESCE(NULLIF(p_amount, 0), v_order.total),
    'NGN',
    p_provider,
    p_payment_reference,
    'success',
    'successful',
    'order',
    p_metadata,
    now()
  ) RETURNING id INTO v_payment_id;

  RETURN jsonb_build_object(
    'success', true,
    'order_id', v_order.id,
    'order_number', v_order.order_number,
    'payment_id', v_payment_id,
    'status', 'paid'
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.verify_and_mark_order_paid TO authenticated, anon;
