-- Location: supabase/migrations/20260117171003_fitness_nutrition_module.sql
-- Schema Analysis: Building upon authentication and workout modules
-- Integration Type: NEW_MODULE - Nutrition and Food Database
-- Dependencies: public.user_profiles

-- 1. Types and Enums
CREATE TYPE public.food_category AS ENUM ('grains', 'proteins', 'vegetables', 'fruits', 'dairy', 'fats', 'beverages', 'snacks', 'supplements');
CREATE TYPE public.meal_type AS ENUM ('breakfast', 'lunch', 'dinner', 'snack');

-- 2. Food Database Table (Global Romanian Foods)
CREATE TABLE public.food_database (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    name_ro TEXT NOT NULL,
    brand TEXT,
    category public.food_category NOT NULL,
    serving_size_g DECIMAL(8,2) NOT NULL,
    serving_unit TEXT NOT NULL DEFAULT 'g',
    calories DECIMAL(8,2) NOT NULL,
    protein_g DECIMAL(8,2) NOT NULL DEFAULT 0,
    carbs_g DECIMAL(8,2) NOT NULL DEFAULT 0,
    fats_g DECIMAL(8,2) NOT NULL DEFAULT 0,
    fiber_g DECIMAL(8,2) DEFAULT 0,
    sugar_g DECIMAL(8,2) DEFAULT 0,
    sodium_mg DECIMAL(8,2) DEFAULT 0,
    barcode TEXT,
    is_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. User Custom Foods Table
CREATE TABLE public.user_custom_foods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    category public.food_category NOT NULL,
    serving_size_g DECIMAL(8,2) NOT NULL,
    serving_unit TEXT NOT NULL DEFAULT 'g',
    calories DECIMAL(8,2) NOT NULL,
    protein_g DECIMAL(8,2) NOT NULL DEFAULT 0,
    carbs_g DECIMAL(8,2) NOT NULL DEFAULT 0,
    fats_g DECIMAL(8,2) NOT NULL DEFAULT 0,
    fiber_g DECIMAL(8,2) DEFAULT 0,
    sugar_g DECIMAL(8,2) DEFAULT 0,
    sodium_mg DECIMAL(8,2) DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 4. User Daily Nutrition Log
CREATE TABLE public.daily_nutrition_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    log_date DATE NOT NULL DEFAULT CURRENT_DATE,
    meal_type public.meal_type NOT NULL,
    food_id UUID REFERENCES public.food_database(id) ON DELETE SET NULL,
    custom_food_id UUID REFERENCES public.user_custom_foods(id) ON DELETE SET NULL,
    servings DECIMAL(8,2) NOT NULL DEFAULT 1,
    total_calories DECIMAL(8,2) NOT NULL,
    total_protein_g DECIMAL(8,2) NOT NULL,
    total_carbs_g DECIMAL(8,2) NOT NULL,
    total_fats_g DECIMAL(8,2) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT food_or_custom_food_check CHECK (
        (food_id IS NOT NULL AND custom_food_id IS NULL) OR
        (food_id IS NULL AND custom_food_id IS NOT NULL)
    )
);

-- 5. Essential Indexes
CREATE INDEX idx_food_database_name ON public.food_database USING gin(to_tsvector('romanian', name_ro));
CREATE INDEX idx_food_database_category ON public.food_database(category);
CREATE INDEX idx_food_database_barcode ON public.food_database(barcode) WHERE barcode IS NOT NULL;
CREATE INDEX idx_user_custom_foods_user ON public.user_custom_foods(user_id);
CREATE INDEX idx_user_custom_foods_name ON public.user_custom_foods USING gin(to_tsvector('romanian', name));
CREATE INDEX idx_daily_nutrition_log_user_date ON public.daily_nutrition_log(user_id, log_date);
CREATE INDEX idx_daily_nutrition_log_meal_type ON public.daily_nutrition_log(meal_type);

-- 6. RLS Setup
ALTER TABLE public.food_database ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_custom_foods ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_nutrition_log ENABLE ROW LEVEL SECURITY;

-- 7. RLS Policies
-- Pattern 4: Public Read for Food Database
CREATE POLICY "public_can_read_food_database"
ON public.food_database
FOR SELECT
TO public
USING (true);

