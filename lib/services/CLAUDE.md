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
| `nutrition_logs` | Daily food entries per user |
| `body_measurements` | Weight, chest, waist, hips, arms — timestamped |
| `user_profiles` | Extended user info beyond Supabase auth |

Get current user ID: `SupabaseService.instance.client.auth.currentUser!.id`

---

## GeminiAIService

File: `gemini_ai_service.dart` (918 lines) — read before any AI work.

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

Reads/writes to `body_measurements` Supabase table. Most recently added service (M7).
Always scope queries to `user_id` — never fetch all users' measurements.

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
