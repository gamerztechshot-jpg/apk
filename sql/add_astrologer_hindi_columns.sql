-- Add Hindi translation columns to astrologers table
-- Safe to run multiple times (uses IF NOT EXISTS)

ALTER TABLE astrologers
  ADD COLUMN IF NOT EXISTS name_hi VARCHAR(255),
  ADD COLUMN IF NOT EXISTS email_hi VARCHAR(255),
  ADD COLUMN IF NOT EXISTS phone_number_hi VARCHAR(20),
  ADD COLUMN IF NOT EXISTS qualification_hi TEXT,
  ADD COLUMN IF NOT EXISTS experience_hi TEXT,
  ADD COLUMN IF NOT EXISTS about_you_hi TEXT,
  ADD COLUMN IF NOT EXISTS address_hi TEXT,
  ADD COLUMN IF NOT EXISTS photo_url_hi TEXT;

COMMENT ON COLUMN astrologers.name_hi IS 'Hindi translation of name';
COMMENT ON COLUMN astrologers.email_hi IS 'Hindi translation of email (usually unused)';
COMMENT ON COLUMN astrologers.phone_number_hi IS 'Hindi translation of phone number (usually unused)';
COMMENT ON COLUMN astrologers.qualification_hi IS 'Hindi translation of qualification';
COMMENT ON COLUMN astrologers.experience_hi IS 'Hindi translation of experience display text (optional)';
COMMENT ON COLUMN astrologers.about_you_hi IS 'Hindi translation of about_you';
COMMENT ON COLUMN astrologers.address_hi IS 'Hindi translation of address';
COMMENT ON COLUMN astrologers.photo_url_hi IS 'Hindi translation of photo_url (usually unused)';

