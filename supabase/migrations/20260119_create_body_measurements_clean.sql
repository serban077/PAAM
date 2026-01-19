-- Drop and recreate body_measurements table
-- Run this in Supabase SQL Editor

-- Drop existing table and related objects
DROP TABLE IF EXISTS body_measurements CASCADE;
DROP FUNCTION IF EXISTS update_body_measurements_updated_at() CASCADE;

-- Create table
CREATE TABLE body_measurements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    measurement_type TEXT NOT NULL,
    value NUMERIC NOT NULL,
    measured_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX idx_body_measurements_user_id ON body_measurements(user_id);
CREATE INDEX idx_body_measurements_type ON body_measurements(measurement_type);
CREATE INDEX idx_body_measurements_date ON body_measurements(measured_at DESC);

-- Enable RLS
ALTER TABLE body_measurements ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view own measurements"
    ON body_measurements FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own measurements"
    ON body_measurements FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own measurements"
    ON body_measurements FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own measurements"
    ON body_measurements FOR DELETE
    USING (auth.uid() = user_id);

-- Create update trigger function
CREATE OR REPLACE FUNCTION update_body_measurements_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
CREATE TRIGGER update_body_measurements_updated_at_trigger
    BEFORE UPDATE ON body_measurements
    FOR EACH ROW
    EXECUTE FUNCTION update_body_measurements_updated_at();

-- Verify
SELECT column_name, data_type 
FROM information_schema.columns
WHERE table_name = 'body_measurements'
ORDER BY ordinal_position;
