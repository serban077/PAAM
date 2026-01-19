-- Migration: Populate Comprehensive Workout Data with Categories
-- Purpose: Fix category_id error by populating complete workout system with proper relationships

-- =====================================================
-- STEP 1: Ensure workout_categories are populated
-- =====================================================

-- Insert additional workout categories if they don't exist
INSERT INTO public.workout_categories (name, description, icon, image_url)
VALUES 
  ('Forță Full Body', 'Antrenamente complete pentru tot corpul', '💪', 'https://images.pexels.com/photos/841130/pexels-photo-841130.jpeg'),
  ('Cardio Intensiv', 'Antrenamente cardio de intensitate ridicată', '🏃', 'https://images.pexels.com/photos/2035066/pexels-photo-2035066.jpeg'),
  ('Rezistență', 'Dezvoltarea rezistenței musculare', '⚡', 'https://images.pexels.com/photos/4164662/pexels-photo-4164662.jpeg'),
  ('Mobilitate', 'Îmbunătățirea flexibilității și mobilității', '🤸', 'https://images.pexels.com/photos/4056723/pexels-photo-4056723.jpeg')
ON CONFLICT (name) DO NOTHING;

-- =====================================================
-- STEP 2: Create comprehensive workout plans
-- =====================================================

-- Delete existing plans to avoid conflicts (only if needed for clean slate)
-- TRUNCATE TABLE public.workout_plans CASCADE;

-- Insert workout plans for different goals
DO $$
DECLARE
  v_plan_id_1 uuid;
  v_plan_id_2 uuid;
  v_plan_id_3 uuid;
  v_plan_id_4 uuid;
  
  -- Category IDs
  v_cat_forta uuid;
  v_cat_cardio uuid;
  v_cat_hiit uuid;
  v_cat_yoga uuid;
  v_cat_rezistenta uuid;
  v_cat_mobilitate uuid;
BEGIN
  -- Get category IDs
  SELECT id INTO v_cat_forta FROM public.workout_categories WHERE name = 'Forță' LIMIT 1;
  SELECT id INTO v_cat_cardio FROM public.workout_categories WHERE name = 'Cardio' LIMIT 1;
  SELECT id INTO v_cat_hiit FROM public.workout_categories WHERE name = 'HIIT' LIMIT 1;
  SELECT id INTO v_cat_yoga FROM public.workout_categories WHERE name = 'Yoga' LIMIT 1;
  SELECT id INTO v_cat_rezistenta FROM public.workout_categories WHERE name = 'Rezistență' LIMIT 1;
  SELECT id INTO v_cat_mobilitate FROM public.workout_categories WHERE name = 'Mobilitate' LIMIT 1;

  -- Plan 1: Pierdere Greutate (3x pe săptămână)
  INSERT INTO public.workout_plans (plan_name, fitness_goal, weekly_frequency, duration_weeks, is_active)
  VALUES ('Plan Pierdere Greutate - Începător', 'pierdere_greutate', 3, 8, false)
  RETURNING id INTO v_plan_id_1;

  -- Sessions for Plan 1
  -- Day 1: Cardio + HIIT
  INSERT INTO public.workout_sessions (plan_id, session_name, day_of_week, category_id, focus_area, estimated_duration_minutes)
  VALUES 
    (v_plan_id_1, 'Cardio Intensiv', 1, v_cat_cardio, 'Ardere Calorii', 30),
    (v_plan_id_1, 'HIIT pentru Tonifiere', 3, v_cat_hiit, 'Tonifiere Generală', 25),
    (v_plan_id_1, 'Cardio Recovery', 5, v_cat_cardio, 'Recuperare Activă', 35);

  -- Plan 2: Creștere Masă Musculară (4x pe săptămână)
  INSERT INTO public.workout_plans (plan_name, fitness_goal, weekly_frequency, duration_weeks, is_active)
  VALUES ('Plan Masă Musculară - Intermediar', 'crestere_masa_musculara', 4, 12, false)
  RETURNING id INTO v_plan_id_2;

  -- Sessions for Plan 2
  INSERT INTO public.workout_sessions (plan_id, session_name, day_of_week, category_id, focus_area, estimated_duration_minutes)
  VALUES 
    (v_plan_id_2, 'Forță Partea Superioară', 1, v_cat_forta, 'Piept, Umeri, Brațe', 50),
    (v_plan_id_2, 'Forță Partea Inferioară', 2, v_cat_forta, 'Picioare, Fesieri', 55),
    (v_plan_id_2, 'Forță Spate & Core', 4, v_cat_forta, 'Spate, Abdomen', 50),
    (v_plan_id_2, 'Full Body Power', 6, v_cat_forta, 'Tot Corpul', 60);

  -- Plan 3: Menținere & Tonifiere (3x pe săptămână)
  INSERT INTO public.workout_plans (plan_name, fitness_goal, weekly_frequency, duration_weeks, is_active)
  VALUES ('Plan Menținere - General', 'mentinere', 3, 10, false)
  RETURNING id INTO v_plan_id_3;

  -- Sessions for Plan 3
  INSERT INTO public.workout_sessions (plan_id, session_name, day_of_week, category_id, focus_area, estimated_duration_minutes)
  VALUES 
    (v_plan_id_3, 'Rezistență & Tonifiere', 1, v_cat_rezistenta, 'Tot Corpul', 40),
    (v_plan_id_3, 'Cardio Moderat', 3, v_cat_cardio, 'Condiționare Cardio', 30),
    (v_plan_id_3, 'Mobilitate & Yoga', 5, v_cat_yoga, 'Flexibilitate', 35);

  -- Plan 4: Tonifiere Avansată (5x pe săptămână)
  INSERT INTO public.workout_plans (plan_name, fitness_goal, weekly_frequency, duration_weeks, is_active)
  VALUES ('Plan Tonifiere Avansat', 'tonifiere', 5, 8, false)
  RETURNING id INTO v_plan_id_4;

  -- Sessions for Plan 4
  INSERT INTO public.workout_sessions (plan_id, session_name, day_of_week, category_id, focus_area, estimated_duration_minutes)
  VALUES 
    (v_plan_id_4, 'HIIT Upper Body', 1, v_cat_hiit, 'Partea Superioară', 30),
    (v_plan_id_4, 'HIIT Lower Body', 2, v_cat_hiit, 'Partea Inferioară', 30),
    (v_plan_id_4, 'Cardio Intensiv', 3, v_cat_cardio, 'Ardere Calorii', 35),
    (v_plan_id_4, 'Forță & Tonifiere', 5, v_cat_forta, 'Tot Corpul', 45),
    (v_plan_id_4, 'Mobilitate Activă', 6, v_cat_mobilitate, 'Recuperare', 25);

