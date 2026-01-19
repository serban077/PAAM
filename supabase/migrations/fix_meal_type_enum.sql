-- Fix meal_type enum to include all required values
-- This fixes the error: invalid input value for enum meal_type: "snack"

-- First, check current enum values
SELECT enumlabel 
FROM pg_enum 
WHERE enumtypid = 'meal_type'::regtype
ORDER BY enumsortorder;

-- Add missing enum values if they don't exist
DO $$ 
BEGIN
    -- Add 'snack' if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM pg_enum 
        WHERE enumlabel = 'snack' 
        AND enumtypid = 'meal_type'::regtype
    ) THEN
        ALTER TYPE meal_type ADD VALUE 'snack';
    END IF;
    
    -- Add 'gustare' as alternative if needed
    IF NOT EXISTS (
        SELECT 1 FROM pg_enum 
        WHERE enumlabel = 'gustare' 
        AND enumtypid = 'meal_type'::regtype
    ) THEN
        ALTER TYPE meal_type ADD VALUE 'gustare';
    END IF;
END $$;

-- Verify the enum now has all values
SELECT enumlabel 
FROM pg_enum 
WHERE enumtypid = 'meal_type'::regtype
ORDER BY enumsortorder;

-- Expected values should include:
-- mic_dejun
-- pranz
-- cina
-- snack (or gustare)