-- Pattern 2: Simple User Ownership for Custom Foods
CREATE POLICY "users_manage_own_custom_foods"
ON public.user_custom_foods
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Pattern 2: Simple User Ownership for Nutrition Log
CREATE POLICY "users_manage_own_nutrition_log"
ON public.daily_nutrition_log
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- 8. Mock Data - Romanian Foods Database
DO $$
BEGIN
    INSERT INTO public.food_database (name, name_ro, brand, category, serving_size_g, serving_unit, calories, protein_g, carbs_g, fats_g, fiber_g, is_verified) VALUES
        -- Grains
        ('White Bread', 'Pâine Albă', 'Generic', 'grains'::public.food_category, 100, 'g', 265, 9, 49, 3.2, 2.7, true),
        ('Brown Rice', 'Orez Brun', 'Generic', 'grains'::public.food_category, 100, 'g', 112, 2.6, 24, 0.9, 1.8, true),
        ('Pasta', 'Paste', 'Generic', 'grains'::public.food_category, 100, 'g', 131, 5.1, 25, 1.1, 1.8, true),
        ('Polenta', 'Mămăligă', 'Generic', 'grains'::public.food_category, 100, 'g', 70, 1.5, 15, 0.3, 1.0, true),
        
        -- Proteins
        ('Chicken Breast', 'Piept de Pui', 'Generic', 'proteins'::public.food_category, 100, 'g', 165, 31, 0, 3.6, 0, true),
        ('Eggs', 'Ouă', 'Generic', 'proteins'::public.food_category, 50, 'bucată', 78, 6.3, 0.6, 5.3, 0, true),
        ('Pork', 'Carne de Porc', 'Generic', 'proteins'::public.food_category, 100, 'g', 242, 27, 0, 14, 0, true),
        ('Telemea Cheese', 'Telemea', 'Napolact', 'proteins'::public.food_category, 100, 'g', 230, 16, 2, 18, 0, true),
        ('Greek Yogurt', 'Iaurt Grecesc', 'Danone', 'dairy'::public.food_category, 150, 'g', 97, 10, 3.6, 5, 0, true),
        
        -- Vegetables
        ('Tomatoes', 'Roșii', 'Generic', 'vegetables'::public.food_category, 100, 'g', 18, 0.9, 3.9, 0.2, 1.2, true),
        ('Cucumber', 'Castraveți', 'Generic', 'vegetables'::public.food_category, 100, 'g', 16, 0.7, 3.6, 0.1, 0.5, true),
        ('Bell Peppers', 'Ardei Gras', 'Generic', 'vegetables'::public.food_category, 100, 'g', 20, 0.9, 4.6, 0.2, 1.7, true),
        ('Cabbage', 'Varză', 'Generic', 'vegetables'::public.food_category, 100, 'g', 25, 1.3, 5.8, 0.1, 2.5, true),
        
        -- Fruits
        ('Apples', 'Mere', 'Generic', 'fruits'::public.food_category, 100, 'g', 52, 0.3, 14, 0.2, 2.4, true),
        ('Bananas', 'Banane', 'Generic', 'fruits'::public.food_category, 100, 'g', 89, 1.1, 23, 0.3, 2.6, true),
        ('Watermelon', 'Pepene Verde', 'Generic', 'fruits'::public.food_category, 100, 'g', 30, 0.6, 8, 0.2, 0.4, true),
        
        -- Snacks
        ('Covrigi', 'Covrigi', 'Vel Pitar', 'snacks'::public.food_category, 50, 'bucată', 160, 5, 30, 2, 1.5, true),
        ('Chocolate Bar', 'Ciocolată', 'Milka', 'snacks'::public.food_category, 100, 'g', 530, 6.9, 59, 29, 2.3, true),
        
        -- Beverages
        ('Coffee', 'Cafea', 'Generic', 'beverages'::public.food_category, 240, 'ml', 2, 0.3, 0, 0, 0, true),
        ('Orange Juice', 'Suc de Portocale', 'Rauch', 'beverages'::public.food_category, 250, 'ml', 112, 1.7, 26, 0.5, 0.5, true);
END $$;