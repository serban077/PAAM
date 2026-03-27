-- M10: Workout Session Live Tracking
-- Add total_volume_kg to workout_logs for quick summary access
ALTER TABLE public.workout_logs ADD COLUMN IF NOT EXISTS total_volume_kg NUMERIC NULL DEFAULT 0;

-- Per-set logging table: one row per completed set during a live workout
CREATE TABLE IF NOT EXISTS public.workout_set_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workout_log_id UUID NOT NULL REFERENCES public.workout_logs(id) ON DELETE CASCADE,
  session_exercise_id UUID NOT NULL REFERENCES public.session_exercises(id),
  exercise_id UUID NOT NULL REFERENCES public.exercises(id),
  set_number INTEGER NOT NULL CHECK (set_number >= 1),
  reps INTEGER NOT NULL CHECK (reps >= 0 AND reps <= 200),
  weight_kg NUMERIC NULL CHECK (weight_kg >= 0),
  is_completed BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(workout_log_id, session_exercise_id, set_number)
);

ALTER TABLE public.workout_set_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own set logs"
ON public.workout_set_logs
FOR ALL
USING (
  workout_log_id IN (
    SELECT id FROM public.workout_logs WHERE user_id = auth.uid()
  )
)
WITH CHECK (
  workout_log_id IN (
    SELECT id FROM public.workout_logs WHERE user_id = auth.uid()
  )
);
