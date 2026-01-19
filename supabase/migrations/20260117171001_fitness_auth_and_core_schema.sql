-- Location: supabase/migrations/20260117171001_fitness_auth_and_core_schema.sql
-- Schema Analysis: Fresh project - No existing tables
-- Integration Type: New complete schema with authentication
-- Dependencies: None - Complete fresh implementation

-- ============================================================================
-- STEP 1: TYPES AND ENUMS
-- ============================================================================

CREATE TYPE public.fitness_goal AS ENUM ('pierdere_greutate', 'crestere_masa_musculara', 'mentinere', 'tonifiere');
CREATE TYPE public.activity_level AS ENUM ('sedentar', 'usor_activ', 'moderat_activ', 'foarte_activ', 'extrem_activ');
CREATE TYPE public.equipment_type AS ENUM ('acasa_fara_echipament', 'acasa_cu_echipament_basic', 'sala_fitness', 'mix');
CREATE TYPE public.dietary_preference AS ENUM ('normal', 'vegetarian', 'vegan', 'fara_gluten', 'fara_lactate');
CREATE TYPE public.workout_type AS ENUM ('piept', 'spate', 'picioare', 'umeri', 'brate', 'abdomen', 'cardio', 'full_body');
CREATE TYPE public.difficulty_level AS ENUM ('incepator', 'intermediar', 'avansat');

-- ============================================================================
-- STEP 2: CORE TABLES - USER MANAGEMENT
-- ============================================================================

-- User profiles table (intermediary for auth.users)
CREATE TABLE public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL,
    avatar_url TEXT,
    age INTEGER,
    gender TEXT CHECK (gender IN ('barbat', 'femeie', 'altul')),
    height_cm DECIMAL(5,2),
    current_weight_kg DECIMAL(5,2),
    target_weight_kg DECIMAL(5,2),
    fitness_goal public.fitness_goal DEFAULT 'mentinere'::public.fitness_goal,
    activity_level public.activity_level DEFAULT 'moderat_activ'::public.activity_level,
    equipment_available public.equipment_type DEFAULT 'sala_fitness'::public.equipment_type,
    dietary_preference public.dietary_preference DEFAULT 'normal'::public.dietary_preference,
    medical_conditions TEXT,
    daily_calorie_goal INTEGER,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Onboarding survey responses
CREATE TABLE public.onboarding_responses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    step_number INTEGER NOT NULL,
    question_key TEXT NOT NULL,
    answer_value TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- STEP 3: WORKOUT MANAGEMENT TABLES
-- ============================================================================

-- Workout types/categories
CREATE TABLE public.workout_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    type_enum public.workout_type NOT NULL UNIQUE,
    description TEXT,
    icon_url TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Workout plans
