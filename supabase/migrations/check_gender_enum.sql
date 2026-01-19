-- Check gender enum values
SELECT enumlabel 
FROM pg_enum 
WHERE enumtypid = 'gender'::regtype
ORDER BY enumsortorder;