END $$;

-- =====================================================
-- STEP 3: Populate exercises with proper categories
-- =====================================================

-- Update existing exercises with proper category assignments
DO $$
DECLARE
  v_cat_forta uuid;
  v_cat_cardio uuid;
  v_cat_hiit uuid;
  v_cat_yoga uuid;
  v_cat_flexibilitate uuid;
BEGIN
  -- Get category IDs
  SELECT id INTO v_cat_forta FROM public.workout_categories WHERE name = 'Forță' LIMIT 1;
  SELECT id INTO v_cat_cardio FROM public.workout_categories WHERE name = 'Cardio' LIMIT 1;
  SELECT id INTO v_cat_hiit FROM public.workout_categories WHERE name = 'HIIT' LIMIT 1;
  SELECT id INTO v_cat_yoga FROM public.workout_categories WHERE name = 'Yoga' LIMIT 1;
  SELECT id INTO v_cat_flexibilitate FROM public.workout_categories WHERE name = 'Flexibilitate' LIMIT 1;

  -- Update exercises to assign categories
  UPDATE public.exercises SET category_id = v_cat_forta 
  WHERE name IN ('Genuflexiuni', 'Împins Bancă', 'Deadlift', 'Tracțiuni', 'Presa Umeri');

  UPDATE public.exercises SET category_id = v_cat_cardio 
  WHERE name IN ('Alergare', 'Bicicletă', 'Sărituri');

  UPDATE public.exercises SET category_id = v_cat_hiit 
  WHERE name IN ('Burpees', 'Mountain Climbers', 'Jump Squats');

  UPDATE public.exercises SET category_id = v_cat_flexibilitate 
  WHERE name IN ('Stretching', 'Yoga Flow');

END $$;

-- Insert additional exercises if needed
INSERT INTO public.exercises (name, description, category_id, difficulty_level, equipment_required, target_muscle_groups, video_url, is_safe_for_conditions)
SELECT 
  'Genuflexiuni cu Greutatea Corporală',
  'Exercițiu fundamental pentru picioare fără echipament',
  (SELECT id FROM public.workout_categories WHERE name = 'Forță' LIMIT 1),
  'beginner',
  'acasa_fara_echipament',
  ARRAY['cvadriceps', 'fesieri', 'ischiogambieri'],
  'https://example.com/squats',
  ARRAY['generale']