CREATE TABLE public.workout_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id UUID REFERENCES public.workout_categories(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    difficulty public.difficulty_level DEFAULT 'intermediar'::public.difficulty_level,
    estimated_duration_minutes INTEGER,
    equipment_needed public.equipment_type DEFAULT 'sala_fitness'::public.equipment_type,
    thumbnail_url TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Exercises library
CREATE TABLE public.exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    category_id UUID REFERENCES public.workout_categories(id) ON DELETE SET NULL,
    description TEXT,
    video_url TEXT,
    thumbnail_url TEXT,
    muscle_groups TEXT[],
    equipment_required TEXT[],
    difficulty public.difficulty_level DEFAULT 'intermediar'::public.difficulty_level,
    instructions TEXT,
    tips TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Workout plan exercises (junction table)
CREATE TABLE public.workout_plan_exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workout_plan_id UUID REFERENCES public.workout_plans(id) ON DELETE CASCADE,
    exercise_id UUID REFERENCES public.exercises(id) ON DELETE CASCADE,
    order_index INTEGER NOT NULL,
    sets INTEGER DEFAULT 3,
    reps TEXT,
    rest_seconds INTEGER DEFAULT 60,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- User workout history
CREATE TABLE public.user_workouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    workout_plan_id UUID REFERENCES public.workout_plans(id) ON DELETE SET NULL,
    started_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMPTZ,
    duration_minutes INTEGER,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- STEP 4: NUTRITION MANAGEMENT TABLES
-- ============================================================================

-- Foods database
CREATE TABLE public.foods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    brand TEXT,
    serving_size TEXT,
    calories INTEGER NOT NULL,
    protein_g DECIMAL(6,2),
    carbs_g DECIMAL(6,2),
    fat_g DECIMAL(6,2),
    fiber_g DECIMAL(6,2),
    is_user_created BOOLEAN DEFAULT false,
    created_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    is_verified BOOLEAN DEFAULT false,
    barcode TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- User meals log
CREATE TABLE public.user_meals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    food_id UUID REFERENCES public.foods(id) ON DELETE SET NULL,
    meal_type TEXT CHECK (meal_type IN ('mic_dejun', 'gustare_dimineata', 'pranz', 'gustare_dupa_amiaza', 'cina', 'gustare_seara')),
    servings DECIMAL(6,2) DEFAULT 1,
    meal_date DATE DEFAULT CURRENT_DATE,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- STEP 5: PROGRESS TRACKING TABLES
-- ============================================================================

-- Weight tracking
CREATE TABLE public.weight_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    weight_kg DECIMAL(5,2) NOT NULL,
    log_date DATE DEFAULT CURRENT_DATE,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Body measurements
CREATE TABLE public.measurement_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    chest_cm DECIMAL(5,2),
    waist_cm DECIMAL(5,2),
    hips_cm DECIMAL(5,2),
    biceps_cm DECIMAL(5,2),
    thighs_cm DECIMAL(5,2),
    log_date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Progress photos
CREATE TABLE public.progress_photos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    photo_url TEXT NOT NULL,
    photo_type TEXT CHECK (photo_type IN ('fata', 'lateral', 'spate')),
    taken_date DATE DEFAULT CURRENT_DATE,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- STEP 6: INDEXES FOR PERFORMANCE
-- ============================================================================

CREATE INDEX idx_user_profiles_email ON public.user_profiles(email);
CREATE INDEX idx_onboarding_user_id ON public.onboarding_responses(user_id);
CREATE INDEX idx_workout_plans_category ON public.workout_plans(category_id);
CREATE INDEX idx_exercises_category ON public.exercises(category_id);
CREATE INDEX idx_plan_exercises_workout ON public.workout_plan_exercises(workout_plan_id);
CREATE INDEX idx_plan_exercises_exercise ON public.workout_plan_exercises(exercise_id);
CREATE INDEX idx_user_workouts_user ON public.user_workouts(user_id);
CREATE INDEX idx_user_workouts_plan ON public.user_workouts(workout_plan_id);
CREATE INDEX idx_foods_name ON public.foods(name);
CREATE INDEX idx_foods_created_by ON public.foods(created_by);
CREATE INDEX idx_user_meals_user_date ON public.user_meals(user_id, meal_date);
CREATE INDEX idx_user_meals_food ON public.user_meals(food_id);
CREATE INDEX idx_weight_logs_user_date ON public.weight_logs(user_id, log_date);
CREATE INDEX idx_measurement_logs_user_date ON public.measurement_logs(user_id, log_date);
CREATE INDEX idx_progress_photos_user_date ON public.progress_photos(user_id, taken_date);

-- ============================================================================
-- STEP 7: ROW LEVEL SECURITY SETUP
-- ============================================================================

ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.onboarding_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_plan_exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.foods ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_meals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.weight_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.measurement_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.progress_photos ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- STEP 8: RLS POLICIES - AUTHENTICATION PATTERNS
-- ============================================================================

-- Pattern 1: Core user table (user_profiles) - Simple ownership
CREATE POLICY "users_manage_own_user_profiles"
ON public.user_profiles
FOR ALL
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- Pattern 2: Simple user ownership for private data
CREATE POLICY "users_manage_own_onboarding"
ON public.onboarding_responses
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_manage_own_workouts"
ON public.user_workouts
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_manage_own_meals"
ON public.user_meals
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_manage_own_weight"
ON public.weight_logs
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_manage_own_measurements"
ON public.measurement_logs
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_manage_own_photos"
ON public.progress_photos
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Pattern 4: Public read, authenticated write for shared resources
CREATE POLICY "public_read_workout_categories"
ON public.workout_categories
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "public_read_workout_plans"
ON public.workout_plans
FOR SELECT
TO authenticated
USING (is_active = true);

CREATE POLICY "public_read_exercises"
ON public.exercises
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "public_read_plan_exercises"
ON public.workout_plan_exercises
FOR SELECT
TO authenticated
USING (true);

-- Foods: Public read for verified, users manage their own
CREATE POLICY "public_read_verified_foods"
ON public.foods
FOR SELECT
TO authenticated
USING (is_verified = true OR created_by = auth.uid());

CREATE POLICY "users_manage_own_foods"
ON public.foods
FOR ALL
TO authenticated
USING (created_by = auth.uid())
WITH CHECK (created_by = auth.uid());

-- ============================================================================
-- STEP 9: TRIGGERS FOR AUTO-PROFILE CREATION
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public.user_profiles (
        id, 
        email, 
        full_name, 
        avatar_url
    )
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'avatar_url', '')
    );
    RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================================
