-- ============================================
-- INITIALIZE USER CREDITS FROM BACKEND
-- This script removes the auto-trigger and creates a backend function
-- to initialize credits when user first accesses the screen
-- ============================================

BEGIN;

-- ============================================
-- 1. Remove the old trigger-based initialization
-- ============================================
DROP TRIGGER IF EXISTS initialize_user_credits_trigger ON user_ai_usage;
DROP FUNCTION IF EXISTS initialize_user_credits();

-- ============================================
-- 2. Create function to initialize user credits (called from backend/app)
-- ============================================
CREATE OR REPLACE FUNCTION initialize_user_credits_on_access(p_user_id UUID)
RETURNS TABLE (
    user_id UUID,
    free_credits_left INTEGER,
    topup_credits INTEGER,
    credits_consumed INTEGER,
    total_credits INTEGER
) AS $$
DECLARE
    v_usage_record RECORD;
    v_default_free_credits INTEGER := 11; -- Default free credits for new users
BEGIN
    -- Check if user_ai_usage record exists
    SELECT * INTO v_usage_record
    FROM user_ai_usage
    WHERE user_id = p_user_id
    LIMIT 1;

    -- If record doesn't exist, create it with default credits
    IF v_usage_record IS NULL THEN
        INSERT INTO user_ai_usage (
            user_id,
            free_credits_left,
            topup_credits,
            credits_consumed,
            accessed_count,
            accessed_problems,
            chat_history,
            chat_question,
            plan_details,
            created_at,
            updated_at
        ) VALUES (
            p_user_id,
            v_default_free_credits, -- Set 11 free credits
            0,                       -- No topup credits initially
            0,                       -- No credits consumed yet
            0,                       -- No problems accessed yet
            '[]'::jsonb,            -- Empty accessed problems array
            '[]'::jsonb,            -- Empty chat history
            '[]'::jsonb,            -- Empty chat questions
            '{}'::jsonb,            -- Empty plan details
            NOW(),
            NOW()
        )
        RETURNING * INTO v_usage_record;
    -- If record exists but has no credits (both free and topup are 0), initialize with default credits
    ELSIF v_usage_record.free_credits_left = 0 AND v_usage_record.topup_credits = 0 THEN
        UPDATE user_ai_usage
        SET 
            free_credits_left = v_default_free_credits,
            updated_at = NOW()
        WHERE user_id = p_user_id
        RETURNING * INTO v_usage_record;
    END IF;

    -- Return the updated record
    RETURN QUERY
    SELECT 
        v_usage_record.user_id,
        v_usage_record.free_credits_left,
        v_usage_record.topup_credits,
        v_usage_record.credits_consumed,
        (v_usage_record.free_credits_left + v_usage_record.topup_credits) AS total_credits;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 3. Grant execute permission to authenticated users
-- ============================================
GRANT EXECUTE ON FUNCTION initialize_user_credits_on_access(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION initialize_user_credits_on_access(UUID) TO anon;

-- ============================================
-- 4. Add comment for documentation
-- ============================================
COMMENT ON FUNCTION initialize_user_credits_on_access(UUID) IS 
'Initializes user credits when user first accesses the Mantra Generator screen. 
Gives 11 free credits to new users. Can be called safely multiple times - only initializes if credits are 0.';

COMMIT;

-- ============================================
-- USAGE EXAMPLE
-- ============================================
-- Call this function from your app when user accesses the Mantra Generator screen:
-- SELECT * FROM initialize_user_credits_on_access('user-uuid-here');

-- ============================================
-- VERIFICATION QUERIES
-- ============================================
-- Check if function exists:
-- SELECT proname, prosrc FROM pg_proc WHERE proname = 'initialize_user_credits_on_access';

-- Test the function (replace with actual user_id):
-- SELECT * FROM initialize_user_credits_on_access('00000000-0000-0000-0000-000000000000'::UUID);
