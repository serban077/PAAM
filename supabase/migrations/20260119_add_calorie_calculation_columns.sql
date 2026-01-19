-- Ensure user_profiles has all required columns for calorie calculation
-- Run this in Supabase SQL Editor

-- Add missing columns if they don't exist
ALTER TABLE user_profiles 
ADD COLUMN IF NOT EXISTS height_cm NUMERIC,
ADD COLUMN IF NOT EXISTS age INTEGER,
ADD COLUMN IF NOT EXISTS gender TEXT,
ADD COLUMN IF NOT EXISTS weekly_training_frequency INTEGER DEFAULT 3,
ADD COLUMN IF NOT EXISTS daily_calorie_goal INTEGER,
ADD COLUMN IF NOT EXISTS protein_goal_g NUMERIC,
ADD COLUMN IF NOT EXISTS carbs_goal_g NUMERIC,
ADD COLUMN IF NOT EXISTS fat_goal_g NUMERIC;

-- Add comments
COMMENT ON COLUMN user_profiles.height_cm IS 'User height in centimeters for BMR calculation';
COMMENT ON COLUMN user_profiles.age IS 'User age for BMR calculation';
COMMENT ON COLUMN user_profiles.gender IS 'User gender (masculin/feminin) for BMR calculation';
COMMENT ON COLUMN user_profiles.weekly_training_frequency IS 'Number of training days per week (0-7) for TDEE calculation';
COMMENT ON COLUMN user_profiles.daily_calorie_goal IS 'Calculated daily calorie target based on goal';
COMMENT ON COLUMN user_profiles.protein_goal_g IS 'Daily protein target in grams';
COMMENT ON COLUMN user_profiles.carbs_goal_g IS 'Daily carbohydrates target in grams';
COMMENT ON COLUMN user_profiles.fat_goal_g IS 'Daily fat target in grams';

-- Verify columns exist
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'user_profiles'
AND column_name IN ('height_cm', 'age', 'gender', 'weekly_training_frequency', 
                     'daily_calorie_goal', 'protein_goal_g', 'carbs_goal_g', 'fat_goal_g')
ORDER BY column_name;
