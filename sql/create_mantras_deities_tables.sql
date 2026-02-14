-- ============================================
-- MANTRA & DEITY TABLES - Production Schema
-- Run this in Supabase SQL Editor
-- ============================================

-- ============================================
-- 1. DEITIES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.deities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    english_name VARCHAR(255) NOT NULL,
    hindi_name VARCHAR(255) NOT NULL,
    icon TEXT NOT NULL,
    description_en TEXT NOT NULL,
    description_hi TEXT NOT NULL,
    colors JSONB DEFAULT '[]'::jsonb NOT NULL,
    image_url TEXT,
    is_active BOOLEAN DEFAULT true NOT NULL,
    is_custom BOOLEAN DEFAULT false NOT NULL,
    display_order INTEGER DEFAULT 0 NOT NULL,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 2. MANTRAS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.mantras (
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

-- ============================================
-- 3. INDEXES FOR PERFORMANCE
-- ============================================
CREATE INDEX IF NOT EXISTS idx_deities_is_active 
    ON public.deities(is_active);
CREATE INDEX IF NOT EXISTS idx_deities_display_order 
    ON public.deities(display_order);
CREATE INDEX IF NOT EXISTS idx_deities_english_name 
    ON public.deities(english_name);

CREATE INDEX IF NOT EXISTS idx_mantras_deity_id 
    ON public.mantras(deity_id);
CREATE INDEX IF NOT EXISTS idx_mantras_category 
    ON public.mantras(category);
CREATE INDEX IF NOT EXISTS idx_mantras_is_active 
    ON public.mantras(is_active);
CREATE INDEX IF NOT EXISTS idx_mantras_difficulty_level 
    ON public.mantras(difficulty_level);
CREATE INDEX IF NOT EXISTS idx_mantras_display_order 
    ON public.mantras(display_order);

-- ============================================
-- 4. RLS POLICIES (Row Level Security)
-- ============================================
ALTER TABLE public.deities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mantras ENABLE ROW LEVEL SECURITY;

-- Everyone can read active deities
CREATE POLICY "Anyone can view active deities" 
    ON public.deities
    FOR SELECT 
    USING (is_active = true);

-- Everyone can read active mantras
CREATE POLICY "Anyone can view active mantras" 
    ON public.mantras
    FOR SELECT 
    USING (is_active = true);

-- Authenticated users can insert/update/delete (for admin panel)
CREATE POLICY "Authenticated users can insert deities" 
    ON public.deities
    FOR INSERT 
    TO authenticated
    WITH CHECK (true);

CREATE POLICY "Authenticated users can update deities" 
    ON public.deities
    FOR UPDATE 
    TO authenticated
    USING (true);

CREATE POLICY "Authenticated users can delete deities" 
    ON public.deities
    FOR DELETE 
    TO authenticated
    USING (true);

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

-- ============================================
-- 5. AUTO-UPDATE TIMESTAMP TRIGGERS
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_deities_updated_at ON public.deities;
CREATE TRIGGER update_deities_updated_at 
    BEFORE UPDATE ON public.deities
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_mantras_updated_at ON public.mantras;
CREATE TRIGGER update_mantras_updated_at 
    BEFORE UPDATE ON public.mantras
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 6. HELPER FUNCTIONS (Optional - for better queries)
-- ============================================

-- Function to get mantras by deity with details
CREATE OR REPLACE FUNCTION get_mantras_by_deity(deity_uuid UUID)
RETURNS TABLE (
    id UUID,
    mantra_en TEXT,
    mantra_hi TEXT,
    meaning_en TEXT,
    meaning_hi TEXT,
    benefits_en TEXT,
    benefits_hi TEXT,
    category VARCHAR,
    difficulty_level VARCHAR,
    deity_name TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        m.id,
        m.mantra_en,
        m.mantra_hi,
        m.meaning_en,
        m.meaning_hi,
        m.benefits_en,
        m.benefits_hi,
        m.category,
        m.difficulty_level,
        d.english_name as deity_name
    FROM public.mantras m
    LEFT JOIN public.deities d ON m.deity_id = d.id
    WHERE m.deity_id = deity_uuid
      AND m.is_active = true
    ORDER BY m.display_order, m.created_at;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- SUCCESS MESSAGE
-- ============================================
DO $$
BEGIN
    RAISE NOTICE '✅ Tables created successfully!';
    RAISE NOTICE '✅ Indexes created successfully!';
    RAISE NOTICE '✅ RLS policies enabled successfully!';
    RAISE NOTICE '✅ Triggers created successfully!';
    RAISE NOTICE '';
    RAISE NOTICE '📝 Next step: Add deities and mantras via admin panel';
END $$;
