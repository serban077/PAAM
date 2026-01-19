-- Migration: Fix gender enum values and workout plan generation
-- Timestamp: 2026-01-17 18:21:01

-- Step 1: Add Romanian gender values to enum
ALTER TYPE public.gender ADD VALUE IF NOT EXISTS 'barbat';
ALTER TYPE public.gender ADD VALUE IF NOT EXISTS 'femeie';
ALTER TYPE public.gender ADD VALUE IF NOT EXISTS 'altul';

-- Step 2: Fix generate_workout_plan function to handle nulls and generate proper plan names
CREATE OR REPLACE FUNCTION public.generate_workout_plan(user_profile_id uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
    new_plan_id UUID;
    user_goal public.fitness_goal;
    user_frequency INTEGER;
    user_equipment public.equipment_type;
    user_level public.experience_level;
    user_conditions TEXT;
    plan_name TEXT;
BEGIN
    -- Get user profile data
    SELECT 
        fitness_goal, 
        weekly_training_frequency, 
        equipment_available, 
        experience_level,
        medical_conditions
    INTO 
        user_goal, 
        user_frequency, 
        user_equipment, 
        user_level,
        user_conditions
    FROM public.user_profiles
    WHERE id = user_profile_id;

    -- Validate required fields
    IF user_goal IS NULL THEN
        RAISE EXCEPTION 'fitness_goal cannot be null for user %', user_profile_id;
    END IF;

    IF user_frequency IS NULL THEN
        RAISE EXCEPTION 'weekly_training_frequency cannot be null for user %', user_profile_id;
    END IF;

    -- Generate plan name based on goal (Romanian labels)
    plan_name := CASE user_goal
        WHEN 'pierdere_greutate' THEN 'Plan Pierdere Greutate'
        WHEN 'crestere_masa_musculara' THEN 'Plan Creștere Masă Musculară'
        WHEN 'tonifiere' THEN 'Plan Tonifiere'
        WHEN 'mentinere' THEN 'Plan Menținere Formă'
        ELSE 'Plan Personalizat'
    END;

    -- Deactivate existing plans
    UPDATE public.workout_plans
    SET is_active = false
    WHERE user_id = user_profile_id AND is_active = true;

    -- Create new workout plan with validated data
    INSERT INTO public.workout_plans (user_id, plan_name, fitness_goal, weekly_frequency)
    VALUES (user_profile_id, plan_name, user_goal, user_frequency)
    RETURNING id INTO new_plan_id;

    -- Generate workout sessions based on frequency
    IF user_frequency >= 3 THEN
        INSERT INTO public.workout_sessions (plan_id, day_of_week, session_name, focus_area, estimated_duration_minutes)
        VALUES
            (new_plan_id, 1, 'Ziua 1: Corp Superior', 'piept, spate, umeri', 60),
            (new_plan_id, 3, 'Ziua 2: Corp Inferior', 'picioare, fesieri', 60),
            (new_plan_id, 5, 'Ziua 3: Complet & Core', 'tot corpul, abdomen', 60);
    END IF;

    IF user_frequency >= 4 THEN
        INSERT INTO public.workout_sessions (plan_id, day_of_week, session_name, focus_area, estimated_duration_minutes)
        VALUES (new_plan_id, 2, 'Ziua 4: Cardio & Tonifiere', 'cardio, core', 45);
    END IF;

    IF user_frequency >= 5 THEN
        INSERT INTO public.workout_sessions (plan_id, day_of_week, session_name, focus_area, estimated_duration_minutes)
        VALUES (new_plan_id, 4, 'Ziua 5: Brațe & Umeri', 'biceps, triceps, deltoizi', 50);
    END IF;

    IF user_frequency >= 6 THEN
        INSERT INTO public.workout_sessions (plan_id, day_of_week, session_name, focus_area, estimated_duration_minutes)
        VALUES (new_plan_id, 6, 'Ziua 6: Recuperare Activă', 'stretching, yoga', 30);
    END IF;

    RETURN new_plan_id;
END;
$function$;