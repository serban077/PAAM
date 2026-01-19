-- Location: supabase/migrations/20260117175554_fix_fitness_enums_and_workout_system.sql
-- Schema Analysis: Existing user_profiles table with mismatched fitness_goal enum values
-- Integration Type: Modificative - Fix enum values and add missing fields for workout system
-- Dependencies: user_profiles, onboarding_responses

-- Step 1: Fix fitness_goal enum to match Romanian values from widget
ALTER TYPE public.fitness_goal RENAME TO fitness_goal_old;

CREATE TYPE public.fitness_goal AS ENUM (
    'pierdere_greutate',
    'crestere_masa_musculara',
    'mentinere',
    'tonifiere'
);

-- Update user_profiles to use new enum (with data migration)
ALTER TABLE public.user_profiles 
    ALTER COLUMN fitness_goal DROP DEFAULT;

ALTER TABLE public.user_profiles 
    ALTER COLUMN fitness_goal TYPE public.fitness_goal 
    USING CASE 
        WHEN fitness_goal::TEXT = 'weight_loss' THEN 'pierdere_greutate'::public.fitness_goal
        WHEN fitness_goal::TEXT = 'muscle_gain' THEN 'crestere_masa_musculara'::public.fitness_goal
        WHEN fitness_goal::TEXT = 'endurance' THEN 'mentinere'::public.fitness_goal
        WHEN fitness_goal::TEXT = 'flexibility' THEN 'tonifiere'::public.fitness_goal
        WHEN fitness_goal::TEXT = 'general_fitness' THEN 'mentinere'::public.fitness_goal
        ELSE 'mentinere'::public.fitness_goal
    END;

DROP TYPE public.fitness_goal_old;

-- Step 2: Add missing fields for workout planning
ALTER TABLE public.user_profiles
ADD COLUMN IF NOT EXISTS weekly_training_frequency INTEGER CHECK (weekly_training_frequency BETWEEN 1 AND 7),
ADD COLUMN IF NOT EXISTS available_training_hours_per_session NUMERIC(4,2) CHECK (available_training_hours_per_session > 0 AND available_training_hours_per_session <= 5);

-- Step 3: Create workout plans table
CREATE TABLE IF NOT EXISTS public.workout_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    plan_name TEXT NOT NULL,
    fitness_goal public.fitness_goal NOT NULL,
    weekly_frequency INTEGER NOT NULL,
    duration_weeks INTEGER DEFAULT 12,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true
);

CREATE INDEX IF NOT EXISTS idx_workout_plans_user_id ON public.workout_plans(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_plans_active ON public.workout_plans(user_id, is_active);

-- Step 4: Create workout sessions table
CREATE TABLE IF NOT EXISTS public.workout_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id UUID REFERENCES public.workout_plans(id) ON DELETE CASCADE,
    day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 1 AND 7),
    session_name TEXT NOT NULL,
    focus_area TEXT NOT NULL,
    estimated_duration_minutes INTEGER NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_workout_sessions_plan_id ON public.workout_sessions(plan_id);

-- Step 5: Create exercises table
CREATE TABLE IF NOT EXISTS public.exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    target_muscle_groups TEXT[] NOT NULL,
    equipment_required public.equipment_type NOT NULL,
    difficulty_level public.experience_level NOT NULL,
    video_url TEXT,
    is_safe_for_conditions TEXT[],
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_exercises_equipment ON public.exercises(equipment_required);
CREATE INDEX IF NOT EXISTS idx_exercises_difficulty ON public.exercises(difficulty_level);

-- Step 6: Create session exercises junction table
CREATE TABLE IF NOT EXISTS public.session_exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID REFERENCES public.workout_sessions(id) ON DELETE CASCADE,
    exercise_id UUID REFERENCES public.exercises(id) ON DELETE CASCADE,
    sets INTEGER NOT NULL DEFAULT 3,
    reps_min INTEGER NOT NULL,
    reps_max INTEGER NOT NULL,
    rest_seconds INTEGER NOT NULL DEFAULT 60,
    order_in_session INTEGER NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_session_exercises_session_id ON public.session_exercises(session_id);
CREATE INDEX IF NOT EXISTS idx_session_exercises_exercise_id ON public.session_exercises(exercise_id);

