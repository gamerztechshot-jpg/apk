-- SQL schema for kundli payment system
-- This file contains the database schema for kundli purchasing functionality

-- Create kundli_payment table for storing kundli purchase records
-- This table stores both order and payment information in JSONB fields
CREATE TABLE IF NOT EXISTS kundli_payment (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    kundli_info JSONB NOT NULL, -- Contains kundli_id and other kundli-related info
    payment_info JSONB NOT NULL, -- Contains razorpay_payment_id, order_id, amount, payment_status, currency, receipt, etc.
    customer_info JSONB NOT NULL, -- Contains customer personal details like name, email, phone, birth details, family info, gotra, specific questions
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_kundli_payment_user_id ON kundli_payment(user_id);
CREATE INDEX IF NOT EXISTS idx_kundli_payment_created_at ON kundli_payment(created_at);

-- Create index on JSONB fields for efficient querying
CREATE INDEX IF NOT EXISTS idx_kundli_payment_kundli_info ON kundli_payment USING GIN(kundli_info);
CREATE INDEX IF NOT EXISTS idx_kundli_payment_payment_info ON kundli_payment USING GIN(payment_info);

-- Enable Row Level Security (RLS)
ALTER TABLE kundli_payment ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
-- Users can only see their own kundli payments
CREATE POLICY "Users can view own kundli payments" ON kundli_payment
    FOR SELECT USING (auth.uid() = user_id);

-- Users can only insert their own kundli payments
CREATE POLICY "Users can insert own kundli payments" ON kundli_payment
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can only update their own kundli payments
CREATE POLICY "Users can update own kundli payments" ON kundli_payment
    FOR UPDATE USING (auth.uid() = user_id);

-- Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_kundli_payment_updated_at 
    BEFORE UPDATE ON kundli_payment 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Create kundli_types table for storing different kundli types
CREATE TABLE IF NOT EXISTS kundli_types (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    image_url TEXT,
    price DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for kundli_types
CREATE INDEX IF NOT EXISTS idx_kundli_types_is_active ON kundli_types(is_active);
CREATE INDEX IF NOT EXISTS idx_kundli_types_price ON kundli_types(price);

-- Enable RLS for kundli_types
ALTER TABLE kundli_types ENABLE ROW LEVEL SECURITY;

-- Create policy for kundli_types (public read access)
CREATE POLICY "Anyone can view active kundli types" ON kundli_types
    FOR SELECT USING (is_active = TRUE);

-- Create trigger for kundli_types updated_at
CREATE TRIGGER update_kundli_types_updated_at 
    BEFORE UPDATE ON kundli_types 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Insert sample kundli types
INSERT INTO kundli_types (title, description, price, is_active) VALUES
('Basic Kundli', 'Get your basic horoscope with planetary positions and basic predictions', 299.00, TRUE),
('Detailed Kundli', 'Comprehensive horoscope with detailed analysis, predictions, and remedies', 599.00, TRUE),
('Premium Kundli', 'Complete horoscope with advanced analysis, compatibility, and personalized guidance', 999.00, TRUE),
('Marriage Kundli', 'Specialized horoscope focusing on marriage compatibility and timing', 799.00, TRUE),
('Career Kundli', 'Horoscope analysis focused on career prospects and professional guidance', 699.00, TRUE)
ON CONFLICT DO NOTHING;

-- Create view for easy querying of kundli payments with user details
CREATE OR REPLACE VIEW kundli_payment_details AS
SELECT 
    kp.id,
    kp.user_id,
    au.email as user_email,
    kp.kundli_info->>'kundli_id' as kundli_id,
    kt.title as kundli_title,
    kt.description as kundli_description,
    kp.payment_info->>'razorpay_payment_id' as razorpay_payment_id,
    kp.payment_info->>'order_id' as order_id,
    kp.payment_info->>'amount' as amount,
    kp.payment_info->>'currency' as currency,
    kp.payment_info->>'receipt' as receipt,
    kp.payment_info->>'payment_status' as payment_status,
    kp.customer_info->>'name' as customer_name,
    kp.customer_info->>'email' as customer_email,
    kp.customer_info->>'phone' as customer_phone,
    kp.customer_info->>'birth_date' as birth_date,
    kp.customer_info->>'birth_time' as birth_time,
    kp.customer_info->>'birth_place' as birth_place,
    kp.customer_info->>'father_name' as father_name,
    kp.customer_info->>'mother_name' as mother_name,
    kp.customer_info->>'gotra' as gotra,
    kp.customer_info->>'specific_questions' as specific_questions,
    kp.created_at,
    kp.updated_at
FROM kundli_payment kp
LEFT JOIN auth.users au ON kp.user_id = au.id
LEFT JOIN kundli_types kt ON kp.kundli_info->>'kundli_id' = kt.id::text;

-- Grant permissions for the view
GRANT SELECT ON kundli_payment_details TO authenticated;

-- Create function to get user's kundli purchase history
CREATE OR REPLACE FUNCTION get_user_kundli_purchases(user_uuid UUID)
RETURNS TABLE (
    payment_id UUID,
    kundli_title VARCHAR(255),
    amount TEXT,
    payment_status TEXT,
    purchase_date TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        kp.id,
        kt.title,
        kp.payment_info->>'amount' as amount_text,
        kp.payment_info->>'payment_status' as status,
        kp.created_at
    FROM kundli_payment kp
    LEFT JOIN kundli_types kt ON kp.kundli_info->>'kundli_id' = kt.id::text
    WHERE kp.user_id = user_uuid
    ORDER BY kp.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION get_user_kundli_purchases(UUID) TO authenticated;

-- Create function to get kundli payment statistics (for admin use)
CREATE OR REPLACE FUNCTION get_kundli_payment_stats()
RETURNS TABLE (
    total_payments BIGINT,
    total_revenue NUMERIC,
    successful_payments BIGINT,
    failed_payments BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*) as total_payments,
        COALESCE(SUM((payment_info->>'amount')::NUMERIC), 0) as total_revenue,
        COUNT(*) FILTER (WHERE payment_info->>'payment_status' = 'success') as successful_payments,
        COUNT(*) FILTER (WHERE payment_info->>'payment_status' = 'failed') as failed_payments
    FROM kundli_payment;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the stats function
GRANT EXECUTE ON FUNCTION get_kundli_payment_stats() TO authenticated;

-- Add comments for documentation
COMMENT ON TABLE kundli_payment IS 'Stores kundli purchase payment records';
COMMENT ON COLUMN kundli_payment.kundli_info IS 'JSONB containing kundli_id and related kundli information';
COMMENT ON COLUMN kundli_payment.payment_info IS 'JSONB containing Razorpay payment details, order_id, amount, status';
COMMENT ON COLUMN kundli_payment.customer_info IS 'JSONB containing customer personal details and birth information';

COMMENT ON TABLE kundli_types IS 'Stores different types of kundli services available for purchase';
COMMENT ON COLUMN kundli_types.price IS 'Price in INR for the kundli service';

COMMENT ON VIEW kundli_payment_details IS 'View combining kundli payment data with user and kundli type information';

COMMENT ON FUNCTION get_user_kundli_purchases IS 'Returns purchase history for a specific user';
COMMENT ON FUNCTION get_kundli_payment_stats IS 'Returns payment statistics for admin dashboard';