WHERE NOT EXISTS (
  SELECT 1 FROM public.exercises WHERE name = 'Genuflexiuni cu Greutatea Corporală'
);

INSERT INTO public.exercises (name, description, category_id, difficulty_level, equipment_required, target_muscle_groups, video_url, is_safe_for_conditions)
SELECT 
  'Flotări',
  'Exercițiu complet pentru partea superioară',
  (SELECT id FROM public.workout_categories WHERE name = 'Forță' LIMIT 1),
  'beginner',
  'acasa_fara_echipament',
  ARRAY['pectorali', 'triceps', 'umeri'],
  'https://example.com/pushups',
  ARRAY['generale']
WHERE NOT EXISTS (
  SELECT 1 FROM public.exercises WHERE name = 'Flotări'
);

INSERT INTO public.exercises (name, description, category_id, difficulty_level, equipment_required, target_muscle_groups, video_url, is_safe_for_conditions)
SELECT 
  'Alergare în Loc',
  'Cardio simplu pentru acasă',
  (SELECT id FROM public.workout_categories WHERE name = 'Cardio' LIMIT 1),
  'beginner',
  'acasa_fara_echipament',
  ARRAY['cardio', 'picioare'],
  'https://example.com/running',
  ARRAY['generale']
WHERE NOT EXISTS (
  SELECT 1 FROM public.exercises WHERE name = 'Alergare în Loc'
);

-- =====================================================
-- STEP 4: Link exercises to workout sessions
-- =====================================================

-- Get some session IDs and exercise IDs to create session_exercises relationships
DO $$
DECLARE
  v_session_id uuid;
  v_exercise_squat uuid;
  v_exercise_pushup uuid;
  v_exercise_running uuid;
BEGIN
  -- Get first session for demo
  SELECT id INTO v_session_id FROM public.workout_sessions LIMIT 1;
  
  -- Get exercise IDs
  SELECT id INTO v_exercise_squat FROM public.exercises WHERE name LIKE '%Genuflexiuni%' LIMIT 1;
  SELECT id INTO v_exercise_pushup FROM public.exercises WHERE name LIKE '%Flotări%' LIMIT 1;
  SELECT id INTO v_exercise_running FROM public.exercises WHERE name LIKE '%Alergare%' LIMIT 1;

  -- Link exercises to first session as example
  IF v_session_id IS NOT NULL AND v_exercise_squat IS NOT NULL THEN
    INSERT INTO public.session_exercises (session_id, exercise_id, order_in_session, sets, reps_min, reps_max, rest_seconds)
    VALUES 
      (v_session_id, v_exercise_squat, 1, 3, 10, 15, 60),
      (v_session_id, v_exercise_pushup, 2, 3, 8, 12, 60),
      (v_session_id, v_exercise_running, 3, 1, 20, 30, 90)
    ON CONFLICT DO NOTHING;
  END IF;

END $$;

-- =====================================================
-- STEP 5: Add indexes for better performance
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_workout_plans_goal ON public.workout_plans(fitness_goal);
CREATE INDEX IF NOT EXISTS idx_workout_plans_frequency ON public.workout_plans(weekly_frequency);
CREATE INDEX IF NOT EXISTS idx_workout_sessions_day ON public.workout_sessions(day_of_week);
CREATE INDEX IF NOT EXISTS idx_exercises_difficulty ON public.exercises(difficulty_level);

-- =====================================================
-- STEP 6: Grant proper permissions
-- =====================================================

-- Ensure authenticated users can read all workout data
GRANT SELECT ON public.workout_plans TO authenticated;
GRANT SELECT ON public.workout_sessions TO authenticated;
GRANT SELECT ON public.session_exercises TO authenticated;
GRANT SELECT ON public.exercises TO authenticated;
GRANT SELECT ON public.workout_categories TO authenticated;

-- =====================================================
-- Success message
-- =====================================================
DO $$
BEGIN
  RAISE NOTICE '✅ Comprehensive workout data populated successfully';
  RAISE NOTICE '✅ Categories: % rows', (SELECT COUNT(*) FROM public.workout_categories);
  RAISE NOTICE '✅ Plans: % rows', (SELECT COUNT(*) FROM public.workout_plans);
  RAISE NOTICE '✅ Sessions: % rows', (SELECT COUNT(*) FROM public.workout_sessions);
  RAISE NOTICE '✅ Exercises: % rows', (SELECT COUNT(*) FROM public.exercises);
END $$;