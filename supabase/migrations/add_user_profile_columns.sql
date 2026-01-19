-- Migration: Add missing columns to user_profiles table
-- This migration adds all necessary columns for the SmartFit AI application
-- Run this in Supabase SQL Editor

-- Add columns if they don't exist
ALTER TABLE user_profiles 
ADD COLUMN IF NOT EXISTS age INTEGER,
ADD COLUMN IF NOT EXISTS weight_kg DECIMAL(5,2),
ADD COLUMN IF NOT EXISTS height_cm DECIMAL(5,2),
ADD COLUMN IF NOT EXISTS activity_level TEXT DEFAULT 'Moderat Activ',
ADD COLUMN IF NOT EXISTS workout_frequency INTEGER DEFAULT 3,
ADD COLUMN IF NOT EXISTS session_duration INTEGER DEFAULT 60,
ADD COLUMN IF NOT EXISTS equipment_available TEXT,
ADD COLUMN IF NOT EXISTS fitness_goal TEXT DEFAULT 'Recompunere corporală',
ADD COLUMN IF NOT EXISTS weekly_training_frequency INTEGER DEFAULT 3,
ADD COLUMN IF NOT EXISTS workout_reminders BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS progress_updates BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS motivational_messages BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS experience_level TEXT DEFAULT 'Începător',
ADD COLUMN IF NOT EXISTS medical_conditions TEXT,
ADD COLUMN IF NOT EXISTS dietary_preference TEXT DEFAULT 'normal',
ADD COLUMN IF NOT EXISTS gender TEXT,
ADD COLUMN IF NOT EXISTS full_name TEXT,
ADD COLUMN IF NOT EXISTS email TEXT;

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_user_profiles_weekly_frequency 
ON user_profiles(weekly_training_frequency);

-- Add comments for documentation
COMMENT ON COLUMN user_profiles.age IS 'User age in years';
COMMENT ON COLUMN user_profiles.weight_kg IS 'User weight in kilograms';
COMMENT ON COLUMN user_profiles.height_cm IS 'User height in centimeters';
COMMENT ON COLUMN user_profiles.activity_level IS 'User activity level (Sedentar, Ușor Activ, Moderat Activ, Foarte Activ, Extrem de Activ)';
COMMENT ON COLUMN user_profiles.workout_frequency IS 'Number of workout days per week';
COMMENT ON COLUMN user_profiles.session_duration IS 'Workout session duration in minutes';
COMMENT ON COLUMN user_profiles.equipment_available IS 'Comma-separated list of available equipment';
COMMENT ON COLUMN user_profiles.fitness_goal IS 'User fitness goal (Pierdere în greutate, Creștere musculară, Rezistență, Recompunere corporală)';
COMMENT ON COLUMN user_profiles.weekly_training_frequency IS 'Weekly training frequency for AI plan generation (synced with workout_frequency)';
COMMENT ON COLUMN user_profiles.workout_reminders IS 'Enable workout reminder notifications';
COMMENT ON COLUMN user_profiles.progress_updates IS 'Enable progress update notifications';
COMMENT ON COLUMN user_profiles.motivational_messages IS 'Enable motivational message notifications';
COMMENT ON COLUMN user_profiles.experience_level IS 'User fitness experience level (Începător, Intermediar, Avansat)';
COMMENT ON COLUMN user_profiles.medical_conditions IS 'User medical conditions or restrictions';
COMMENT ON COLUMN user_profiles.dietary_preference IS 'User dietary preference (normal, vegetarian, vegan, etc.)';

-- Verify the migration
SELECT column_name, data_type, column_default 
FROM information_schema.columns 
WHERE table_name = 'user_profiles' 
ORDER BY ordinal_position;
