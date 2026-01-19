-- Create body_measurements table for tracking body measurements
-- Run this in Supabase SQL Editor

-- Create table
CREATE TABLE IF NOT EXISTS body_measurements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    measurement_type TEXT NOT NULL, -- 'head', 'neck', 'shoulders', 'chest', 'waist', 'hips', 'arm', 'forearm', 'thigh', 'calf'
    value NUMERIC NOT NULL, -- value in cm
    measured_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Drop existing indexes if they exist
DROP INDEX IF EXISTS idx_body_measurements_user_id;
DROP INDEX IF EXISTS idx_body_measurements_type;
DROP INDEX IF EXISTS idx_body_measurements_date;
DROP INDEX IF EXISTS idx_body_measurements_user_type;

-- Add indexes for performance
CREATE INDEX idx_body_measurements_user_id ON body_measurements(user_id);
CREATE INDEX idx_body_measurements_type ON body_measurements(measurement_type);
CREATE INDEX idx_body_measurements_date ON body_measurements(measured_at DESC);
CREATE INDEX idx_body_measurements_user_type ON body_measurements(user_id, measurement_type);

-- Add comments
COMMENT ON TABLE body_measurements IS 'Stores user body measurements for progress tracking';
COMMENT ON COLUMN body_measurements.measurement_type IS 'Type of measurement: head, neck, shoulders, chest, waist, hips, arm, forearm, thigh, calf';
COMMENT ON COLUMN body_measurements.value IS 'Measurement value in centimeters';

-- Enable RLS
ALTER TABLE body_measurements ENABLE ROW LEVEL SECURITY;

-- RLS Policies
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

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_body_measurements_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS update_body_measurements_updated_at_trigger ON body_measurements;
CREATE TRIGGER update_body_measurements_updated_at_trigger
    BEFORE UPDATE ON body_measurements
    FOR EACH ROW
    EXECUTE FUNCTION update_body_measurements_updated_at();

-- Verify table was created
SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns
WHERE table_name = 'body_measurements'
ORDER BY ordinal_position;
