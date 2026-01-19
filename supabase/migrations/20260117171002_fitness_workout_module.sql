-- Location: supabase/migrations/20260117171002_fitness_workout_module.sql
-- Schema Analysis: Building upon authentication module
-- Integration Type: NEW_MODULE - Workout Plans and Exercises
-- Dependencies: public.user_profiles

-- 1. Types and Enums
CREATE TYPE public.training_type AS ENUM ('strength', 'cardio', 'hiit', 'flexibility', 'bodyweight');
CREATE TYPE public.difficulty_level AS ENUM ('beginner', 'intermediate', 'advanced');
CREATE TYPE public.equipment_type AS ENUM ('none', 'dumbbells', 'barbell', 'resistance_bands', 'gym_equipment', 'cardio_machine');

-- 2. Workout Plans Table
CREATE TABLE public.workout_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    name_ro TEXT NOT NULL, -- Romanian name
    description TEXT,
    description_ro TEXT,
    training_type public.training_type NOT NULL,
    difficulty_level public.difficulty_level NOT NULL,
    duration_weeks INTEGER NOT NULL,
    required_equipment public.equipment_type[] DEFAULT ARRAY[]::public.equipment_type[],
    thumbnail_url TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. Exercises Table
CREATE TABLE public.exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    name_ro TEXT NOT NULL,
    description TEXT,
    description_ro TEXT,
    instructions TEXT,
    instructions_ro TEXT,
    video_url TEXT NOT NULL,
    thumbnail_url TEXT,
    muscle_groups TEXT[] DEFAULT ARRAY[]::TEXT[],
    equipment_needed public.equipment_type DEFAULT 'none'::public.equipment_type,
    difficulty_level public.difficulty_level NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 4. Workout Plan Exercises Junction Table
CREATE TABLE public.workout_plan_exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workout_plan_id UUID REFERENCES public.workout_plans(id) ON DELETE CASCADE,
    exercise_id UUID REFERENCES public.exercises(id) ON DELETE CASCADE,
    week_number INTEGER NOT NULL,
    day_number INTEGER NOT NULL,
    sets INTEGER NOT NULL DEFAULT 3,
    reps INTEGER NOT NULL DEFAULT 10,
    rest_seconds INTEGER NOT NULL DEFAULT 60,
    order_index INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(workout_plan_id, week_number, day_number, order_index)
);

-- 5. User Workout Progress Table
CREATE TABLE public.user_workout_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    workout_plan_id UUID REFERENCES public.workout_plans(id) ON DELETE CASCADE,
    current_week INTEGER NOT NULL DEFAULT 1,
    completed_days INTEGER[] DEFAULT ARRAY[]::INTEGER[],
    started_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 6. Essential Indexes
CREATE INDEX idx_workout_plans_training_type ON public.workout_plans(training_type);
CREATE INDEX idx_workout_plans_difficulty ON public.workout_plans(difficulty_level);
CREATE INDEX idx_exercises_difficulty ON public.exercises(difficulty_level);
CREATE INDEX idx_workout_plan_exercises_plan ON public.workout_plan_exercises(workout_plan_id);
CREATE INDEX idx_workout_plan_exercises_exercise ON public.workout_plan_exercises(exercise_id);
CREATE INDEX idx_user_workout_progress_user ON public.user_workout_progress(user_id);
CREATE INDEX idx_user_workout_progress_active ON public.user_workout_progress(is_active);

-- 7. RLS Setup
ALTER TABLE public.workout_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_plan_exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_workout_progress ENABLE ROW LEVEL SECURITY;

-- 8. RLS Policies (Pattern 4: Public Read, Private Write)
CREATE POLICY "public_can_read_workout_plans"
ON public.workout_plans
FOR SELECT
TO public
USING (true);

CREATE POLICY "public_can_read_exercises"
ON public.exercises
FOR SELECT
TO public
USING (true);

