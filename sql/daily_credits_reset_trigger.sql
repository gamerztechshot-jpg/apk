BEGIN;

-- =====================================================
-- 1. DROP EXISTING FUNCTION
-- =====================================================
DROP FUNCTION IF EXISTS reset_daily_free_credits();

-- =====================================================
-- 2. CREATE DAILY FREE CREDITS RESET FUNCTION
-- =====================================================
CREATE FUNCTION reset_daily_free_credits()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_updated_count INTEGER;
BEGIN
  UPDATE user_ai_usage u
  SET
    free_credits_left = 11,
    updated_at = NOW()
  WHERE
    -- Only users with TOTAL credits = 0
    (u.free_credits_left + u.topup_credits) = 0

    -- Never topped up
    AND u.topup_credits = 0

    -- No chatbot package
    AND NOT EXISTS (
      SELECT 1
      FROM user_payments p
      WHERE p.user_id::uuid = u.user_id
      AND p.payment_status = 'success'
    )

    -- No pandit package
    AND NOT EXISTS (
      SELECT 1
      FROM pandit_package_orders o
      WHERE o.user_id = u.user_id
      AND o.status = 'success'
    );

  GET DIAGNOSTICS v_updated_count = ROW_COUNT;
  RETURN v_updated_count;
END;
$$;

-- =====================================================
-- 3. GRANT PERMISSIONS
-- =====================================================
GRANT EXECUTE ON FUNCTION reset_daily_free_credits() TO service_role;
GRANT EXECUTE ON FUNCTION reset_daily_free_credits() TO authenticated;

-- =====================================================
-- 4. REMOVE OLD CRON JOB (SAFE)
-- =====================================================
SELECT cron.unschedule('daily-free-credits-reset')
WHERE EXISTS (
  SELECT 1 FROM cron.job WHERE jobname = 'daily-free-credits-reset'
);

-- =====================================================
-- 5. CREATE DAILY CRON JOB (MIDNIGHT IST)
-- 18:30 UTC = 12:00 AM IST
-- =====================================================
SELECT cron.schedule(
  'daily-free-credits-reset',
  '30 18 * * *',
  $$SELECT reset_daily_free_credits();$$
);

COMMIT;
