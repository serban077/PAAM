-- Check if user profile exists and create if missing
-- Run this in Supabase SQL Editor

-- Step 1: Check current user ID
SELECT auth.uid() as current_user_id;

-- Step 2: Check if profile exists (without auth filter)
SELECT id, email, weight_kg, daily_calorie_goal
FROM user_profiles
LIMIT 5;

-- Step 3: If no profile exists for current user, create one
INSERT INTO user_profiles (
    id,
    email,
    age,
    weight_kg,
    height_cm,
    weekly_training_frequency,
    daily_calorie_goal,
    protein_goal_g,
    carbs_goal_g,
    fat_goal_g,
    target_weight_kg,
    target_timeframe_weeks
)
SELECT 
    auth.uid(),
    auth.email(),
    30, -- default age
    80, -- default weight (schimbă cu greutatea ta)
    175, -- default height (schimbă cu înălțimea ta)
    3, -- default training frequency
    2038, -- default calories (va fi recalculat)
    176, -- default protein
    255, -- default carbs
    57, -- default fat
    75, -- target weight (schimbă cu greutatea țintă)
    12 -- target timeframe weeks
WHERE NOT EXISTS (
    SELECT 1 FROM user_profiles WHERE id = auth.uid()
);

-- Step 4: Verify profile was created
SELECT 
    id,
    email,
    weight_kg,
    daily_calorie_goal,
    target_weight_kg,
    target_timeframe_weeks
FROM user_profiles
WHERE id = auth.uid();
