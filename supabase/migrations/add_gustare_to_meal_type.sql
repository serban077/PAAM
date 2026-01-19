-- Add missing 'gustare' value to meal_type enum
-- Run this in Supabase SQL Editor

-- First, check if 'gustare' already exists
DO $$ 
BEGIN
    -- Try to add 'gustare' if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM pg_enum 
        WHERE enumlabel = 'gustare' 
        AND enumtypid = 'meal_type'::regtype
    ) THEN
        ALTER TYPE meal_type ADD VALUE 'gustare';
        RAISE NOTICE 'Added gustare to meal_type enum';
    ELSE
        RAISE NOTICE 'gustare already exists in meal_type enum';
    END IF;
END $$;

-- Verify all values
SELECT enumlabel as meal_type_values
FROM pg_enum 
WHERE enumtypid = 'meal_type'::regtype
ORDER BY enumsortorder;
