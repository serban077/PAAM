-- Force update daily nutrition goals for today
-- Run this in Supabase SQL Editor

-- Step 1: Check current daily_nutrition_goals
SELECT * FROM daily_nutrition_goals
WHERE user_id = (SELECT id FROM auth.users WHERE email = 'serban.07@yahoo.com')
ORDER BY date DESC
LIMIT 5;

-- Step 2: Delete today's goal to force recreation
DELETE FROM daily_nutrition_goals
WHERE user_id = (SELECT id FROM auth.users WHERE email = 'serban.07@yahoo.com')
AND date = CURRENT_DATE;

-- Step 3: Verify user_profiles has correct calorie_goal
SELECT 
    id,
    email,
    daily_calorie_goal,
    protein_goal_g,
    carbs_goal_g,
    fat_goal_g
FROM user_profiles
WHERE email = 'serban.07@yahoo.com';

-- Step 4: After running this, restart the app and go to Nutrition screen
-- It will automatically create a new daily_nutrition_goals entry with correct values