-- STEP 10: HELPER FUNCTIONS
-- ============================================================================

-- Calculate TDEE (Total Daily Energy Expenditure)
CREATE OR REPLACE FUNCTION public.calculate_tdee(
    user_uuid UUID
)
RETURNS INTEGER
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
DECLARE
    profile_record RECORD;
    bmr DECIMAL;
    activity_multiplier DECIMAL;
BEGIN
    SELECT * INTO profile_record
    FROM public.user_profiles
    WHERE id = user_uuid;

    IF NOT FOUND THEN
        RETURN 2000; -- Default fallback
    END IF;

    -- Calculate BMR using Mifflin-St Jeor equation
    IF profile_record.gender = 'barbat' THEN
        bmr := (10 * profile_record.current_weight_kg) + (6.25 * profile_record.height_cm) - (5 * profile_record.age) + 5;
    ELSE
        bmr := (10 * profile_record.current_weight_kg) + (6.25 * profile_record.height_cm) - (5 * profile_record.age) - 161;
    END IF;

    -- Apply activity level multiplier
    activity_multiplier := CASE profile_record.activity_level
        WHEN 'sedentar' THEN 1.2
        WHEN 'usor_activ' THEN 1.375
        WHEN 'moderat_activ' THEN 1.55
        WHEN 'foarte_activ' THEN 1.725
        WHEN 'extrem_activ' THEN 1.9
        ELSE 1.55
    END;

    RETURN ROUND(bmr * activity_multiplier)::INTEGER;
END;
$$;

-- ============================================================================
-- STEP 11: MOCK DATA FOR TESTING
-- ============================================================================

DO $$
DECLARE
    test_user_id UUID := gen_random_uuid();
    piept_cat_id UUID := gen_random_uuid();
    spate_cat_id UUID := gen_random_uuid();
    picioare_cat_id UUID := gen_random_uuid();
    piept_plan_id UUID := gen_random_uuid();
    spate_plan_id UUID := gen_random_uuid();
    picioare_plan_id UUID := gen_random_uuid();
    ex1_id UUID := gen_random_uuid();
    ex2_id UUID := gen_random_uuid();
    ex3_id UUID := gen_random_uuid();
    ex4_id UUID := gen_random_uuid();
    ex5_id UUID := gen_random_uuid();
    ex6_id UUID := gen_random_uuid();
