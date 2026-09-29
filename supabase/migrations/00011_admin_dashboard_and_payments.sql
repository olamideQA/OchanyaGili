-- 00011_admin_dashboard_and_payments.sql
-- Ensure Admins and Designers can manage payments (INSERT, UPDATE, DELETE)

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'payments' AND policyname = 'Admins can manage payments'
    ) THEN
        CREATE POLICY "Admins can manage payments" ON payments 
        FOR ALL 
        USING (get_user_role() = ANY (ARRAY['admin', 'designer'])) 
        WITH CHECK (get_user_role() = ANY (ARRAY['admin', 'designer']));
    END IF;
END $$;
