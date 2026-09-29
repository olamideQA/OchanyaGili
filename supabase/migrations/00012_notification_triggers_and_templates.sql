-- Migration 00012: Comprehensive Notification Triggers for Orders, Custom Requests, and Appointments
-- Date: 2026-09-29

-- 1. Trigger for Orders status changes
CREATE OR REPLACE FUNCTION public.handle_order_notification_trigger() RETURNS TRIGGER AS $$
DECLARE
    notif_title TEXT;
    notif_body TEXT;
BEGIN
    IF (TG_OP = 'INSERT') OR (TG_OP = 'UPDATE' AND OLD.status IS DISTINCT FROM NEW.status) THEN
        -- Map status to luxury editorial notification copy
        CASE NEW.status
            WHEN 'confirmed' THEN
                notif_title := 'Commission Authenticated & Confirmed';
                notif_body := 'Your commission #' || NEW.order_number || ' has been confirmed through our secure atelier gateway and logged in the master ledger.';
            WHEN 'processing' THEN
                notif_title := 'Textile Allocation & Pattern Drafting';
                notif_body := 'Fabrics curated and anatomical block pattern drafted for commission #' || NEW.order_number || '.';
            WHEN 'in_production' THEN
                notif_title := 'Atelier Craftsmanship in Progress';
                notif_body := 'Your garment #' || NEW.order_number || ' has entered cutting, canvassing, and hand assembly by our master couturiers.';
            WHEN 'ready_for_fitting' THEN
                notif_title := 'Garment Ready for Private Fitting';
                notif_body := 'Commission #' || NEW.order_number || ' has completed primary assembly. Please reserve your private salon fitting session.';
            WHEN 'ready_for_delivery' THEN
                notif_title := 'Quality Inspection Complete';
                notif_body := 'Commission #' || NEW.order_number || ' has passed rigorous couture assessment and salon pressing. Ready for delivery.';
            WHEN 'shipped' THEN
                notif_title := 'Commission Dispatched';
                notif_body := 'Commission #' || NEW.order_number || ' is secured in protective dust carrier and dispatched with our private courier.';
            WHEN 'delivered' THEN
                notif_title := 'Commission Hand-Delivered';
                notif_body := 'Commission #' || NEW.order_number || ' has been safely presented. We trust your bespoke piece brings you joy.';
            WHEN 'cancelled' THEN
                notif_title := 'Commission Cancelled';
                notif_body := 'Commission #' || NEW.order_number || ' has been cancelled. Our concierge is available for any questions.';
            ELSE
                notif_title := 'Commission Status Updated';
                notif_body := 'Commission #' || NEW.order_number || ' status updated to ' || NEW.status || '.';
        END CASE;

        -- Insert in-app notification
        INSERT INTO public.notifications (
            profile_id,
            title,
            body,
            type,
            reference_type,
            reference_id,
            is_read,
            channel,
            created_at
        ) VALUES (
            NEW.profile_id,
            notif_title,
            notif_body,
            'order',
            'order',
            NEW.id,
            false,
            'in_app',
            now()
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_order_notification ON public.orders;
CREATE TRIGGER trg_order_notification
AFTER INSERT OR UPDATE ON public.orders
FOR EACH ROW EXECUTE FUNCTION public.handle_order_notification_trigger();


-- 2. Trigger for Custom Requests / Bespoke status changes
CREATE OR REPLACE FUNCTION public.handle_custom_request_notification_trigger() RETURNS TRIGGER AS $$
DECLARE
    notif_title TEXT;
    notif_body TEXT;
BEGIN
    IF (TG_OP = 'INSERT') OR (TG_OP = 'UPDATE' AND OLD.status IS DISTINCT FROM NEW.status) THEN
        CASE NEW.status
            WHEN 'requested', 'submitted' THEN
                notif_title := 'Bespoke Inquiry Received';
                notif_body := 'Your custom atelier inquiry #' || NEW.request_number || ' has been received. Our design studio is reviewing your specifications.';
            WHEN 'under_review' THEN
                notif_title := 'Design Review in Progress';
                notif_body := 'Master Couturier Ochanya is reviewing your silhouette and material preferences for #' || NEW.request_number || '.';
            WHEN 'quote_sent' THEN
                notif_title := 'Couture Quotation Ready';
                notif_body := 'Your bespoke couture quotation for #' || NEW.request_number || ' has been prepared. Review specifications & estimate in your account.';
            WHEN 'customer_approved' THEN
                notif_title := 'Quotation Approved';
                notif_body := 'Thank you for approving quotation #' || NEW.request_number || '. Textile reservations have commenced.';
            WHEN 'in_production', 'production' THEN
                notif_title := 'Bespoke Creation in Production';
                notif_body := 'Your custom creation #' || NEW.request_number || ' is now in active cutting, boning, and hand embroidery.';
            WHEN 'ready_for_fitting', 'fitting' THEN
                notif_title := 'Bespoke Fitting Ready';
                notif_body := 'Bespoke piece #' || NEW.request_number || ' is prepared for your toile fitting appointment.';
            WHEN 'completed', 'delivered', 'ready' THEN
                notif_title := 'Bespoke Commission Completed';
                notif_body := 'Your one-of-a-kind creation #' || NEW.request_number || ' is completed and ready for gala wear.';
            ELSE
                notif_title := 'Bespoke Request Updated';
                notif_body := 'Your bespoke request #' || NEW.request_number || ' status updated to ' || NEW.status || '.';
        END CASE;

        INSERT INTO public.notifications (
            profile_id,
            title,
            body,
            type,
            reference_type,
            reference_id,
            is_read,
            channel,
            created_at
        ) VALUES (
            NEW.profile_id,
            notif_title,
            notif_body,
            'custom_request',
            'custom_request',
            NEW.id,
            false,
            'in_app',
            now()
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS tr_notify_custom_request_status_change ON public.custom_requests;
DROP TRIGGER IF EXISTS trg_custom_request_notification ON public.custom_requests;
CREATE TRIGGER trg_custom_request_notification
AFTER INSERT OR UPDATE ON public.custom_requests
FOR EACH ROW EXECUTE FUNCTION public.handle_custom_request_notification_trigger();


-- 3. Trigger for Appointments status changes
CREATE OR REPLACE FUNCTION public.handle_appointment_notification_trigger() RETURNS TRIGGER AS $$
DECLARE
    notif_title TEXT;
    notif_body TEXT;
BEGIN
    IF (TG_OP = 'INSERT') OR (TG_OP = 'UPDATE' AND OLD.status IS DISTINCT FROM NEW.status) THEN
        CASE NEW.status
            WHEN 'confirmed' THEN
                notif_title := 'Salon Appointment Confirmed';
                notif_body := 'Your private salon appointment on ' || NEW.scheduled_date || ' at ' || COALESCE(NEW.start_time, '10:00') || ' has been confirmed.';
            WHEN 'completed' THEN
                notif_title := 'Salon Fitting Completed';
                notif_body := 'Thank you for visiting the Ochanya Gili salon. Fitting adjustments have been logged in your profile.';
            WHEN 'cancelled' THEN
                notif_title := 'Appointment Cancelled';
                notif_body := 'Your appointment scheduled for ' || NEW.scheduled_date || ' has been cancelled.';
            ELSE
                notif_title := 'Appointment Updated';
                notif_body := 'Your appointment status has changed to ' || NEW.status || '.';
        END CASE;

        INSERT INTO public.notifications (
            profile_id,
            title,
            body,
            type,
            reference_type,
            reference_id,
            is_read,
            channel,
            created_at
        ) VALUES (
            NEW.profile_id,
            notif_title,
            notif_body,
            'appointment',
            'appointment',
            NEW.id,
            false,
            'in_app',
            now()
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_appointment_notification ON public.appointments;
CREATE TRIGGER trg_appointment_notification
AFTER INSERT OR UPDATE ON public.appointments
FOR EACH ROW EXECUTE FUNCTION public.handle_appointment_notification_trigger();
