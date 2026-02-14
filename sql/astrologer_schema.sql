-- Astrologer Database Schema with Real Ratings and Reviews
-- This file contains the SQL schema for astrologer functionality with real rating system

-- Create astrologers table
CREATE TABLE IF NOT EXISTS astrologers (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    name_hi VARCHAR(255),
    email VARCHAR(255) UNIQUE NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    qualification TEXT NOT NULL,
    qualification_hi TEXT,
    experience INTEGER NOT NULL, -- in months
    about_you TEXT NOT NULL,
    about_you_hi TEXT,
    address TEXT NOT NULL,
    address_hi TEXT,
    photo_url TEXT,
    per_minute_charge DECIMAL(10,2) DEFAULT 0.00,
    per_hour_charge DECIMAL(10,2) DEFAULT 0.00,
    per_month_charge DECIMAL(10,2) DEFAULT 0.00,
    is_active BOOLEAN DEFAULT TRUE,
    priority DECIMAL(3,2) DEFAULT 0.00, -- For sorting/ranking
    specializations TEXT[], -- Array of specializations
    languages TEXT[], -- Array of languages spoken
    availability_schedule JSONB, -- Store availability as JSON
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create astrologer_reviews table for real ratings
CREATE TABLE IF NOT EXISTS astrologer_reviews (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    astrologer_id UUID NOT NULL REFERENCES astrologers(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review_text TEXT,
    consultation_type VARCHAR(50), -- 'video_call', 'phone_call', 'chat', 'in_person'
    consultation_duration INTEGER, -- in minutes
    is_verified BOOLEAN DEFAULT FALSE, -- Verified consultation
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(astrologer_id, user_id) -- One review per user per astrologer
);

-- Create astrologer_bookings table
CREATE TABLE IF NOT EXISTS astrologer_bookings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    astrologer_id UUID NOT NULL REFERENCES astrologers(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    consultation_type VARCHAR(50) NOT NULL, -- 'video_call', 'phone_call', 'chat', 'in_person'
    scheduled_time TIMESTAMP WITH TIME ZONE NOT NULL,
    duration_minutes INTEGER DEFAULT 60,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'completed', 'cancelled', 'no_show')),
    notes TEXT,
    total_amount DECIMAL(10,2),
    payment_status VARCHAR(20) DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'refunded')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create astrologer_availability table
