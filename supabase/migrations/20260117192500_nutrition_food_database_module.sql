-- Location: supabase/migrations/20260117192500_nutrition_food_database_module.sql
-- Schema Analysis: Existing fitness schema with user_profiles, workout_* tables
-- Integration Type: Addition - New nutrition tracking module
-- Dependencies: user_profiles, existing fitness enums

-- ========================================
-- 1. ENUMS & TYPES
-- ========================================

CREATE TYPE public.meal_type AS ENUM ('mic_dejun', 'gustare_dimineata', 'pranz', 'gustare_dupa_amiaza', 'cina', 'gustare_seara');

-- ========================================
-- 2. CORE FOOD DATABASE (MyFitnessPal-style)
-- ========================================

CREATE TABLE public.food_database (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    brand TEXT,
    serving_size NUMERIC NOT NULL,
    serving_unit TEXT NOT NULL DEFAULT 'g',
    calories INTEGER NOT NULL,
    protein_g NUMERIC NOT NULL,
    carbs_g NUMERIC NOT NULL,
    fat_g NUMERIC NOT NULL,
    fiber_g NUMERIC DEFAULT 0,
    sugar_g NUMERIC DEFAULT 0,
    sodium_mg NUMERIC DEFAULT 0,
    barcode TEXT,
    is_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ========================================
-- 3. USER MEAL TRACKING
-- ========================================

CREATE TABLE public.user_meals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    food_id UUID REFERENCES public.food_database(id) ON DELETE CASCADE,
    meal_type public.meal_type NOT NULL,
    serving_quantity NUMERIC NOT NULL DEFAULT 1,
    consumed_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.daily_nutrition_goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    calorie_goal INTEGER,
    protein_goal_g NUMERIC,
    carbs_goal_g NUMERIC,
    fat_goal_g NUMERIC,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, date)
);

-- ========================================
-- 4. INDEXES
-- ========================================

CREATE INDEX idx_food_database_name ON public.food_database(name);
CREATE INDEX idx_food_database_brand ON public.food_database(brand);
CREATE INDEX idx_food_database_barcode ON public.food_database(barcode);

CREATE INDEX idx_user_meals_user_id ON public.user_meals(user_id);
CREATE INDEX idx_user_meals_consumed_at ON public.user_meals(consumed_at);
CREATE INDEX idx_user_meals_meal_type ON public.user_meals(meal_type);

CREATE INDEX idx_daily_nutrition_goals_user_id ON public.daily_nutrition_goals(user_id);
CREATE INDEX idx_daily_nutrition_goals_date ON public.daily_nutrition_goals(date);

-- ========================================
-- 5. RLS POLICIES
-- ========================================

ALTER TABLE public.food_database ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_meals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_nutrition_goals ENABLE ROW LEVEL SECURITY;

-- Food database - public read, authenticated can add
CREATE POLICY "public_can_read_food_database"
ON public.food_database
FOR SELECT
TO public
USING (true);

CREATE POLICY "authenticated_can_add_food"
ON public.food_database
FOR INSERT
TO authenticated
WITH CHECK (true);

-- User meals - simple ownership
CREATE POLICY "users_manage_own_user_meals"
ON public.user_meals
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Daily nutrition goals - simple ownership
CREATE POLICY "users_manage_own_daily_nutrition_goals"
ON public.daily_nutrition_goals
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- ========================================
-- 6. COMPREHENSIVE ROMANIAN FOOD DATABASE
-- ========================================

