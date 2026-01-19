-- Create profile for serban.07@yahoo.com
-- Run this in Supabase SQL Editor

-- Step 1: Find user ID and create profile in one go
DO $$
DECLARE
    v_user_id uuid;
BEGIN
    -- Get user ID from email
    SELECT id INTO v_user_id
    FROM auth.users
    WHERE email = 'serban.07@yahoo.com';
    
    -- Check if user exists
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User with email serban.07@yahoo.com not found';
    END IF;
    
    -- Create profile
    INSERT INTO user_profiles (
        id,
        email,
        full_name,
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
        v_user_id,
        'serban.07@yahoo.com',
        'Serban',  -- full_name (schimbă cu numele tău)
        30,   -- age (schimbă dacă vrei)
        80,   -- weight_kg (greutatea ta actuală)
        175,  -- height_cm (înălțimea ta)
        4,    -- weekly_training_frequency (zile antrenament/săptămână)
        2038, -- daily_calorie_goal (calculat pentru 80kg -> 75kg în 12 săptămâni)
        176,  -- protein_goal_g
        255,  -- carbs_goal_g
        57,   -- fat_goal_g
        75,   -- target_weight_kg (greutatea țintă)
        12    -- target_timeframe_weeks (săptămâni)
    )
    ON CONFLICT (id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        weight_kg = EXCLUDED.weight_kg,
        height_cm = EXCLUDED.height_cm,
        daily_calorie_goal = EXCLUDED.daily_calorie_goal,
        protein_goal_g = EXCLUDED.protein_goal_g,
        carbs_goal_g = EXCLUDED.carbs_goal_g,
        fat_goal_g = EXCLUDED.fat_goal_g,
        target_weight_kg = EXCLUDED.target_weight_kg,
        target_timeframe_weeks = EXCLUDED.target_timeframe_weeks;
    
    RAISE NOTICE 'Profile created/updated for user: %', v_user_id;
END $$;

-- Step 2: Verify profile was created
SELECT 
    id,
    email,
    age,
    weight_kg,
    height_cm,
    daily_calorie_goal,
    target_weight_kg,
    target_timeframe_weeks
FROM user_profiles
WHERE email = 'serban.07@yahoo.com';
