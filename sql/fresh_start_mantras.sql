-- ============================================
-- FRESH START: Drop and Recreate mantras Table
-- ⚠️ WARNING: This will DELETE ALL existing mantras data!
-- Only use this if you want to start fresh
-- ============================================

-- Step 1: Drop existing policies and triggers
DROP POLICY IF EXISTS "Anyone can view active mantras" ON public.mantras;
DROP POLICY IF EXISTS "Authenticated users can insert mantras" ON public.mantras;
DROP POLICY IF EXISTS "Authenticated users can update mantras" ON public.mantras;
DROP POLICY IF EXISTS "Authenticated users can delete mantras" ON public.mantras;
DROP TRIGGER IF EXISTS update_mantras_updated_at ON public.mantras;

-- Step 2: Drop the table (this deletes all data!)
DROP TABLE IF EXISTS public.mantras CASCADE;

-- Step 3: Create fresh mantras table
CREATE TABLE public.mantras (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mantra_en TEXT NOT NULL,
    mantra_hi TEXT NOT NULL DEFAULT '',
    meaning_en TEXT NOT NULL DEFAULT '',
    meaning_hi TEXT NOT NULL DEFAULT '',
    benefits_en TEXT NOT NULL DEFAULT '',
    benefits_hi TEXT NOT NULL DEFAULT '',
    deity_id UUID REFERENCES public.deities(id) ON DELETE SET NULL,
    category VARCHAR(100) NOT NULL DEFAULT 'General',
    difficulty_level VARCHAR(20) NOT NULL DEFAULT 'easy' 
        CHECK (difficulty_level IN ('easy', 'medium', 'difficult')),
    is_active BOOLEAN NOT NULL DEFAULT true,
    is_custom BOOLEAN NOT NULL DEFAULT false,
    display_order INTEGER NOT NULL DEFAULT 0,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 4: Create indexes
CREATE INDEX idx_mantras_deity_id ON public.mantras(deity_id);
CREATE INDEX idx_mantras_category ON public.mantras(category);
CREATE INDEX idx_mantras_is_active ON public.mantras(is_active);
CREATE INDEX idx_mantras_difficulty_level ON public.mantras(difficulty_level);
CREATE INDEX idx_mantras_display_order ON public.mantras(display_order);

-- Step 5: Enable RLS and create policies
ALTER TABLE public.mantras ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view active mantras" 
    ON public.mantras
    FOR SELECT 
    USING (is_active = true);

CREATE POLICY "Authenticated users can insert mantras" 
    ON public.mantras
    FOR INSERT 
    TO authenticated
    WITH CHECK (true);

CREATE POLICY "Authenticated users can update mantras" 
    ON public.mantras
    FOR UPDATE 
    TO authenticated
    USING (true);

CREATE POLICY "Authenticated users can delete mantras" 
    ON public.mantras
    FOR DELETE 
    TO authenticated
    USING (true);

-- Step 6: Create trigger for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_mantras_updated_at 
    BEFORE UPDATE ON public.mantras
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Success message
DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ Fresh mantras table created!';
    RAISE NOTICE '✅ Ready to add data!';
    RAISE NOTICE '========================================';
END $$;