DO $$
BEGIN
    -- Fructe
    INSERT INTO public.food_database (name, brand, serving_size, serving_unit, calories, protein_g, carbs_g, fat_g, fiber_g, sugar_g, is_verified) VALUES
    ('Măr', 'Generic', 100, 'g', 52, 0.3, 14, 0.2, 2.4, 10, true),
    ('Banană', 'Generic', 100, 'g', 89, 1.1, 23, 0.3, 2.6, 12, true),
    ('Portocală', 'Generic', 100, 'g', 47, 0.9, 12, 0.1, 2.4, 9, true),
    ('Struguri', 'Generic', 100, 'g', 69, 0.7, 18, 0.2, 0.9, 15, true),
    ('Căpșuni', 'Generic', 100, 'g', 32, 0.7, 8, 0.3, 2, 4.9, true),
    ('Pepene verde', 'Generic', 100, 'g', 30, 0.6, 8, 0.2, 0.4, 6, true),
    ('Pere', 'Generic', 100, 'g', 57, 0.4, 15, 0.1, 3.1, 10, true),
    ('Piersici', 'Generic', 100, 'g', 39, 0.9, 10, 0.3, 1.5, 8, true),
    ('Prune', 'Generic', 100, 'g', 46, 0.7, 11, 0.3, 1.4, 10, true),
    ('Kiwi', 'Generic', 100, 'g', 61, 1.1, 15, 0.5, 3, 9, true),

    -- Legume
    ('Roșii', 'Generic', 100, 'g', 18, 0.9, 3.9, 0.2, 1.2, 2.6, true),
    ('Castraveți', 'Generic', 100, 'g', 15, 0.7, 3.6, 0.1, 0.5, 1.7, true),
    ('Ardei gras', 'Generic', 100, 'g', 20, 0.9, 4.6, 0.2, 1.7, 2.4, true),
    ('Broccoli', 'Generic', 100, 'g', 34, 2.8, 7, 0.4, 2.6, 1.7, true),
    ('Morcovi', 'Generic', 100, 'g', 41, 0.9, 10, 0.2, 2.8, 4.7, true),
    ('Spanac', 'Generic', 100, 'g', 23, 2.9, 3.6, 0.4, 2.2, 0.4, true),
    ('Salată verde', 'Generic', 100, 'g', 15, 1.4, 2.9, 0.2, 1.3, 0.8, true),
    ('Ceapă', 'Generic', 100, 'g', 40, 1.1, 9, 0.1, 1.7, 4.2, true),
    ('Cartofi', 'Generic', 100, 'g', 77, 2, 17, 0.1, 2.2, 0.8, true),
    ('Vinete', 'Generic', 100, 'g', 25, 1, 6, 0.2, 3, 3.5, true),

    -- Carne și pește
    ('Piept de pui', 'Generic', 100, 'g', 165, 31, 0, 3.6, 0, 0, true),
    ('Carne de vita', 'Generic', 100, 'g', 250, 26, 0, 15, 0, 0, true),
    ('Carne de porc', 'Generic', 100, 'g', 242, 27, 0, 14, 0, 0, true),
    ('Somon', 'Generic', 100, 'g', 208, 20, 0, 13, 0, 0, true),
    ('Ton conservă', 'Generic', 100, 'g', 132, 28, 0, 1.3, 0, 0, true),
    ('Ouă', 'Generic', 100, 'g', 155, 13, 1.1, 11, 0, 1.1, true),
    ('Șuncă de pui', 'Generic', 100, 'g', 104, 21, 1, 1.6, 0, 0.6, true),
    ('Cârnați', 'Generic', 100, 'g', 301, 13, 2, 27, 0, 0.5, true),

    -- Lactate
    ('Lapte integral', 'Generic', 100, 'ml', 61, 3.2, 4.8, 3.3, 0, 5, true),
    ('Iaurt natural', 'Generic', 100, 'g', 59, 3.5, 4.7, 3.3, 0, 4.7, true),
    ('Brânză telemea', 'Generic', 100, 'g', 208, 17, 0.9, 15, 0, 0.9, true),
    ('Cașcaval', 'Generic', 100, 'g', 373, 23, 1.3, 30, 0, 0.5, true),
    ('Unt', 'Generic', 100, 'g', 717, 0.9, 0.1, 81, 0, 0.1, true),
    ('Smântână', 'Generic', 100, 'g', 193, 2.1, 3.4, 19, 0, 3.1, true),

    -- Cereale și pâine
    ('Pâine albă', 'Generic', 100, 'g', 265, 9, 49, 3.2, 2.7, 5, true),
    ('Pâine integrală', 'Generic', 100, 'g', 247, 13, 41, 3.4, 7, 6, true),
    ('Orez alb fiert', 'Generic', 100, 'g', 130, 2.7, 28, 0.3, 0.4, 0.1, true),
    ('Paste făinoase', 'Generic', 100, 'g', 131, 5, 25, 1.1, 1.8, 0.6, true),
    ('Fulgi de ovăz', 'Generic', 100, 'g', 389, 17, 66, 7, 11, 0.9, true),
    ('Cornflakes', 'Generic', 100, 'g', 357, 7.5, 84, 0.4, 3, 8, true),

    -- Snacks și dulciuri
    ('Ciocolată cu lapte', 'Generic', 100, 'g', 535, 7.6, 59, 30, 3.4, 51, true),
    ('Biscuiți simpli', 'Generic', 100, 'g', 502, 6.5, 68, 23, 2, 21, true),
    ('Chips cartofi', 'Generic', 100, 'g', 536, 7, 50, 35, 4.4, 0.4, true),
    ('Prăjitură', 'Generic', 100, 'g', 387, 4.6, 48, 19, 1.5, 29, true),

    -- Băuturi
    ('Suc de portocale natural', 'Generic', 100, 'ml', 45, 0.7, 10, 0.2, 0.2, 8.4, true),
    ('Cola', 'Generic', 100, 'ml', 42, 0, 10.6, 0, 0, 10.6, true),
    ('Apă minerală', 'Generic', 100, 'ml', 0, 0, 0, 0, 0, 0, true),
    ('Cafea neagră', 'Generic', 100, 'ml', 2, 0.3, 0, 0, 0, 0, true),
    ('Ceai verde', 'Generic', 100, 'ml', 1, 0, 0, 0, 0, 0, true),

    -- Leguminoase și nuci
    ('Fasole boabe fiartă', 'Generic', 100, 'g', 127, 8.7, 23, 0.5, 6.4, 0.3, true),
    ('Linte fiartă', 'Generic', 100, 'g', 116, 9, 20, 0.4, 7.9, 1.8, true),
    ('Năut fiert', 'Generic', 100, 'g', 164, 8.9, 27, 2.6, 7.6, 4.8, true),
    ('Migdale', 'Generic', 100, 'g', 579, 21, 22, 50, 13, 4.4, true),
    ('Nuci', 'Generic', 100, 'g', 654, 15, 14, 65, 6.7, 2.6, true),
    ('Alune', 'Generic', 100, 'g', 628, 15, 17, 61, 8.5, 4.8, true),
    ('Semințe floarea-soarelui', 'Generic', 100, 'g', 584, 21, 20, 51, 8.6, 2.6, true);