CREATE POLICY "public_can_read_workout_plan_exercises"
ON public.workout_plan_exercises
FOR SELECT
TO public
USING (true);

-- Pattern 2: Simple User Ownership for Progress
CREATE POLICY "users_manage_own_workout_progress"
ON public.user_workout_progress
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- 9. Mock Data
DO $$
DECLARE
    strength_plan_id UUID := gen_random_uuid();
    cardio_plan_id UUID := gen_random_uuid();
    hiit_plan_id UUID := gen_random_uuid();
    flex_plan_id UUID := gen_random_uuid();
    bodyweight_plan_id UUID := gen_random_uuid();
    
    pushup_exercise_id UUID := gen_random_uuid();
    squat_exercise_id UUID := gen_random_uuid();
    plank_exercise_id UUID := gen_random_uuid();
    jumping_jacks_id UUID := gen_random_uuid();
    burpees_id UUID := gen_random_uuid();
    yoga_stretch_id UUID := gen_random_uuid();
    bench_press_id UUID := gen_random_uuid();
    deadlift_id UUID := gen_random_uuid();
    running_id UUID := gen_random_uuid();
    cycling_id UUID := gen_random_uuid();
BEGIN
    -- Insert Workout Plans
    INSERT INTO public.workout_plans (id, name, name_ro, description, description_ro, training_type, difficulty_level, duration_weeks, required_equipment, thumbnail_url) VALUES
        (strength_plan_id, 'Full Body Strength Builder', 'Program Forță Corp Complet', 'Build overall strength with compound movements', 'Construiește forța generală cu mișcări compuse', 'strength'::public.training_type, 'intermediate'::public.difficulty_level, 8, ARRAY['dumbbells', 'barbell', 'gym_equipment']::public.equipment_type[], 'https://images.pexels.com/photos/1552242/pexels-photo-1552242.jpeg'),
        (cardio_plan_id, 'Cardio Endurance Program', 'Program Rezistență Cardio', 'Improve cardiovascular endurance', 'Îmbunătățește rezistența cardiovasculară', 'cardio'::public.training_type, 'beginner'::public.difficulty_level, 6, ARRAY['cardio_machine']::public.equipment_type[], 'https://images.pexels.com/photos/4162492/pexels-photo-4162492.jpeg'),
        (hiit_plan_id, 'High Intensity Interval Training', 'Antrenament Intervalat Intensitate Mare', 'Maximize fat burn with intense intervals', 'Maximizează arderea grăsimilor cu intervale intense', 'hiit'::public.training_type, 'advanced'::public.difficulty_level, 4, ARRAY['none']::public.equipment_type[], 'https://images.pexels.com/photos/4164761/pexels-photo-4164761.jpeg'),
        (flex_plan_id, 'Flexibility & Mobility', 'Flexibilitate și Mobilitate', 'Enhance flexibility and range of motion', 'Îmbunătățește flexibilitatea și amplitudinea mișcărilor', 'flexibility'::public.training_type, 'beginner'::public.difficulty_level, 4, ARRAY['none']::public.equipment_type[], 'https://images.pexels.com/photos/3822621/pexels-photo-3822621.jpeg'),
        (bodyweight_plan_id, 'Bodyweight Mastery', 'Stăpânire Exerciții Corp Liber', 'Master bodyweight exercises anywhere', 'Stăpânește exercițiile cu corp liber oriunde', 'bodyweight'::public.training_type, 'intermediate'::public.difficulty_level, 6, ARRAY['none']::public.equipment_type[], 'https://images.pexels.com/photos/4164844/pexels-photo-4164844.jpeg');

    -- Insert Exercises
    INSERT INTO public.exercises (id, name, name_ro, description, description_ro, instructions, instructions_ro, video_url, thumbnail_url, muscle_groups, equipment_needed, difficulty_level) VALUES
        (pushup_exercise_id, 'Push-ups', 'Flotări', 'Classic upper body exercise', 'Exercițiu clasic pentru partea superioară', 'Start in plank position, lower body, push back up', 'Începe în poziție de planșă, coboară corpul, împinge înapoi', 'https://www.youtube.com/watch?v=IODxDxX7oi4', 'https://images.pexels.com/photos/416778/pexels-photo-416778.jpeg', ARRAY['chest', 'triceps', 'shoulders'], 'none'::public.equipment_type, 'beginner'::public.difficulty_level),
        (squat_exercise_id, 'Squats', 'Genuflexiuni', 'Lower body strength builder', 'Construitor de forță pentru partea inferioară', 'Stand with feet shoulder-width, lower hips, stand back up', 'Stai cu picioarele la lățimea umerilor, coboară șoldurile, ridică-te', 'https://www.youtube.com/watch?v=aclHkVaku9U', 'https://images.pexels.com/photos/1552252/pexels-photo-1552252.jpeg', ARRAY['quadriceps', 'glutes', 'hamstrings'], 'none'::public.equipment_type, 'beginner'::public.difficulty_level),
        (plank_exercise_id, 'Plank Hold', 'Planșă', 'Core stability exercise', 'Exercițiu pentru stabilitatea trunchiului', 'Hold body straight in push-up position', 'Menține corpul drept în poziție de flotare', 'https://www.youtube.com/watch?v=ASdvN_XEl_c', 'https://images.pexels.com/photos/4162449/pexels-photo-4162449.jpeg', ARRAY['core', 'abs'], 'none'::public.equipment_type, 'beginner'::public.difficulty_level),
        (jumping_jacks_id, 'Jumping Jacks', 'Sărituri cu Mâinile Sus', 'Cardio warm-up exercise', 'Exercițiu cardio de încălzire', 'Jump while spreading legs and raising arms', 'Sari în timp ce îți deschizi picioarele și ridici brațele', 'https://www.youtube.com/watch?v=iSSAk4XCsRA', 'https://images.pexels.com/photos/4164761/pexels-photo-4164761.jpeg', ARRAY['full_body'], 'none'::public.equipment_type, 'beginner'::public.difficulty_level),
        (burpees_id, 'Burpees', 'Burpees', 'Full body high-intensity exercise', 'Exercițiu complet de intensitate mare', 'Squat, plank, push-up, jump up', 'Genuflexiune, planșă, flotare, săritură', 'https://www.youtube.com/watch?v=dZgVxmf6jkA', 'https://images.pexels.com/photos/4164844/pexels-photo-4164844.jpeg', ARRAY['full_body'], 'none'::public.equipment_type, 'advanced'::public.difficulty_level),
        (yoga_stretch_id, 'Yoga Stretch', 'Întindere Yoga', 'Flexibility and relaxation', 'Flexibilitate și relaxare', 'Hold stretches for 30-60 seconds', 'Menține întinderile 30-60 secunde', 'https://www.youtube.com/watch?v=v7AYKMP6rOE', 'https://images.pexels.com/photos/3822621/pexels-photo-3822621.jpeg', ARRAY['full_body'], 'none'::public.equipment_type, 'beginner'::public.difficulty_level),
        (bench_press_id, 'Bench Press', 'Presă Bancă', 'Upper body strength exercise', 'Exercițiu de forță pentru partea superioară', 'Lie on bench, lower barbell to chest, press up', 'Întinde-te pe bancă, coboară bara spre piept, împinge', 'https://www.youtube.com/watch?v=rT7DgCr-3pg', 'https://images.pexels.com/photos/1552242/pexels-photo-1552242.jpeg', ARRAY['chest', 'triceps', 'shoulders'], 'barbell'::public.equipment_type, 'intermediate'::public.difficulty_level),
        (deadlift_id, 'Deadlift', 'Ridicare din Poziție Moartă', 'Lower body and back strength', 'Forță pentru partea inferioară și spate', 'Lift barbell from ground to standing position', 'Ridică bara de pe sol în poziție verticală', 'https://www.youtube.com/watch?v=op9kVnSso6Q', 'https://images.pexels.com/photos/1552249/pexels-photo-1552249.jpeg', ARRAY['back', 'hamstrings', 'glutes'], 'barbell'::public.equipment_type, 'intermediate'::public.difficulty_level),
        (running_id, 'Running', 'Alergare', 'Cardio endurance exercise', 'Exercițiu de rezistență cardio', 'Maintain steady pace for set duration', 'Menține o ritmă constantă pentru durata stabilită', 'https://www.youtube.com/watch?v=brFHyOtTwH4', 'https://images.pexels.com/photos/4162492/pexels-photo-4162492.jpeg', ARRAY['legs', 'cardiovascular'], 'cardio_machine'::public.equipment_type, 'beginner'::public.difficulty_level),
        (cycling_id, 'Stationary Cycling', 'Ciclism Staționar', 'Low-impact cardio workout', 'Antrenament cardio cu impact redus', 'Pedal at moderate to high intensity', 'Pedalează cu intensitate moderată până la mare', 'https://www.youtube.com/watch?v=uyDJDWHi7Kg', 'https://images.pexels.com/photos/5705090/pexels-photo-5705090.jpeg', ARRAY['legs', 'cardiovascular'], 'cardio_machine'::public.equipment_type, 'beginner'::public.difficulty_level);

    -- Link Exercises to Strength Workout Plan (Week 1)
    INSERT INTO public.workout_plan_exercises (workout_plan_id, exercise_id, week_number, day_number, sets, reps, rest_seconds, order_index) VALUES
        (strength_plan_id, bench_press_id, 1, 1, 4, 8, 90, 1),
        (strength_plan_id, squat_exercise_id, 1, 1, 4, 10, 90, 2),
        (strength_plan_id, deadlift_id, 1, 3, 4, 6, 120, 1),
        (strength_plan_id, pushup_exercise_id, 1, 3, 3, 15, 60, 2);

    -- Link Exercises to Cardio Workout Plan
    INSERT INTO public.workout_plan_exercises (workout_plan_id, exercise_id, week_number, day_number, sets, reps, rest_seconds, order_index) VALUES
        (cardio_plan_id, running_id, 1, 1, 1, 20, 0, 1),
        (cardio_plan_id, cycling_id, 1, 3, 1, 30, 0, 1),
        (cardio_plan_id, jumping_jacks_id, 1, 5, 3, 30, 30, 1);

    -- Link Exercises to HIIT Workout Plan
    INSERT INTO public.workout_plan_exercises (workout_plan_id, exercise_id, week_number, day_number, sets, reps, rest_seconds, order_index) VALUES
        (hiit_plan_id, burpees_id, 1, 1, 5, 15, 30, 1),
        (hiit_plan_id, jumping_jacks_id, 1, 1, 5, 30, 30, 2),
        (hiit_plan_id, squat_exercise_id, 1, 2, 5, 20, 30, 1);

    -- Link Exercises to Flexibility Plan
    INSERT INTO public.workout_plan_exercises (workout_plan_id, exercise_id, week_number, day_number, sets, reps, rest_seconds, order_index) VALUES
        (flex_plan_id, yoga_stretch_id, 1, 1, 3, 1, 60, 1),
        (flex_plan_id, plank_exercise_id, 1, 1, 3, 1, 30, 2);

    -- Link Exercises to Bodyweight Plan
    INSERT INTO public.workout_plan_exercises (workout_plan_id, exercise_id, week_number, day_number, sets, reps, rest_seconds, order_index) VALUES
        (bodyweight_plan_id, pushup_exercise_id, 1, 1, 4, 15, 60, 1),
        (bodyweight_plan_id, squat_exercise_id, 1, 1, 4, 20, 60, 2),
        (bodyweight_plan_id, plank_exercise_id, 1, 1, 3, 1, 45, 3),
        (bodyweight_plan_id, burpees_id, 1, 3, 4, 12, 60, 1);
END $$;