CREATE TABLE IF NOT EXISTS astrologer_availability (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    astrologer_id UUID NOT NULL REFERENCES astrologers(id) ON DELETE CASCADE,
    day_of_week INTEGER NOT NULL CHECK (day_of_week >= 0 AND day_of_week <= 6), -- 0=Sunday, 1=Monday, etc.
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    is_available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for better performance
CREATE INDEX IF NOT EXISTS idx_astrologers_is_active ON astrologers(is_active);
CREATE INDEX IF NOT EXISTS idx_astrologers_priority ON astrologers(priority DESC);
CREATE INDEX IF NOT EXISTS idx_astrologers_experience ON astrologers(experience DESC);
CREATE INDEX IF NOT EXISTS idx_astrologers_per_minute_charge ON astrologers(per_minute_charge);

CREATE INDEX IF NOT EXISTS idx_astrologer_reviews_astrologer_id ON astrologer_reviews(astrologer_id);
CREATE INDEX IF NOT EXISTS idx_astrologer_reviews_user_id ON astrologer_reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_astrologer_reviews_rating ON astrologer_reviews(rating);
CREATE INDEX IF NOT EXISTS idx_astrologer_reviews_created_at ON astrologer_reviews(created_at);

CREATE INDEX IF NOT EXISTS idx_astrologer_bookings_astrologer_id ON astrologer_bookings(astrologer_id);
CREATE INDEX IF NOT EXISTS idx_astrologer_bookings_user_id ON astrologer_bookings(user_id);
CREATE INDEX IF NOT EXISTS idx_astrologer_bookings_status ON astrologer_bookings(status);
CREATE INDEX IF NOT EXISTS idx_astrologer_bookings_scheduled_time ON astrologer_bookings(scheduled_time);

CREATE INDEX IF NOT EXISTS idx_astrologer_availability_astrologer_id ON astrologer_availability(astrologer_id);
CREATE INDEX IF NOT EXISTS idx_astrologer_availability_day ON astrologer_availability(day_of_week);

-- Enable Row Level Security (RLS)
ALTER TABLE astrologers ENABLE ROW LEVEL SECURITY;
ALTER TABLE astrologer_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE astrologer_bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE astrologer_availability ENABLE ROW LEVEL SECURITY;

-- RLS Policies for astrologers
CREATE POLICY "Anyone can view active astrologers" ON astrologers
    FOR SELECT USING (is_active = true);

CREATE POLICY "Admin can manage astrologers" ON astrologers
    FOR ALL USING (auth.role() = 'admin') WITH CHECK (auth.role() = 'admin');

-- RLS Policies for astrologer_reviews
CREATE POLICY "Anyone can view astrologer reviews" ON astrologer_reviews
    FOR SELECT USING (true);

CREATE POLICY "Users can insert their own reviews" ON astrologer_reviews
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own reviews" ON astrologer_reviews
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own reviews" ON astrologer_reviews
    FOR DELETE USING (auth.uid() = user_id);

-- RLS Policies for astrologer_bookings
CREATE POLICY "Users can view their own bookings" ON astrologer_bookings
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own bookings" ON astrologer_bookings
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own bookings" ON astrologer_bookings
    FOR UPDATE USING (auth.uid() = user_id);

-- RLS Policies for astrologer_availability
CREATE POLICY "Anyone can view astrologer availability" ON astrologer_availability
    FOR SELECT USING (true);

CREATE POLICY "Admin can manage astrologer availability" ON astrologer_availability
    FOR ALL USING (auth.role() = 'admin') WITH CHECK (auth.role() = 'admin');

-- Triggers for updating updated_at timestamp
CREATE TRIGGER update_astrologers_updated_at BEFORE UPDATE ON astrologers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_astrologer_reviews_updated_at BEFORE UPDATE ON astrologer_reviews
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_astrologer_bookings_updated_at BEFORE UPDATE ON astrologer_bookings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_astrologer_availability_updated_at BEFORE UPDATE ON astrologer_availability
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to calculate average rating for an astrologer
CREATE OR REPLACE FUNCTION get_astrologer_avg_rating(astrologer_uuid UUID)
RETURNS DECIMAL(3,2)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    avg_rating DECIMAL(3,2);
BEGIN
    SELECT COALESCE(AVG(rating), 0) INTO avg_rating
    FROM astrologer_reviews
    WHERE astrologer_id = astrologer_uuid;
    
    RETURN ROUND(avg_rating, 2);
END;
$$;

-- Function to get total reviews count for an astrologer
CREATE OR REPLACE FUNCTION get_astrologer_reviews_count(astrologer_uuid UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    reviews_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO reviews_count
    FROM astrologer_reviews
    WHERE astrologer_id = astrologer_uuid;
    
    RETURN reviews_count;
END;
$$;

-- View for astrologers with calculated ratings
CREATE OR REPLACE VIEW astrologers_with_ratings AS
SELECT 
    a.*,
    COALESCE(get_astrologer_avg_rating(a.id), 0) as average_rating,
    get_astrologer_reviews_count(a.id) as total_reviews,
    CASE 
        WHEN a.per_minute_charge > 0 THEN '₹' || a.per_minute_charge || '/min'
        WHEN a.per_hour_charge > 0 THEN '₹' || a.per_hour_charge || '/hr'
        WHEN a.per_month_charge > 0 THEN '₹' || a.per_month_charge || '/month'
        ELSE 'Contact for price'
    END as display_price
FROM astrologers a
WHERE a.is_active = true;

-- Grant permissions
GRANT SELECT ON astrologers_with_ratings TO authenticated;
GRANT SELECT ON astrologer_reviews TO authenticated;
GRANT SELECT ON astrologer_bookings TO authenticated;
GRANT SELECT ON astrologer_availability TO authenticated;