END $$;

-- ========================================
-- 7. HELPER FUNCTIONS
-- ========================================

-- Function to calculate daily nutrition totals
CREATE OR REPLACE FUNCTION public.calculate_daily_nutrition_totals(
    p_user_id UUID,
    p_date DATE
)
RETURNS TABLE(
    total_calories NUMERIC,
    total_protein_g NUMERIC,
    total_carbs_g NUMERIC,
    total_fat_g NUMERIC
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT
        SUM((fd.calories * um.serving_quantity * fd.serving_size / 100)::NUMERIC) as total_calories,
        SUM((fd.protein_g * um.serving_quantity * fd.serving_size / 100)::NUMERIC) as total_protein_g,
        SUM((fd.carbs_g * um.serving_quantity * fd.serving_size / 100)::NUMERIC) as total_carbs_g,
        SUM((fd.fat_g * um.serving_quantity * fd.serving_size / 100)::NUMERIC) as total_fat_g
    FROM public.user_meals um
    JOIN public.food_database fd ON um.food_id = fd.id
    WHERE um.user_id = p_user_id
      AND DATE(um.consumed_at) = p_date;
END;
$$;

-- Function to search food with autocomplete
CREATE OR REPLACE FUNCTION public.search_food(search_term TEXT)
RETURNS TABLE(
    id UUID,
    name TEXT,
    brand TEXT,
    calories INTEGER,
    protein_g NUMERIC,
    carbs_g NUMERIC,
    fat_g NUMERIC,
    serving_size NUMERIC,
    serving_unit TEXT
)
LANGUAGE sql
STABLE
AS $$
    SELECT 
        id, name, brand, calories, protein_g, carbs_g, fat_g, serving_size, serving_unit
    FROM public.food_database
    WHERE LOWER(name) LIKE LOWER('%' || search_term || '%')
       OR LOWER(brand) LIKE LOWER('%' || search_term || '%')
    ORDER BY 
        CASE 
            WHEN LOWER(name) = LOWER(search_term) THEN 1
            WHEN LOWER(name) LIKE LOWER(search_term || '%') THEN 2
            ELSE 3
        END,
        is_verified DESC,
        name
    LIMIT 50;
$$;