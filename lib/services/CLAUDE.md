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
| `user_meals` | Daily food entries per user; `meal_type` uses Romanian keys: `mic_dejun`, `pranz`, `cina`, `gustare_dimineata` |
| `food_database` | Global food lookup — `name`, `calories`, `protein_g`, `carbs_g`, `fat_g`, `barcode`, `is_verified` |
| `body_measurements` | Body measurements — `measurement_type` (head/neck/shoulders/chest/waist/hips/arm/forearm/thigh/calf), `value` cm, `measured_at` |
| `user_profiles` | Extended user info beyond Supabase auth; notification flags, nutrition goals |
| `strength_progress` | PR entries — `user_id`, `exercise_id`, `session_id`, `weight_kg`, `reps` |
| `user_workout_schedules` | Links user to active plan (`plan_id`, `is_active`) |
| `workout_sessions` | Sessions within a plan — `name`, `day_number`, `focus_area`, `estimated_duration_minutes` |
| `session_exercises` | Exercises within a session — `sets`, `reps_min`, `reps_max`, `order_in_session` |

Get current user ID: `SupabaseService.instance.client.auth.currentUser!.id`

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
