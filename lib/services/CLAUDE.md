# lib/services/ — Service Layer Conventions

Read this file when working on any service, Supabase query, or Gemini AI call.

---

## Service Pattern

All services are plain Dart classes — no dependency injection, instantiated directly in screens.

```dart
class MyService {
  final SupabaseClient _client = SupabaseService.instance.client;

  Future<Something> doThing() async {
    try {
      final response = await _client
          .from('table_name')
          .select()
          .eq('user_id', _client.auth.currentUser!.id)
          .timeout(const Duration(seconds: 15));
      return Something.fromMap(response);
    } catch (error) {
      throw Exception('doThing failed: $error');
    }
  }
}
```

Rules:
- NEVER access `SupabaseService` directly — always `SupabaseService.instance.client`
- ALWAYS add `.timeout(const Duration(seconds: 15))` to every async call
- ALWAYS wrap in `try/catch` and rethrow with a descriptive message
- NEVER put Supabase queries in screens — services only

---

## Supabase Tables Reference

| Table | Purpose |
|---|---|
| `onboarding_responses` | User fitness profile from onboarding survey (checked for completion at login) |
| `workouts` | Saved workout sessions |
| `workout_exercises` | Exercises within a workout session |
| `user_meals` | Daily food entries per user; `meal_type` uses Romanian keys: `mic_dejun`, `pranz`, `cina`, `gustare_dimineata`; `serving_quantity` stores **actual grams/ml** (not a multiplier) |
| `food_database` | Global food lookup — `name`, `calories`, `protein_g`, `carbs_g`, `fat_g`, `serving_size`, `serving_unit`, `barcode`, `is_verified`; 363 verified rows seeded (M14) |
| `body_measurements` | Body measurements — `measurement_type` (head/neck/shoulders/chest/waist/hips/arm/forearm/thigh/calf/**weight**), `value` cm or kg, `measured_at`. Weight is logged here on every profile save (type=`weight`, value=kg). |
| `user_profiles` | Extended user info beyond Supabase auth; notification flags, nutrition goals |
| `strength_progress` | PR entries — `user_id`, `exercise_id`, `session_id`, `weight_kg`, `reps` |
| `user_workout_schedules` | Links user to active plan (`plan_id`, `is_active`) |
| `workout_sessions` | Sessions within a plan — `name`, `day_number`, `focus_area`, `estimated_duration_minutes` |
| `session_exercises` | Exercises within a session — `sets`, `reps_min`, `reps_max`, `order_in_session` |

Get current user ID: `SupabaseService.instance.client.auth.currentUser!.id`

**Enum values are fully English** (migrated 2026-03-25). Never use Romanian strings for enum columns:
- `fitness_goal`: `weight_loss`, `muscle_gain`, `maintenance`, `toning`, `endurance`, `body_recomposition`, `flexibility`, `general_fitness`
- `activity_level`: `sedentary`, `lightly_active`, `moderately_active`, `very_active`, `extremely_active`
- `equipment_type`: `gym`, `home_no_equipment`, `home_basic_equipment`, `mix`
- `dietary_preference`: `normal`, `vegetarian`, `vegan`, `gluten_free`, `dairy_free`
- `gender`: `male`, `female`, `other`, `prefer_not_to_say`

**Stored procedure `generate_workout_plan(user_profile_id)`** — RPC that creates a `workout_plans` row + sessions. Called from `OnboardingSurveyWidget._saveOnboardingData`. Its CASE statement uses English enum values — do not revert to Romanian.

---

## GeminiAIService

File: `gemini_ai_service.dart` — read before any AI work.

Generates both workout and nutrition plans in a single call. Returns `AIPlanResponse`.

```dart
final geminiService = GeminiAIService();
final plan = await geminiService.generatePersonalizedPlan(
  userProfile: onboardingData,   // Map from onboarding_responses
  focusArea: 'full_body',
  durationWeeks: 4,
);
// plan.trainingPlan.days → List<WorkoutDay>
// plan.nutritionPlan.dailyCalories → int
```

Prompt engineering is inside `gemini_ai_service.dart` — do not duplicate prompts elsewhere.
Gemini API key: `const String.fromEnvironment('GEMINI_API_KEY')`

---

## AINutritionService

File: `ai_nutrition_service.dart` — nutrition-specific AI calls (food search, meal adjustments).
Calls Gemini with nutrition-focused prompts. Uses `CalorieCalculatorService` for TDEE.

---

## CalorieCalculatorService

Pure calculation service — no API calls, no Supabase. TDEE formula:
- BMR (Mifflin-St Jeor) × activity multiplier = TDEE
- Macros split based on user goal (bulk / cut / maintain)

---

## BodyMeasurementsService

Reads/writes to `body_measurements` Supabase table.
Always scope queries to `user_id` — never fetch all users' measurements.
`getMeasurementHistory(type, limit)` delegates to `getMeasurements(measurementType: type, limit: limit)`.

---

## ThemeService

File: `theme_service.dart` — static class, no instantiation needed.

```dart
await ThemeService.init();              // call once in main() before runApp
ThemeService.themeNotifier             // ValueNotifier<ThemeMode> — listen in MaterialApp
ThemeService.setDarkMode(true);        // persists to SharedPreferences
ThemeService.isDark                    // bool getter
```

`main.dart` wraps `MaterialApp` in `ValueListenableBuilder<ThemeMode>(valueListenable: ThemeService.themeNotifier, ...)`.
Profile screen uses its own `ValueListenableBuilder` for the toggle tile.

---

## AuthService

| Method | What it does |
|---|---|
| `signUp(email, password, fullName)` | Creates Supabase auth user + sets `full_name` in metadata |
| `signIn(email, password)` | Returns `AuthResponse` |
| `signOut()` | Clears session |
| `getCurrentUser()` | Returns `User?` from Supabase auth |
| `isAuthenticated()` | Returns `bool` |

Auth state stream: `SupabaseService.instance.client.auth.onAuthStateChange`
Used in `AuthenticationOnboardingFlow` to react to login/logout events.

---

## WorkoutService / NutritionService

Standard CRUD services for workout sessions and nutrition logs.
Both follow the same pattern: scope all queries by `user_id`, add `.timeout(15s)`, wrap in try/catch.

**Calorie formula (critical — do not change):**
```
kcal = food.calories * user_meals.serving_quantity / food.serving_size
```
- `serving_quantity` = actual amount in grams (or ml, or portions)
- `serving_size` = the reference amount the `calories` value is based on (e.g. 100 for 100g foods)
- Example: potato (87 kcal / 100g) logged at 150g → `87 * 150 / 100 = 130.5 kcal`
- AI meals use `serving_size = 1` (1 portion) and `serving_quantity = 1` → formula gives full calories

This formula is used in three places that must stay in sync:
1. Supabase RPC `calculate_daily_nutrition_totals` — fixed M14 (was multiplying instead of dividing)
2. `SimpleMealCard.totalCalories` getter (inline Dart)
3. `main_dashboard_initial_page.dart` `_loadDashboardData` inline loop

---

## Service Inventory

| File | Responsibility |
|---|---|
| `supabase_service.dart` | Singleton client init — source of `SupabaseService.instance.client` |
| `auth_service.dart` | Sign up / in / out / user state |
| `gemini_ai_service.dart` | All Gemini AI plan generation |
| `ai_nutrition_service.dart` | Nutrition-specific AI calls |
| `calorie_calculator_service.dart` | TDEE + macro math (no I/O) |
| `body_measurements_service.dart` | Body metrics CRUD |
| `nutrition_service.dart` | Food log CRUD |
| `workout_service.dart` | Workout session CRUD |
| `theme_service.dart` | Dark/light mode toggle — `ValueNotifier<ThemeMode>` + SharedPreferences |
