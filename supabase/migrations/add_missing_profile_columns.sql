-- Migration: Add missing columns to user_profiles table
-- Based on existing schema structure
-- Run this in Supabase SQL Editor

-- Add missing columns that the app needs
ALTER TABLE public.user_profiles 
ADD COLUMN IF NOT EXISTS workout_frequency INTEGER DEFAULT 3 
  CHECK (workout_frequency >= 1 AND workout_frequency <= 7),
ADD COLUMN IF NOT EXISTS session_duration INTEGER DEFAULT 60 
  CHECK (session_duration >= 30 AND session_duration <= 180),
ADD COLUMN IF NOT EXISTS workout_reminders BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS progress_updates BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS motivational_messages BOOLEAN DEFAULT true;

-- Add comments for documentation
COMMENT ON COLUMN user_profiles.workout_frequency IS 'Number of workout days per week (1-7)';
COMMENT ON COLUMN user_profiles.session_duration IS 'Workout session duration in minutes (30-180)';
COMMENT ON COLUMN user_profiles.workout_reminders IS 'Enable workout reminder notifications';
COMMENT ON COLUMN user_profiles.progress_updates IS 'Enable progress update notifications';
COMMENT ON COLUMN user_profiles.motivational_messages IS 'Enable motivational message notifications';

-- Sync weekly_training_frequency with workout_frequency for existing users
UPDATE user_profiles 
SET weekly_training_frequency = COALESCE(workout_frequency, 3)
WHERE weekly_training_frequency IS NULL;

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_user_profiles_workout_frequency 
ON user_profiles(workout_frequency);

-- Verify the migration
SELECT 
  column_name, 
  data_type, 
  column_default,
  is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'user_profiles' 
  AND column_name IN (
    'age', 'height_cm', 'weight_kg', 'activity_level', 
    'equipment_available', 'weekly_training_frequency', 
    'available_training_hours_per_session', 'workout_frequency', 
    'session_duration', 'workout_reminders', 'progress_updates', 
    'motivational_messages'
  )
ORDER BY ordinal_position;
