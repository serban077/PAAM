-- Allow any authenticated user to correct nutritional data on any food
-- (university project — community corrections are encouraged)
CREATE POLICY "authenticated_can_update_food"
ON public.food_database
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);
