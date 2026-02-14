-- Trigger to populate Hindi data when astrologer is approved (is_active becomes true)
-- This acts as a fallback/auto-fill if Hindi data wasn't explicitly provided during approval.

CREATE OR REPLACE FUNCTION on_astrologer_approve()
RETURNS TRIGGER AS $$
BEGIN
    -- Check if is_active changed to true
    IF (NEW.is_active = true AND (OLD.is_active = false OR OLD.is_active IS NULL)) THEN
        
        -- Populate name_hi if null
        IF NEW.name_hi IS NULL OR NEW.name_hi = '' THEN
            NEW.name_hi := NEW.name;
        END IF;

        -- Populate qualification_hi if null
        IF NEW.qualification_hi IS NULL OR NEW.qualification_hi = '' THEN
            NEW.qualification_hi := NEW.qualification;
        END IF;

        -- Populate about_you_hi if null
        IF NEW.about_you_hi IS NULL OR NEW.about_you_hi = '' THEN
            NEW.about_you_hi := NEW.about_you;
        END IF;

        -- Populate address_hi if null
        IF NEW.address_hi IS NULL OR NEW.address_hi = '' THEN
            NEW.address_hi := NEW.address;
        END IF;

    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop trigger if exists to avoid duplication errors during development
DROP TRIGGER IF EXISTS trigger_on_astrologer_approve ON astrologers;

CREATE TRIGGER trigger_on_astrologer_approve
    BEFORE UPDATE ON astrologers
    FOR EACH ROW
    EXECUTE FUNCTION on_astrologer_approve();
