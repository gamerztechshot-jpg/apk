-- Astrologer Booking Schema
-- This file contains the SQL schema for astrologer booking functionality

-- Create astrologer_bookings table for storing booking records
CREATE TABLE IF NOT EXISTS astrologer_bookings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    astrologer_id UUID NOT NULL REFERENCES astrologers(id) ON DELETE CASCADE,
    booking_type VARCHAR(20) NOT NULL CHECK (booking_type IN ('per_minute', 'per_month')),
    minutes_booked INTEGER, -- Only for per_minute bookings
    communication_mode VARCHAR(10) CHECK (communication_mode IN ('chat', 'call')), -- Only for per_minute bookings
    total_amount DECIMAL(10,2) NOT NULL,
    payment_status VARCHAR(20) DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'failed', 'refunded')),
    booking_status VARCHAR(20) DEFAULT 'pending' CHECK (booking_status IN ('pending', 'confirmed', 'completed', 'cancelled')),
    payment_info JSONB, -- Contains razorpay_payment_id, order_id, etc.
    customer_info JSONB NOT NULL, -- Contains customer details
    scheduled_time TIMESTAMP WITH TIME ZONE, -- When the consultation is scheduled
    consultation_notes TEXT, -- Notes about the consultation
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_astrologer_bookings_user_id ON astrologer_bookings(user_id);
CREATE INDEX IF NOT EXISTS idx_astrologer_bookings_astrologer_id ON astrologer_bookings(astrologer_id);
CREATE INDEX IF NOT EXISTS idx_astrologer_bookings_booking_type ON astrologer_bookings(booking_type);
CREATE INDEX IF NOT EXISTS idx_astrologer_bookings_payment_status ON astrologer_bookings(payment_status);
CREATE INDEX IF NOT EXISTS idx_astrologer_bookings_booking_status ON astrologer_bookings(booking_status);
CREATE INDEX IF NOT EXISTS idx_astrologer_bookings_created_at ON astrologer_bookings(created_at);

-- Create index on JSONB fields for efficient querying
CREATE INDEX IF NOT EXISTS idx_astrologer_bookings_payment_info ON astrologer_bookings USING GIN(payment_info);
CREATE INDEX IF NOT EXISTS idx_astrologer_bookings_customer_info ON astrologer_bookings USING GIN(customer_info);

-- Enable Row Level Security (RLS)
ALTER TABLE astrologer_bookings ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
-- Users can only see their own bookings
CREATE POLICY "Users can view own astrologer bookings" ON astrologer_bookings
    FOR SELECT USING (auth.uid() = user_id);

-- Users can insert their own bookings
CREATE POLICY "Users can insert own astrologer bookings" ON astrologer_bookings
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own bookings (e.g., status changes)
CREATE POLICY "Users can update own astrologer bookings" ON astrologer_bookings
    FOR UPDATE USING (auth.uid() = user_id);

-- Users can delete their own bookings (if needed)
CREATE POLICY "Users can delete own astrologer bookings" ON astrologer_bookings
    FOR DELETE USING (auth.uid() = user_id);

-- Create trigger for updating updated_at timestamp
CREATE TRIGGER update_astrologer_bookings_updated_at BEFORE UPDATE ON astrologer_bookings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create view for easy querying of astrologer bookings with details
CREATE OR REPLACE VIEW astrologer_booking_details AS
SELECT
    ab.id,
    ab.user_id,
    au.email as user_email,
    au.raw_user_meta_data->>'name' as user_name,
    ab.astrologer_id,
    a.name as astrologer_name,
    a.qualification as astrologer_qualification,
    a.per_minute_charge,
    a.per_month_charge,
    ab.booking_type,
    ab.minutes_booked,
    ab.communication_mode,
    ab.total_amount,
    ab.payment_status,
    ab.booking_status,
    ab.payment_info->>'razorpay_payment_id' as razorpay_payment_id,
    ab.payment_info->>'order_id' as order_id,
    ab.customer_info->>'name' as customer_name,
    ab.customer_info->>'email' as customer_email,
    ab.customer_info->>'phone' as customer_phone,
    ab.scheduled_time,
    ab.consultation_notes,
    ab.created_at,
    ab.updated_at
FROM astrologer_bookings ab
LEFT JOIN auth.users au ON ab.user_id = au.id
LEFT JOIN astrologers a ON ab.astrologer_id = a.id;

-- Grant permissions for the view
GRANT SELECT ON astrologer_booking_details TO authenticated;

-- Create function to get user's astrologer booking history
CREATE OR REPLACE FUNCTION get_user_astrologer_bookings(p_user_id UUID)
RETURNS SETOF astrologer_booking_details
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY SELECT * FROM astrologer_booking_details
    WHERE user_id = p_user_id
    ORDER BY created_at DESC;
END;
$$;

-- Grant execution rights to authenticated users
GRANT EXECUTE ON FUNCTION get_user_astrologer_bookings(UUID) TO authenticated;

-- Create function to get astrologer's booking statistics
CREATE OR REPLACE FUNCTION get_astrologer_booking_stats(p_astrologer_id UUID)
RETURNS TABLE(
    total_bookings BIGINT,
    completed_bookings BIGINT,
    pending_bookings BIGINT,
    total_earnings DECIMAL(10,2),
    avg_booking_value DECIMAL(10,2)
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*) as total_bookings,
        COUNT(*) FILTER (WHERE booking_status = 'completed') as completed_bookings,
        COUNT(*) FILTER (WHERE booking_status = 'pending') as pending_bookings,
        COALESCE(SUM(total_amount) FILTER (WHERE payment_status = 'paid'), 0) as total_earnings,
        COALESCE(AVG(total_amount) FILTER (WHERE payment_status = 'paid'), 0) as avg_booking_value
    FROM astrologer_bookings
    WHERE astrologer_id = p_astrologer_id;
END;
$$;

-- Grant execution rights to authenticated users
GRANT EXECUTE ON FUNCTION get_astrologer_booking_stats(UUID) TO authenticated;

-- Insert some sample booking data for testing (optional)
-- INSERT INTO astrologer_bookings (user_id, astrologer_id, booking_type, minutes_booked, communication_mode, total_amount, payment_status, booking_status, customer_info, payment_info) VALUES
-- ('sample-user-id', 'a1111111-1111-1111-1111-111111111111', 'per_minute', 30, 'chat', 1200.00, 'paid', 'completed', 
--  '{"name": "John Doe", "email": "john@example.com", "phone": "+91-9876543210"}',
--  '{"razorpay_payment_id": "pay_test123", "order_id": "order_test123", "payment_status": "paid"}'),
-- ('sample-user-id', 'a2222222-2222-2222-2222-222222222222', 'per_month', NULL, NULL, 3000.00, 'paid', 'confirmed',
--  '{"name": "Jane Smith", "email": "jane@example.com", "phone": "+91-9876543211"}',
--  '{"razorpay_payment_id": "pay_test456", "order_id": "order_test456", "payment_status": "paid"}');
