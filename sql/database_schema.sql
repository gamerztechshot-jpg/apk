-- Dharma Store Database Schema - Simplified Structure
-- This file contains the SQL commands to create the necessary tables for the Dharma Store

-- Orders Table - Simplified Structure
CREATE TABLE IF NOT EXISTS orders (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id TEXT NOT NULL,
    order_number VARCHAR(20) UNIQUE NOT NULL,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'shipped', 'delivered', 'cancelled')),
    total_amount DECIMAL(10,2) NOT NULL,
    payment_info JSONB NOT NULL, -- Contains order_id, razorpay_id, payment_status, etc.
    address JSONB NOT NULL, -- Delivery address JSON
    items JSONB NOT NULL, -- Array of ordered items with details
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Cart Table - Simplified Structure with JSON storage
CREATE TABLE IF NOT EXISTS cart (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id TEXT NOT NULL UNIQUE,
    items JSONB DEFAULT '[]'::jsonb, -- Array of cart items
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add address column to profiles table (if not exists)
-- This will be handled by you as mentioned

-- Indexes for better performance
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at);
CREATE INDEX IF NOT EXISTS idx_cart_user_id ON cart(user_id);

-- Triggers for updating updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_cart_updated_at BEFORE UPDATE ON cart
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- RLS (Row Level Security) Policies
-- Enable RLS on tables
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE cart ENABLE ROW LEVEL SECURITY;

-- RLS Policies for orders
CREATE POLICY "Users can view their own orders" ON orders
    FOR SELECT USING (auth.uid()::text = user_id);

CREATE POLICY "Users can insert their own orders" ON orders
    FOR INSERT WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can update their own orders" ON orders
    FOR UPDATE USING (auth.uid()::text = user_id);

-- RLS Policies for cart
CREATE POLICY "Users can view their own cart" ON cart
    FOR SELECT USING (auth.uid()::text = user_id);

CREATE POLICY "Users can insert their own cart" ON cart
    FOR INSERT WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can update their own cart" ON cart
    FOR UPDATE USING (auth.uid()::text = user_id);

CREATE POLICY "Users can delete their own cart" ON cart
    FOR DELETE USING (auth.uid()::text = user_id);

-- Puja Payment Table (new JSON structure)
CREATE TABLE IF NOT EXISTS puja_payment (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id TEXT NOT NULL,
    puja_info JSONB NOT NULL, -- { puja_id, package_id }
    payment_info JSONB NOT NULL, -- { razorpay_payment_id, order_id, amount, payment_status, puja_completed }
    customer_info JSONB NOT NULL, -- varies by package type
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_puja_payment_user_id ON puja_payment(user_id);
CREATE INDEX IF NOT EXISTS idx_puja_payment_created_at ON puja_payment(created_at);

ALTER TABLE puja_payment ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own puja payments" ON puja_payment
    FOR SELECT USING (auth.uid()::text = user_id);

CREATE POLICY "Users can insert their own puja payments" ON puja_payment
    FOR INSERT WITH CHECK (auth.uid()::text = user_id);

CREATE TRIGGER update_puja_payment_updated_at BEFORE UPDATE ON puja_payment
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
