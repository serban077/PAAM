-- Debug query to check user profile calorie goal
-- Run this in Supabase SQL Editor

SELECT 
    id,
    weight_kg,
    target_weight_kg,
    target_timeframe_weeks,
    weekly_training_frequency,
    fitness_goal,
    daily_calorie_goal,
    protein_goal_g,
    carbs_goal_g,
    fat_goal_g
FROM user_profiles
WHERE id = auth.uid();
