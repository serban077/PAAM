-- Location: supabase/migrations/20260117171001_fitness_auth_module.sql
-- Schema Analysis: Empty database - creating fresh project schema
-- Integration Type: NEW_MODULE - Authentication and User Profiles
-- Dependencies: None (fresh project)

-- 1. Types and Enums
CREATE TYPE public.fitness_goal AS ENUM ('weight_loss', 'muscle_gain', 'endurance', 'flexibility', 'general_fitness');
CREATE TYPE public.experience_level AS ENUM ('beginner', 'intermediate', 'advanced');
CREATE TYPE public.gender AS ENUM ('male', 'female', 'other', 'prefer_not_to_say');

-- 2. Core Tables
CREATE TABLE public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL,
    avatar_url TEXT,
    date_of_birth DATE,
    gender public.gender,
    height_cm DECIMAL(5,2),
    weight_kg DECIMAL(5,2),
    fitness_goal public.fitness_goal,
    experience_level public.experience_level,
    target_weight_kg DECIMAL(5,2),
    onboarding_completed BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. Essential Indexes
CREATE INDEX idx_user_profiles_email ON public.user_profiles(email);
CREATE INDEX idx_user_profiles_onboarding ON public.user_profiles(onboarding_completed);

-- 4. RLS Setup
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies (Pattern 1: Core user table - Simple only, no functions)
CREATE POLICY "users_manage_own_user_profiles"
ON public.user_profiles
FOR ALL
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- 6. Trigger Function for Automatic Profile Creation
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
        avatar_url,
        date_of_birth,
        gender,
        height_cm,
        weight_kg,
        fitness_goal,
        experience_level,
        target_weight_kg,
        onboarding_completed
    )
    VALUES (
        NEW.id, 
        NEW.email, 
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'avatar_url', ''),
        CASE WHEN NEW.raw_user_meta_data->>'date_of_birth' IS NOT NULL 
             THEN (NEW.raw_user_meta_data->>'date_of_birth')::DATE 
             ELSE NULL END,
        CASE WHEN NEW.raw_user_meta_data->>'gender' IS NOT NULL 
             THEN (NEW.raw_user_meta_data->>'gender')::public.gender 
             ELSE NULL END,
        CASE WHEN NEW.raw_user_meta_data->>'height_cm' IS NOT NULL 
             THEN (NEW.raw_user_meta_data->>'height_cm')::DECIMAL 
             ELSE NULL END,
        CASE WHEN NEW.raw_user_meta_data->>'weight_kg' IS NOT NULL 
             THEN (NEW.raw_user_meta_data->>'weight_kg')::DECIMAL 
             ELSE NULL END,
        CASE WHEN NEW.raw_user_meta_data->>'fitness_goal' IS NOT NULL 
             THEN (NEW.raw_user_meta_data->>'fitness_goal')::public.fitness_goal 
             ELSE NULL END,
        CASE WHEN NEW.raw_user_meta_data->>'experience_level' IS NOT NULL 
             THEN (NEW.raw_user_meta_data->>'experience_level')::public.experience_level 
             ELSE NULL END,
        CASE WHEN NEW.raw_user_meta_data->>'target_weight_kg' IS NOT NULL 
             THEN (NEW.raw_user_meta_data->>'target_weight_kg')::DECIMAL 
             ELSE NULL END,
        COALESCE((NEW.raw_user_meta_data->>'onboarding_completed')::BOOLEAN, false)
    );
    RETURN NEW;
END;
$$;

-- 7. Trigger on auth.users
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 8. Mock Data for Testing
DO $$
DECLARE
    test_user1_id UUID := gen_random_uuid();
    test_user2_id UUID := gen_random_uuid();
BEGIN
    -- Create test auth users
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        created_at, updated_at, raw_user_meta_data, raw_app_meta_data,
        is_sso_user, is_anonymous, confirmation_token, confirmation_sent_at,
        recovery_token, recovery_sent_at, email_change_token_new, email_change,
        email_change_sent_at, email_change_token_current, email_change_confirm_status,
        reauthentication_token, reauthentication_sent_at, phone, phone_change,
        phone_change_token, phone_change_sent_at
    ) VALUES
        (test_user1_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'test.user@fitness.com', crypt('FitnessDemo123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Test User", "fitness_goal": "muscle_gain", "experience_level": "intermediate"}'::jsonb, 
         '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (test_user2_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'demo.athlete@fitness.com', crypt('AthleteDemo123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Demo Athlete", "fitness_goal": "endurance", "experience_level": "advanced"}'::jsonb, 
         '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null);
END $$;