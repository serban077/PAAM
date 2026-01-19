-- Query to check AI meals and their food data
-- Run this in Supabase SQL Editor to debug

-- Check recent user_meals with food_database join
SELECT 
    um.id as meal_id,
    um.meal_type,
    um.serving_quantity,
    um.consumed_at,
    um.notes,
    fd.id as food_id,
    fd.name as food_name,
    fd.serving_size,
    fd.serving_unit,
    fd.calories,
    fd.protein_g,
    fd.carbs_g,
    fd.fat_g,
    fd.is_verified
FROM user_meals um
LEFT JOIN food_database fd ON um.food_id = fd.id
WHERE um.user_id = auth.uid()
AND um.consumed_at >= CURRENT_DATE
ORDER BY um.consumed_at DESC
LIMIT 20;

-- Check if AI-generated foods exist
SELECT 
    id,
    name,
    serving_size,
    serving_unit,
    calories,
    protein_g,
    carbs_g,
    fat_g,
    is_verified,
    created_at
FROM food_database
WHERE name LIKE 'Plan AI%'
ORDER BY created_at DESC
LIMIT 10;
