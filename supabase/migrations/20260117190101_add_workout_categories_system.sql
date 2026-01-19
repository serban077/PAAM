-- Location: supabase/migrations/20260117190101_add_workout_categories_system.sql
-- Schema Analysis: Existing fitness app with exercises, workout_sessions, workout_plans, user_profiles
-- Integration Type: Extension - Adding workout categorization system
-- Dependencies: exercises, workout_sessions tables

-- ============================================================================
-- 1. CREATE WORKOUT_CATEGORIES TABLE
-- ============================================================================

CREATE TABLE public.workout_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    image_url TEXT,
    icon TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 2. ADD CATEGORY_ID TO EXERCISES TABLE
-- ============================================================================

ALTER TABLE public.exercises
ADD COLUMN category_id UUID REFERENCES public.workout_categories(id) ON DELETE SET NULL;

-- ============================================================================
-- 3. ADD CATEGORY_ID TO WORKOUT_SESSIONS TABLE (OPTIONAL BUT USEFUL)
-- ============================================================================

ALTER TABLE public.workout_sessions
ADD COLUMN category_id UUID REFERENCES public.workout_categories(id) ON DELETE SET NULL;

-- ============================================================================
-- 4. CREATE INDEXES FOR PERFORMANCE
-- ============================================================================

CREATE INDEX idx_workout_categories_name ON public.workout_categories(name);
CREATE INDEX idx_exercises_category_id ON public.exercises(category_id);
CREATE INDEX idx_workout_sessions_category_id ON public.workout_sessions(category_id);

-- ============================================================================
-- 5. ENABLE ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE public.workout_categories ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 6. CREATE RLS POLICIES (PUBLIC READ ACCESS)
-- ============================================================================

CREATE POLICY "public_read_workout_categories"
ON public.workout_categories
FOR SELECT
TO authenticated
USING (true);

-- ============================================================================
-- 7. SEED WORKOUT CATEGORIES DATA
-- ============================================================================

DO $$
DECLARE
    strength_id UUID := gen_random_uuid();
    cardio_id UUID := gen_random_uuid();
    flexibility_id UUID := gen_random_uuid();
    hiit_id UUID := gen_random_uuid();
    yoga_id UUID := gen_random_uuid();
    pilates_id UUID := gen_random_uuid();
    sports_id UUID := gen_random_uuid();
BEGIN
    -- Insert workout categories
    INSERT INTO public.workout_categories (id, name, description, image_url, icon) VALUES
        (strength_id, 'Forță', 'Antrenamente pentru construirea masei musculare și creșterea forței', 'https://images.pexels.com/photos/841130/pexels-photo-841130.jpeg', '💪'),
        (cardio_id, 'Cardio', 'Antrenamente aerobice pentru rezistență și sănătatea cardiovasculară', 'https://images.pexels.com/photos/2035066/pexels-photo-2035066.jpeg', '🏃'),
        (flexibility_id, 'Flexibilitate', 'Exerciții de stretching pentru mobilitate și prevenirea accidentărilor', 'https://images.pexels.com/photos/3822906/pexels-photo-3822906.jpeg', '🤸'),
        (hiit_id, 'HIIT', 'Antrenamente de intensitate ridicată pentru arderea caloriilor', 'https://images.pexels.com/photos/4162449/pexels-photo-4162449.jpeg', '🔥'),
        (yoga_id, 'Yoga', 'Practici de yoga pentru echilibru, flexibilitate și relaxare', 'https://images.pexels.com/photos/3822621/pexels-photo-3822621.jpeg', '🧘'),
        (pilates_id, 'Pilates', 'Exerciții pentru întărirea core-ului și tonifierea corpului', 'https://images.pexels.com/photos/4056535/pexels-photo-4056535.jpeg', '⚡'),
        (sports_id, 'Sport', 'Activități sportive și antrenamente specifice', 'https://images.pexels.com/photos/3775164/pexels-photo-3775164.jpeg', '⚽');

    -- Update existing exercises with appropriate category_id
    -- Strength exercises
    UPDATE public.exercises
    SET category_id = strength_id
    WHERE name IN ('Genuflexiuni', 'Flotări')
       OR target_muscle_groups::TEXT ILIKE '%fesieri%'
       OR target_muscle_groups::TEXT ILIKE '%cvadriceps%'
       OR target_muscle_groups::TEXT ILIKE '%piept%';

    -- Cardio exercises (if any exist with cardio-related names)
    UPDATE public.exercises
    SET category_id = cardio_id
    WHERE name ILIKE '%alergare%'
       OR name ILIKE '%cardio%'
       OR name ILIKE '%ciclism%';

    -- Flexibility exercises
    UPDATE public.exercises
    SET category_id = flexibility_id
    WHERE name ILIKE '%stretching%'
       OR name ILIKE '%intindere%';

    -- Log successful seeding
    RAISE NOTICE 'Workout categories seeded successfully with % categories', 7;
END $$;

-- ============================================================================
-- 8. UPDATE EXISTING WORKOUT SESSIONS WITH CATEGORY_ID (OPTIONAL)
-- ============================================================================

-- This will intelligently assign categories to existing workout sessions based on their focus_area
DO $$
DECLARE
    strength_cat_id UUID;
    cardio_cat_id UUID;
    flexibility_cat_id UUID;
BEGIN
    -- Get category IDs
    SELECT id INTO strength_cat_id FROM public.workout_categories WHERE name = 'Forță' LIMIT 1;
    SELECT id INTO cardio_cat_id FROM public.workout_categories WHERE name = 'Cardio' LIMIT 1;
    SELECT id INTO flexibility_cat_id FROM public.workout_categories WHERE name = 'Flexibilitate' LIMIT 1;

    -- Update workout sessions based on focus_area
    UPDATE public.workout_sessions
    SET category_id = CASE
        WHEN focus_area ILIKE '%piept%' OR focus_area ILIKE '%spate%' OR focus_area ILIKE '%picioare%' THEN strength_cat_id
        WHEN focus_area ILIKE '%cardio%' OR focus_area ILIKE '%rezistenta%' THEN cardio_cat_id
        WHEN focus_area ILIKE '%flexibilitate%' OR focus_area ILIKE '%stretching%' THEN flexibility_cat_id
        ELSE strength_cat_id  -- Default to strength if unclear
    END
    WHERE category_id IS NULL;

    RAISE NOTICE 'Workout sessions updated with category assignments';
END $$;