BEGIN
    -- Create test user in auth.users
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        created_at, updated_at, raw_user_meta_data, raw_app_meta_data,
        is_sso_user, is_anonymous, confirmation_token, confirmation_sent_at,
        recovery_token, recovery_sent_at, email_change_token_new, email_change,
        email_change_sent_at, email_change_token_current, email_change_confirm_status,
        reauthentication_token, reauthentication_sent_at, phone, phone_change,
        phone_change_token, phone_change_sent_at
    ) VALUES (
        test_user_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'test@smartfitai.ro', crypt('Test123!', gen_salt('bf', 10)), now(), now(), now(),
        '{"full_name": "Test User", "avatar_url": ""}'::jsonb, 
        '{"provider": "email", "providers": ["email"]}'::jsonb,
        false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null
    );

    -- Insert workout categories
    INSERT INTO public.workout_categories (id, name, type_enum, description, icon_url) VALUES
        (piept_cat_id, 'Antrenament Piept', 'piept', 'Exerciții pentru dezvoltarea musculaturii pectorale', 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=400'),
        (spate_cat_id, 'Antrenament Spate', 'spate', 'Exerciții pentru dezvoltarea musculaturii dorsale', 'https://images.unsplash.com/photo-1532029837206-abbe2b7620e3?w=400'),
        (picioare_cat_id, 'Antrenament Picioare', 'picioare', 'Exerciții pentru dezvoltarea musculaturii picioarelor', 'https://images.unsplash.com/photo-1434682881908-b43d0467b798?w=400');

    -- Insert workout plans
    INSERT INTO public.workout_plans (id, category_id, title, description, difficulty, estimated_duration_minutes, thumbnail_url) VALUES
        (piept_plan_id, piept_cat_id, 'Program Piept Complet', 'Plan complet pentru dezvoltarea pectoralelor', 'intermediar', 45, 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=600'),
        (spate_plan_id, spate_cat_id, 'Program Spate Masiv', 'Plan pentru un spate puternic și larg', 'intermediar', 50, 'https://images.unsplash.com/photo-1532029837206-abbe2b7620e3?w=600'),
        (picioare_plan_id, picioare_cat_id, 'Program Picioare Puternice', 'Plan pentru dezvoltarea completă a picioarelor', 'avansat', 55, 'https://images.unsplash.com/photo-1434682881908-b43d0467b798?w=600');

    -- Insert exercises with Romanian descriptions
    INSERT INTO public.exercises (id, name, category_id, description, video_url, thumbnail_url, muscle_groups, equipment_required, difficulty, instructions, tips) VALUES
        (ex1_id, 'Flotări', piept_cat_id, 'Exercițiu fundamental pentru piept', 'https://www.youtube.com/watch?v=IODxDxX7oi4', 'https://images.pexels.com/photos/841130/pexels-photo-841130.jpeg?w=400', ARRAY['piept', 'triceps', 'umeri'], ARRAY['greutate_corporala'], 'incepator', 
         'Începeți în poziție de planșă cu mâinile puțin mai late decât umerii. Coborâți-vă corpul până când pieptul atinge aproape solul, apoi împingeți înapoi la poziția inițială.',
         'Mențineți corpul drept și abdomenul contractat pe toată durata mișcării.'),
        
        (ex2_id, 'Bench Press', piept_cat_id, 'Exercițiu clasic pentru masa musculară a pieptului', 'https://www.youtube.com/watch?v=rT7DgCr-3pg', 'https://images.unsplash.com/photo-1541534741688-6078c6bfb5c5?w=400', ARRAY['piept', 'triceps', 'umeri'], ARRAY['bara', 'banca'], 'intermediar',
         'Întindeți-vă pe bancă cu picioarele pe podea. Coborâți bara controlat până atinge pieptul, apoi împingeți puternic înapoi.',
         'Păstrați omoplații strânși și nu ridicați fesele de pe bancă.'),
        
        (ex3_id, 'Tracțiuni', spate_cat_id, 'Exercițiu excelent pentru dezvoltarea spatelui', 'https://www.youtube.com/watch?v=eGo4IYlbE5g', 'https://images.pexels.com/photos/1954524/pexels-photo-1954524.jpeg?w=400', ARRAY['spate', 'biceps'], ARRAY['bara_tractiuni'], 'intermediar',
         'Apucați bara cu priza mai largă decât umerii. Trageți-vă în sus până când bărbia depășește bara, apoi coborâți controlat.',
         'Concentrați-vă pe contractarea mușchilor spatelui, nu doar pe ridicare.'),
        
        (ex4_id, 'Rowing cu Bară', spate_cat_id, 'Exercițiu pentru grosimea spatelui', 'https://www.youtube.com/watch?v=FWJR5Ve8bnQ', 'https://images.unsplash.com/photo-1541534741688-6078c6bfb5c5?w=400', ARRAY['spate', 'biceps'], ARRAY['bara'], 'intermediar',
         'Aplecați-vă la 45 de grade cu bara în mâini. Trageți bara spre abdomen, strângând omoplații.',
         'Mențineți spatele drept și nu folosiți impulsul pentru a ridica bara.'),
        
        (ex5_id, 'Genuflexiuni', picioare_cat_id, 'Regele exercițiilor pentru picioare', 'https://www.youtube.com/watch?v=ultWZbUMPL8', 'https://images.pexels.com/photos/38630/bodybuilder-weight-training-stress-38630.jpeg?w=400', ARRAY['cvadriceps', 'fesieri', 'ischiogambieri'], ARRAY['bara'], 'avansat',
         'Așezați bara pe umeri, coborâți-vă până când coapsele sunt paralele cu solul, apoi împingeți înapoi.',
         'Genunchii nu trebuie să depășească vârfurile picioarelor.'),
        
        (ex6_id, 'Presa Picioare', picioare_cat_id, 'Exercițiu sigur pentru masa musculară a picioarelor', 'https://www.youtube.com/watch?v=IZxyjW7MPJQ', 'https://images.unsplash.com/photo-1434682881908-b43d0467b798?w=400', ARRAY['cvadriceps', 'fesieri'], ARRAY['aparat_presa'], 'intermediar',
         'Așezați picioarele pe platformă la lățimea umerilor. Împingeți platforma în sus, apoi coborâți controlat.',
         'Nu blocați genunchii la extensie completă.');

    -- Link exercises to workout plans
    INSERT INTO public.workout_plan_exercises (workout_plan_id, exercise_id, order_index, sets, reps, rest_seconds) VALUES
        (piept_plan_id, ex1_id, 1, 4, '12-15', 90),
        (piept_plan_id, ex2_id, 2, 4, '8-10', 120),
        (spate_plan_id, ex3_id, 1, 4, '8-12', 120),
        (spate_plan_id, ex4_id, 2, 4, '10-12', 90),
        (picioare_plan_id, ex5_id, 1, 5, '6-8', 180),
        (picioare_plan_id, ex6_id, 2, 4, '10-12', 120);

    -- Insert sample foods with Romanian names
    INSERT INTO public.foods (name, brand, serving_size, calories, protein_g, carbs_g, fat_g, fiber_g, is_verified) VALUES
        ('Piept de Pui', 'Generic', '100g', 165, 31.0, 0.0, 3.6, 0.0, true),
        ('Orez Integral', 'Generic', '100g', 370, 7.5, 77.0, 2.9, 3.5, true),
        ('Ouă', 'Generic', '1 ou mare', 78, 6.3, 0.6, 5.3, 0.0, true),
        ('Banană', 'Generic', '1 medie', 105, 1.3, 27.0, 0.4, 3.1, true),
        ('Iaurt Grecesc', 'Generic', '100g', 59, 10.0, 3.6, 0.4, 0.0, true);

    RAISE NOTICE 'Mock data created successfully with user: test@smartfitai.ro / Test123!';
END $$;