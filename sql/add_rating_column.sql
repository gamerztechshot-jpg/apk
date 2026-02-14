-- Add rating column to astrologers table
-- This script adds a rating column to store actual ratings from users

ALTER TABLE astrologers 
ADD COLUMN IF NOT EXISTS rating DECIMAL(3,2) CHECK (rating >= 0 AND rating <= 5);

-- Add a comment to describe the column
COMMENT ON COLUMN astrologers.rating IS 'User rating for the astrologer (0.0 to 5.0)';

-- Example: Update some existing records with sample ratings
-- UPDATE astrologers SET rating = 4.8 WHERE name = 'Pandit Sharma';
-- UPDATE astrologers SET rating = 4.6 WHERE name = 'Jyoti Kumari';
-- UPDATE astrologers SET rating = 4.9 WHERE name = 'Acharya Iyer';
