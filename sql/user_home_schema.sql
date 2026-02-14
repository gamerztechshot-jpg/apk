-- User Home Configuration Table
-- This table stores the dynamic content boxes configuration for the home screen
-- Uses JSONB columns for flexible content structure

CREATE TABLE IF NOT EXISTS user_home (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    image TEXT, -- Optional header image
    box1 JSONB, -- Box 1 configuration: {"type": "ebook", "ref_id": "uuid", "title": "Title", "description": "Description", "image": "url"}
    box2 JSONB, -- Box 2 configuration
    box3 JSONB, -- Box 3 configuration
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_user_home_created_at ON user_home(created_at);

-- Insert sample data for testing
INSERT INTO user_home (
    image,
    box1,
    box2,
    box3
) VALUES (
    'https://example.com/header-image.jpg',
    '{"type": "ebook", "ref_id": "00000000-0000-0000-0000-000000000001", "title": "Bhagavad Gita", "description": "The sacred Hindu scripture with 700 verses", "image": "https://example.com/bhagavad-gita.jpg"}',
    '{"type": "store_item", "ref_id": "00000000-0000-0000-0000-000000000002", "title": "Puja Samagri", "description": "Essential items for daily worship", "image": "https://example.com/puja-samagri.jpg"}',
    '{"type": "puja", "ref_id": "00000000-0000-0000-0000-000000000003", "title": "Ganesh Puja", "description": "Book online Ganesh Puja for prosperity", "image": "https://example.com/ganesh-puja.jpg"}'
) ON CONFLICT DO NOTHING;