-- Step 7: Enable RLS for new tables
ALTER TABLE public.workout_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.session_exercises ENABLE ROW LEVEL SECURITY;

-- Step 8: Create RLS policies
CREATE POLICY "users_manage_own_workout_plans"
ON public.workout_plans
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_view_own_workout_sessions"
ON public.workout_sessions
FOR SELECT
TO authenticated
USING (
    plan_id IN (
        SELECT id FROM public.workout_plans WHERE user_id = auth.uid()
    )
);

CREATE POLICY "public_read_exercises"
ON public.exercises
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "users_view_own_session_exercises"
ON public.session_exercises
FOR SELECT
TO authenticated
USING (
    session_id IN (
        SELECT ws.id FROM public.workout_sessions ws
        JOIN public.workout_plans wp ON ws.plan_id = wp.id
        WHERE wp.user_id = auth.uid()
    )
);

-- Step 9: Create function for caloric budget calculation
CREATE OR REPLACE FUNCTION public.calculate_daily_calories(
    user_profile_id UUID
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_age INTEGER;
    user_gender public.gender;
    user_weight NUMERIC;
    user_height NUMERIC;
    user_activity public.activity_level;
    user_goal public.fitness_goal;
    bmr NUMERIC;
    tdee NUMERIC;
    calorie_adjustment NUMERIC;
    final_calories INTEGER;
BEGIN
    -- Get user profile data
    SELECT age, gender, current_weight_kg, height_cm, activity_level, fitness_goal
    INTO user_age, user_gender, user_weight, user_height, user_activity, user_goal
    FROM public.user_profiles
    WHERE id = user_profile_id;

    -- Calculate BMR using Mifflin-St Jeor equation
    IF user_gender = 'male' THEN
        bmr := (10 * user_weight) + (6.25 * user_height) - (5 * user_age) + 5;
    ELSIF user_gender = 'female' THEN
        bmr := (10 * user_weight) + (6.25 * user_height) - (5 * user_age) - 161;
    ELSE
        -- Default to average for other genders
        bmr := (10 * user_weight) + (6.25 * user_height) - (5 * user_age) - 78;
    END IF;

    -- Calculate TDEE based on activity level
    CASE user_activity
        WHEN 'sedentar' THEN tdee := bmr * 1.2;
        WHEN 'usor_activ' THEN tdee := bmr * 1.375;
        WHEN 'moderat_activ' THEN tdee := bmr * 1.55;
        WHEN 'foarte_activ' THEN tdee := bmr * 1.725;
        WHEN 'extrem_activ' THEN tdee := bmr * 1.9;
        ELSE tdee := bmr * 1.55;
    END CASE;

    -- Adjust calories based on fitness goal
    CASE user_goal
        WHEN 'pierdere_greutate' THEN calorie_adjustment := -500;
        WHEN 'crestere_masa_musculara' THEN calorie_adjustment := 300;
        WHEN 'tonifiere' THEN calorie_adjustment := -200;
        WHEN 'mentinere' THEN calorie_adjustment := 0;
        ELSE calorie_adjustment := 0;
    END CASE;

    final_calories := ROUND(tdee + calorie_adjustment);

    -- Update user profile with calculated calories
    UPDATE public.user_profiles
    SET daily_calorie_goal = final_calories,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = user_profile_id;

    RETURN final_calories;
END;
$$;

-- Step 10: Create function for generating personalized workout plan
CREATE OR REPLACE FUNCTION public.generate_workout_plan(
    user_profile_id UUID
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
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

    -- Generate plan name based on goal
    plan_name := CASE user_goal
        WHEN 'pierdere_greutate' THEN 'Plan Pierdere Greutate'
        WHEN 'crestere_masa_musculara' THEN 'Plan Creștere Masă Musculară'
        WHEN 'tonifiere' THEN 'Plan Tonifiere'
        WHEN 'mentinere' THEN 'Plan Menținere Formă'
    END;

    -- Deactivate existing plans
    UPDATE public.workout_plans
    SET is_active = false
    WHERE user_id = user_profile_id AND is_active = true;

    -- Create new workout plan
    INSERT INTO public.workout_plans (user_id, plan_name, fitness_goal, weekly_frequency)
    VALUES (user_profile_id, plan_name, user_goal, user_frequency)
    RETURNING id INTO new_plan_id;

    -- Generate workout sessions based on frequency
    IF user_frequency >= 3 THEN
        -- Full body split for 3+ days
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

    RETURN new_plan_id;
END;
$$;

-- Step 11: Insert sample exercises for each equipment type and difficulty level
DO $$
DECLARE
    pushup_id UUID := gen_random_uuid();
    squat_id UUID := gen_random_uuid();
    plank_id UUID := gen_random_uuid();
    lunges_id UUID := gen_random_uuid();
    burpees_id UUID := gen_random_uuid();
BEGIN
    INSERT INTO public.exercises (id, name, description, target_muscle_groups, equipment_required, difficulty_level, is_safe_for_conditions, video_url)
    VALUES
        (pushup_id, 'Flotări', 'Exercițiu clasic pentru piept și brațe', ARRAY['piept', 'triceps', 'umeri'], 'acasa_fara_echipament'::public.equipment_type, 'beginner'::public.experience_level, ARRAY['generale'], 'https://example.com/pushups'),
        (squat_id, 'Genuflexiuni', 'Exercițiu fundamental pentru picioare', ARRAY['cvadriceps', 'fesieri', 'ischiogambieri'], 'acasa_fara_echipament'::public.equipment_type, 'beginner'::public.experience_level, ARRAY['generale'], 'https://example.com/squats'),
        (plank_id, 'Plank', 'Exercițiu izometric pentru abdomen', ARRAY['abdomen', 'core', 'spate'], 'acasa_fara_echipament'::public.equipment_type, 'beginner'::public.experience_level, ARRAY['generale', 'probleme spate'], 'https://example.com/plank'),
        (lunges_id, 'Fandări', 'Exercițiu unilateral pentru picioare', ARRAY['cvadriceps', 'fesieri', 'echilibru'], 'acasa_fara_echipament'::public.equipment_type, 'intermediate'::public.experience_level, ARRAY['generale'], 'https://example.com/lunges'),
        (burpees_id, 'Burpees', 'Exercițiu cardio complet', ARRAY['tot corpul', 'cardio', 'rezistenta'], 'acasa_fara_echipament'::public.equipment_type, 'advanced'::public.experience_level, ARRAY['generale'], 'https://example.com/burpees');
END $$;

-- Step 12: Update handle_new_user trigger to calculate calories on profile creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Insert user profile with trigger data
    INSERT INTO public.user_profiles (
        id, 
        email, 
        full_name, 
        age,
        gender,
        height_cm,
        current_weight_kg,
        target_weight_kg,
        fitness_goal,
        activity_level,
        equipment_available,
        dietary_preference,
        experience_level,
        medical_conditions,
        weekly_training_frequency,
        available_training_hours_per_session,
        avatar_url
    )
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        COALESCE((NEW.raw_user_meta_data->>'age')::INTEGER, NULL),
        COALESCE((NEW.raw_user_meta_data->>'gender')::public.gender, NULL),
        COALESCE((NEW.raw_user_meta_data->>'height_cm')::NUMERIC, NULL),
        COALESCE((NEW.raw_user_meta_data->>'current_weight_kg')::NUMERIC, NULL),
        COALESCE((NEW.raw_user_meta_data->>'target_weight_kg')::NUMERIC, NULL),
        COALESCE((NEW.raw_user_meta_data->>'fitness_goal')::public.fitness_goal, NULL),
        COALESCE((NEW.raw_user_meta_data->>'activity_level')::public.activity_level, 'moderat_activ'::public.activity_level),
        COALESCE((NEW.raw_user_meta_data->>'equipment_available')::public.equipment_type, 'sala_fitness'::public.equipment_type),
        COALESCE((NEW.raw_user_meta_data->>'dietary_preference')::public.dietary_preference, 'normal'::public.dietary_preference),
        COALESCE((NEW.raw_user_meta_data->>'experience_level')::public.experience_level, NULL),
        COALESCE(NEW.raw_user_meta_data->>'medical_conditions', NULL),
        COALESCE((NEW.raw_user_meta_data->>'weekly_training_frequency')::INTEGER, NULL),
        COALESCE((NEW.raw_user_meta_data->>'available_training_hours_per_session')::NUMERIC, NULL),
        COALESCE(NEW.raw_user_meta_data->>'avatar_url', '')
    );
    
    RETURN NEW;
END;
$$;

-- Recreate trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();