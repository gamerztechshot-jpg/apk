-- Pandit BookNow Table Schema
-- This table stores booking requests made by users to specific pandits

CREATE TABLE IF NOT EXISTS pandit_booknow (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id TEXT NOT NULL,
    pandit_id TEXT NOT NULL,
    details JSONB NOT NULL, -- Contains name, puja_details, booking_date, status, notes, etc.
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for better performance
CREATE INDEX IF NOT EXISTS idx_pandit_booknow_user_id ON pandit_booknow(user_id);
CREATE INDEX IF NOT EXISTS idx_pandit_booknow_pandit_id ON pandit_booknow(pandit_id);
CREATE INDEX IF NOT EXISTS idx_pandit_booknow_created_at ON pandit_booknow(created_at);

-- Trigger for updating updated_at timestamp
CREATE TRIGGER update_pandit_booknow_updated_at BEFORE UPDATE ON pandit_booknow
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- RLS (Row Level Security) Policies
ALTER TABLE pandit_booknow ENABLE ROW LEVEL SECURITY;

-- Users can view their own bookings
CREATE POLICY "Users can view their own bookings" ON pandit_booknow
    FOR SELECT USING (auth.uid()::text = user_id);

-- Users can insert their own bookings
CREATE POLICY "Users can insert their own bookings" ON pandit_booknow
    FOR INSERT WITH CHECK (auth.uid()::text = user_id);

-- Users can update their own bookings
CREATE POLICY "Users can update their own bookings" ON pandit_booknow
    FOR UPDATE USING (auth.uid()::text = user_id);

-- Users can delete their own bookings
CREATE POLICY "Users can delete their own bookings" ON pandit_booknow
    FOR DELETE USING (auth.uid()::text = user_id);

-- Pandits can view bookings made to them
CREATE POLICY "Pandits can view their bookings" ON pandit_booknow
    FOR SELECT USING (auth.uid()::text = pandit_id);

-- Pandits can update bookings made to them
CREATE POLICY "Pandits can update their bookings" ON pandit_booknow
    FOR UPDATE USING (auth.uid()::text = pandit_id);

-- Sample data structure for details JSONB field:
-- {
--   "name": "John Doe",
--   "puja_details": "I would like to book a Ganesh Puja for my new house",
--   "booking_date": "2024-01-15T10:30:00Z",
--   "status": "pending", // pending, accepted, rejected, completed
--   "notes": "Please call me for more details",
--   "preferred_date": "2024-01-20",
--   "preferred_time": "morning",
--   "contact_phone": "+1234567890"
-- }
