-- ============================================
-- MIGRATION: Add Missing Columns to Existing mantras Table
-- Run this in Supabase SQL Editor
-- ============================================

-- Step 1: Check if table exists and add missing columns
DO $$ 
BEGIN
    -- Add deity_id column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'mantras' 
        AND column_name = 'deity_id'
    ) THEN
        ALTER TABLE public.mantras 
        ADD COLUMN deity_id UUID REFERENCES public.deities(id) ON DELETE SET NULL;
        RAISE NOTICE '✅ Added deity_id column';
    END IF;

    -- Add is_active column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'mantras' 
        AND column_name = 'is_active'
    ) THEN
        ALTER TABLE public.mantras 
        ADD COLUMN is_active BOOLEAN NOT NULL DEFAULT true;
        RAISE NOTICE '✅ Added is_active column';
    END IF;

    -- Add is_custom column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'mantras' 
        AND column_name = 'is_custom'
    ) THEN
        ALTER TABLE public.mantras 
        ADD COLUMN is_custom BOOLEAN NOT NULL DEFAULT false;
        RAISE NOTICE '✅ Added is_custom column';
    END IF;

    -- Add display_order column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'mantras' 
        AND column_name = 'display_order'
    ) THEN
        ALTER TABLE public.mantras 
        ADD COLUMN display_order INTEGER NOT NULL DEFAULT 0;
        RAISE NOTICE '✅ Added display_order column';
    END IF;

    -- Add created_by column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'mantras' 
        AND column_name = 'created_by'
    ) THEN
        ALTER TABLE public.mantras 
        ADD COLUMN created_by UUID REFERENCES auth.users(id);
        RAISE NOTICE '✅ Added created_by column';
    END IF;

    -- Add updated_at column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'mantras' 
        AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE public.mantras 
        ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE '✅ Added updated_at column';
    END IF;

    RAISE NOTICE '✅ Migration completed successfully!';
END $$;

-- Step 2: Create indexes if they don't exist
CREATE INDEX IF NOT EXISTS idx_mantras_deity_id 
    ON public.mantras(deity_id);
CREATE INDEX IF NOT EXISTS idx_mantras_is_active 
    ON public.mantras(is_active);
CREATE INDEX IF NOT EXISTS idx_mantras_display_order 
    ON public.mantras(display_order);

-- Step 3: Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Anyone can view active mantras" ON public.mantras;
DROP POLICY IF EXISTS "Authenticated users can insert mantras" ON public.mantras;
DROP POLICY IF EXISTS "Authenticated users can update mantras" ON public.mantras;
DROP POLICY IF EXISTS "Authenticated users can delete mantras" ON public.mantras;

-- Step 4: Enable RLS and create policies
ALTER TABLE public.mantras ENABLE ROW LEVEL SECURITY;

-- Everyone can read active mantras
CREATE POLICY "Anyone can view active mantras" 
    ON public.mantras
    FOR SELECT 
    USING (is_active = true);

-- Authenticated users can insert/update/delete
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

-- Step 5: Create/Update trigger for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_mantras_updated_at ON public.mantras;
CREATE TRIGGER update_mantras_updated_at 
    BEFORE UPDATE ON public.mantras
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Success message
DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ Mantras table migration completed!';
    RAISE NOTICE '✅ All missing columns added!';
    RAISE NOTICE '✅ Indexes created!';
    RAISE NOTICE '✅ RLS policies enabled!';
    RAISE NOTICE '========================================';
END $$;
























































































































