-- ============================================
-- MANTRA GENERATOR SCHEMA IMPROVEMENTS
-- Run this script in Supabase SQL Editor
-- Date: 2026-01-27
-- ============================================

BEGIN;

-- ============================================
-- 1. Add accessed_problems column
-- ============================================
ALTER TABLE user_ai_usage 
ADD COLUMN IF NOT EXISTS accessed_problems JSONB DEFAULT '[]'::jsonb;

COMMENT ON COLUMN user_ai_usage.accessed_problems IS 
'Array of problem IDs (main_problems.id or sub_problems.id) that user has accessed. Format: ["uuid-1", "uuid-2"]. Prevents duplicate credit deduction.';

-- ============================================
-- 2. Add updated_at columns
-- ============================================
ALTER TABLE chatbot_packages 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE main_problems 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE sub_problems 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE user_ai_usage 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE user_payments 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- ============================================
-- 3. Create auto-update trigger function
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- ============================================
-- 4. Create triggers for updated_at
-- ============================================
DROP TRIGGER IF EXISTS update_chatbot_packages_updated_at ON chatbot_packages;
CREATE TRIGGER update_chatbot_packages_updated_at 
BEFORE UPDATE ON chatbot_packages 
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_main_problems_updated_at ON main_problems;
CREATE TRIGGER update_main_problems_updated_at 
BEFORE UPDATE ON main_problems 
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_sub_problems_updated_at ON sub_problems;
CREATE TRIGGER update_sub_problems_updated_at 
BEFORE UPDATE ON sub_problems 
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_user_ai_usage_updated_at ON user_ai_usage;
CREATE TRIGGER update_user_ai_usage_updated_at 
BEFORE UPDATE ON user_ai_usage 
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_user_payments_updated_at ON user_payments;
CREATE TRIGGER update_user_payments_updated_at 
BEFORE UPDATE ON user_payments 
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 5. Create indexes for performance
-- ============================================

