-- Migration: AI Nutrition Plans Table
-- Created: 2026-01-19
-- Purpose: Store AI-generated nutrition plans with persistence

-- Create table for AI nutrition plans
CREATE TABLE IF NOT EXISTS ai_nutrition_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  plan_data JSONB NOT NULL, -- Full AI plan in JSON format
  daily_calories_goal INT,
  generated_at TIMESTAMPTZ DEFAULT NOW(),
  is_active BOOLEAN DEFAULT true, -- Only one active plan per user
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index for fast lookup
CREATE INDEX IF NOT EXISTS idx_ai_nutrition_plans_user_active 
ON ai_nutrition_plans(user_id, is_active) 
WHERE is_active = true;

-- Enable Row Level Security
ALTER TABLE ai_nutrition_plans ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view own nutrition plans"
ON ai_nutrition_plans FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own nutrition plans"
ON ai_nutrition_plans FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own nutrition plans"
ON ai_nutrition_plans FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own nutrition plans"
ON ai_nutrition_plans FOR DELETE
USING (auth.uid() = user_id);

-- Function to deactivate old nutrition plans when a new one is created
CREATE OR REPLACE FUNCTION deactivate_old_nutrition_plans()
RETURNS TRIGGER AS $$
BEGIN
  -- Deactivate all old plans for this user
  UPDATE ai_nutrition_plans
  SET is_active = false, updated_at = NOW()
  WHERE user_id = NEW.user_id 
    AND id != NEW.id
    AND is_active = true;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically deactivate old plans
DROP TRIGGER IF EXISTS trigger_deactivate_old_nutrition_plans ON ai_nutrition_plans;
CREATE TRIGGER trigger_deactivate_old_nutrition_plans
AFTER INSERT ON ai_nutrition_plans
FOR EACH ROW
EXECUTE FUNCTION deactivate_old_nutrition_plans();

-- Add comment
COMMENT ON TABLE ai_nutrition_plans IS 'Stores AI-generated nutrition plans for users with automatic deactivation of old plans';
