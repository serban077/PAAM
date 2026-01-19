-- Add target_timeframe_weeks column to user_profiles
-- This enables deadline-based calorie calculation

ALTER TABLE user_profiles 
ADD COLUMN IF NOT EXISTS target_timeframe_weeks INTEGER;

COMMENT ON COLUMN user_profiles.target_timeframe_weeks IS 'Timeframe to reach target weight (in weeks)';

-- Verify columns exist
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'user_profiles'
AND column_name IN ('target_weight_kg', 'target_timeframe_weeks')
ORDER BY column_name;