-- user_ai_usage indexes (most critical)
CREATE INDEX IF NOT EXISTS idx_user_ai_usage_user_id ON user_ai_usage(user_id);
CREATE INDEX IF NOT EXISTS idx_user_ai_usage_created_at ON user_ai_usage(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_ai_usage_accessed_problems 
ON user_ai_usage USING GIN (accessed_problems);
CREATE INDEX IF NOT EXISTS idx_user_ai_usage_chat_history 
ON user_ai_usage USING GIN (chat_history);

-- user_payments indexes
CREATE INDEX IF NOT EXISTS idx_user_payments_user_id ON user_payments(user_id);
CREATE INDEX IF NOT EXISTS idx_user_payments_package_id ON user_payments(package_id);
CREATE INDEX IF NOT EXISTS idx_user_payments_payment_status ON user_payments(payment_status);
CREATE INDEX IF NOT EXISTS idx_user_payments_created_at ON user_payments(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_payments_user_status 
ON user_payments(user_id, payment_status) 
WHERE payment_status = 'success';

-- chatbot_packages indexes
CREATE INDEX IF NOT EXISTS idx_chatbot_packages_is_active ON chatbot_packages(is_active);
CREATE INDEX IF NOT EXISTS idx_chatbot_packages_package_type ON chatbot_packages(package_type);
CREATE INDEX IF NOT EXISTS idx_chatbot_packages_content_access 
ON chatbot_packages USING GIN (content_access);

-- main_problems indexes
CREATE INDEX IF NOT EXISTS idx_main_problems_is_active ON main_problems(is_active);
CREATE INDEX IF NOT EXISTS idx_main_problems_display_order ON main_problems(display_order);
CREATE INDEX IF NOT EXISTS idx_main_problems_is_paid ON main_problems(is_paid);

-- sub_problems indexes
CREATE INDEX IF NOT EXISTS idx_sub_problems_main_problem_id ON sub_problems(main_problem_id);
CREATE INDEX IF NOT EXISTS idx_sub_problems_is_active ON sub_problems(is_active);
CREATE INDEX IF NOT EXISTS idx_sub_problems_is_paid ON sub_problems(is_paid);

-- ============================================
-- 6. Add foreign key constraints
-- ============================================
ALTER TABLE sub_problems 
DROP CONSTRAINT IF EXISTS fk_sub_problems_main_problem;
ALTER TABLE sub_problems 
ADD CONSTRAINT fk_sub_problems_main_problem 
FOREIGN KEY (main_problem_id) 
REFERENCES main_problems(id) 
ON DELETE CASCADE;

ALTER TABLE user_payments 
DROP CONSTRAINT IF EXISTS fk_user_payments_package;
ALTER TABLE user_payments 
ADD CONSTRAINT fk_user_payments_package 
FOREIGN KEY (package_id) 
REFERENCES chatbot_packages(id) 
ON DELETE RESTRICT;

-- ============================================
-- 7. Add check constraints
-- ============================================
ALTER TABLE chatbot_packages 
DROP CONSTRAINT IF EXISTS chk_package_type;
ALTER TABLE chatbot_packages 
ADD CONSTRAINT chk_package_type 
CHECK (package_type IN ('starter', 'premium', 'ultimate'));

ALTER TABLE user_payments 
DROP CONSTRAINT IF EXISTS chk_payment_status;
ALTER TABLE user_payments 
ADD CONSTRAINT chk_payment_status 
CHECK (payment_status IN ('success', 'failed', 'pending'));

ALTER TABLE main_problems 
DROP CONSTRAINT IF EXISTS chk_main_problems_credit_cost;
ALTER TABLE main_problems 
ADD CONSTRAINT chk_main_problems_credit_cost 
CHECK (credit_cost >= 0);

ALTER TABLE sub_problems 
DROP CONSTRAINT IF EXISTS chk_sub_problems_credit_cost;
ALTER TABLE sub_problems 
ADD CONSTRAINT chk_sub_problems_credit_cost 
CHECK (credit_cost >= 0);

ALTER TABLE user_ai_usage 
DROP CONSTRAINT IF EXISTS chk_user_ai_usage_credits;
ALTER TABLE user_ai_usage 
ADD CONSTRAINT chk_user_ai_usage_credits 
CHECK (
    free_credits_left >= 0 AND 
    topup_credits >= 0 AND 
    credits_consumed >= 0
);

ALTER TABLE chatbot_packages 
DROP CONSTRAINT IF EXISTS chk_ai_question_limit;
ALTER TABLE chatbot_packages 
ADD CONSTRAINT chk_ai_question_limit 
CHECK (ai_question_limit >= 0);

-- ============================================
-- 8. Create function to initialize user credits
-- ============================================
CREATE OR REPLACE FUNCTION initialize_user_credits()
RETURNS TRIGGER AS $$
BEGIN
    -- Set default 11 free credits for new users
    IF NEW.free_credits_left = 0 AND NEW.topup_credits = 0 THEN
        NEW.free_credits_left := 11;
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger
DROP TRIGGER IF EXISTS initialize_user_credits_trigger ON user_ai_usage;
CREATE TRIGGER initialize_user_credits_trigger
BEFORE INSERT ON user_ai_usage
FOR EACH ROW
EXECUTE FUNCTION initialize_user_credits();

COMMIT;

-- ============================================
-- VERIFICATION QUERIES
-- Run these after migration to verify
-- ============================================

-- Verify accessed_problems column added
-- SELECT column_name, data_type, column_default 
-- FROM information_schema.columns 
-- WHERE table_name = 'user_ai_usage' 
-- AND column_name = 'accessed_problems';

-- Verify updated_at columns added
-- SELECT table_name, column_name, data_type 
-- FROM information_schema.columns 
-- WHERE table_name IN ('chatbot_packages', 'main_problems', 'sub_problems', 'user_ai_usage', 'user_payments')
-- AND column_name = 'updated_at'
-- ORDER BY table_name;

-- Verify indexes created
-- SELECT indexname, indexdef 
-- FROM pg_indexes 
-- WHERE tablename IN ('user_ai_usage', 'user_payments', 'chatbot_packages', 'main_problems', 'sub_problems')
-- ORDER BY tablename, indexname;

-- Verify constraints
-- SELECT conname, contype, pg_get_constraintdef(oid) 
-- FROM pg_constraint 
-- WHERE conrelid IN (
--     'user_ai_usage'::regclass,
--     'user_payments'::regclass,
--     'chatbot_packages'::regclass,
--     'main_problems'::regclass,
--     'sub_problems'::regclass
-- )
-- ORDER BY conrelid, conname;

-- Verify trigger function exists
-- SELECT proname, prosrc 
-- FROM pg_proc 
-- WHERE proname IN ('update_updated_at_column', 'initialize_user_credits');

-- Verify triggers exist
-- SELECT tgname, tgrelid::regclass, tgenabled 
-- FROM pg_trigger 
-- WHERE tgname LIKE '%updated_at%' OR tgname LIKE '%credits%';
