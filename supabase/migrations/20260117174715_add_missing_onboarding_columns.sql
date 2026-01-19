-- Location: supabase/migrations/20260117174715_add_missing_onboarding_columns.sql
-- Schema Analysis: Existing user_profiles table missing onboarding fields
-- Integration Type: MODIFICATIVE - Extending existing user_profiles table
-- Dependencies: user_profiles table (existing), needs activity_level, equipment_type, dietary_preference ENUMs

-- ============================================================================
-- STEP 1: CREATE MISSING ENUM TYPES (if they don't exist)
-- ============================================================================

DO $$ BEGIN
    CREATE TYPE public.activity_level AS ENUM ('sedentar', 'usor_activ', 'moderat_activ', 'foarte_activ', 'extrem_activ');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE public.equipment_type AS ENUM ('acasa_fara_echipament', 'acasa_cu_echipament_basic', 'sala_fitness', 'mix');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE public.dietary_preference AS ENUM ('normal', 'vegetarian', 'vegan', 'fara_gluten', 'fara_lactate');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- ============================================================================
-- STEP 2: ADD MISSING COLUMNS TO user_profiles TABLE
-- ============================================================================

-- Add age column (integer)
ALTER TABLE public.user_profiles 
ADD COLUMN IF NOT EXISTS age INTEGER;

-- Add activity_level column (enum)
ALTER TABLE public.user_profiles 
ADD COLUMN IF NOT EXISTS activity_level public.activity_level DEFAULT 'moderat_activ'::public.activity_level;

-- Add current_weight_kg column (decimal)
ALTER TABLE public.user_profiles 
ADD COLUMN IF NOT EXISTS current_weight_kg DECIMAL(5,2);

-- Add equipment_available column (enum)
ALTER TABLE public.user_profiles 
ADD COLUMN IF NOT EXISTS equipment_available public.equipment_type DEFAULT 'sala_fitness'::public.equipment_type;

-- Add dietary_preference column (enum)  
ALTER TABLE public.user_profiles 
ADD COLUMN IF NOT EXISTS dietary_preference public.dietary_preference DEFAULT 'normal'::public.dietary_preference;

-- Add medical_conditions column (text)
ALTER TABLE public.user_profiles 
ADD COLUMN IF NOT EXISTS medical_conditions TEXT;

-- Add daily_calorie_goal column (integer) for nutrition tracking
ALTER TABLE public.user_profiles 
ADD COLUMN IF NOT EXISTS daily_calorie_goal INTEGER;

-- ============================================================================
-- STEP 3: CREATE onboarding_responses TABLE (if missing)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.onboarding_responses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    step_number INTEGER NOT NULL,
    question_key TEXT NOT NULL,
    answer_value TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- STEP 4: ADD INDEXES FOR PERFORMANCE
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_onboarding_user_id 
ON public.onboarding_responses(user_id);

-- ============================================================================
-- STEP 5: ENABLE RLS ON onboarding_responses (if not already enabled)
-- ============================================================================

ALTER TABLE public.onboarding_responses ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- STEP 6: CREATE RLS POLICY FOR onboarding_responses
-- ============================================================================

DROP POLICY IF EXISTS "users_manage_own_onboarding" ON public.onboarding_responses;

CREATE POLICY "users_manage_own_onboarding"
ON public.onboarding_responses
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- ============================================================================
-- STEP 7: CREATE FUNCTION TO RECOMMEND WORKOUTS BASED ON MEDICAL CONDITIONS
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_safe_workout_plans(user_uuid UUID)
RETURNS TABLE(
    plan_id UUID,
    plan_title TEXT,
    category_name TEXT,
    difficulty TEXT,
    is_recommended BOOLEAN,
    recommendation_reason TEXT
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
DECLARE
    user_medical_conditions TEXT;
    user_fitness_goal TEXT;
    user_equipment TEXT;
    user_activity TEXT;
BEGIN
    -- Get user profile data
    SELECT 
        LOWER(COALESCE(up.medical_conditions, '')),
        COALESCE(up.fitness_goal::TEXT, 'mentinere'),
        COALESCE(up.equipment_available::TEXT, 'sala_fitness'),
        COALESCE(up.activity_level::TEXT, 'moderat_activ')
    INTO 
        user_medical_conditions,
        user_fitness_goal,
        user_equipment,
        user_activity
    FROM public.user_profiles up
    WHERE up.id = user_uuid;

    -- Return workout plans with medical condition awareness
    RETURN QUERY
    SELECT 
        wp.id AS plan_id,
        wp.title AS plan_title,
        wc.name AS category_name,
        wp.difficulty::TEXT AS difficulty,
        CASE
            -- Recommend based on equipment match
            WHEN wp.equipment_needed::TEXT = user_equipment THEN true
            WHEN user_equipment = 'mix' THEN true
            -- Avoid high-impact if medical conditions exist
            WHEN user_medical_conditions LIKE '%genunchi%' AND wc.type_enum = 'picioare' THEN false
            WHEN user_medical_conditions LIKE '%spate%' AND wc.type_enum IN ('spate', 'picioare') THEN false
            WHEN user_medical_conditions LIKE '%diabet%' AND wp.difficulty = 'avansat' THEN false
            WHEN user_medical_conditions LIKE '%inima%' AND wc.type_enum = 'cardio' THEN false
            ELSE true
        END AS is_recommended,
        CASE
            WHEN user_medical_conditions LIKE '%genunchi%' AND wc.type_enum = 'picioare' THEN 
                'Atenție: Acest program include exerciții pentru picioare. Consultați medicul.'
            WHEN user_medical_conditions LIKE '%spate%' AND wc.type_enum IN ('spate', 'picioare') THEN 
                'Atenție: Acest program poate solicita zona spatelui. Consultați medicul.'
            WHEN user_medical_conditions LIKE '%diabet%' AND wp.difficulty = 'avansat' THEN 
                'Program avansat - monitorizați glicemia înainte și după antrenament.'
            WHEN user_medical_conditions LIKE '%inima%' AND wc.type_enum = 'cardio' THEN 
                'Consultați cardiologul înainte de a începe acest program.'
            WHEN wp.equipment_needed::TEXT = user_equipment THEN 
                'Recomandat: Echipamentul disponibil se potrivește perfect.'
            ELSE 'Program standard - fără contraindicații detectate.'
        END AS recommendation_reason
    FROM public.workout_plans wp
    JOIN public.workout_categories wc ON wp.category_id = wc.id
    WHERE wp.is_active = true
    ORDER BY is_recommended DESC, wp.difficulty;
END;
$$;

COMMENT ON FUNCTION public.get_safe_workout_plans(UUID) IS 
'Returns workout plans filtered and ranked based on user medical conditions, equipment, and fitness level. 
Provides safety recommendations for users with specific health concerns.';