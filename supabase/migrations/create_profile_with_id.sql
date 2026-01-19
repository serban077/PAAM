-- Create user profile using email to find user ID
-- Run this in Supabase SQL Editor

-- Step 1: Find your user ID by email
SELECT id, email 
FROM auth.users 
LIMIT 5;

-- Step 2: Copy your user ID from above and paste it below
-- Replace 'YOUR_USER_ID_HERE' with your actual ID

-- Step 3: Create profile with your user ID
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
VALUES (
    'YOUR_USER_ID_HERE'::uuid,  -- REPLACE THIS with your ID from Step 1
    'your.email@example.com',    -- REPLACE with your email
    30,   -- age (schimbă cu vârsta ta)
    80,   -- weight_kg (greutatea ta actuală)
    175,  -- height_cm (înălțimea ta)
    4,    -- weekly_training_frequency (zile antrenament/săptămână)
    2038, -- daily_calorie_goal (va fi recalculat automat)
    176,  -- protein_goal_g
    255,  -- carbs_goal_g
    57,   -- fat_goal_g
    75,   -- target_weight_kg (greutatea țintă)
    12    -- target_timeframe_weeks (săptămâni)
)
ON CONFLICT (id) DO NOTHING;

-- Step 4: Verify profile was created
SELECT 
    id,
    email,
    weight_kg,
    daily_calorie_goal,
    target_weight_kg,
    target_timeframe_weeks
FROM user_profiles
WHERE email = 'your.email@example.com';  -- REPLACE with your email
