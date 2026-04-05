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
| `workout_set_logs` | Per-set data for a live session — `workout_log_id`, `session_exercise_id`, `exercise_id`, `set_number`, `reps`, `weight_kg` (nullable for bodyweight), `is_completed` |

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

**Thinking model gotcha:** `gemini-2.5-flash` is a thinking model — thought parts consume `maxOutputTokens` budget. `GeminiClient.createChat` reads the last non-thought part from the response. For structured output (JSON), use `maxTokens: 8192` minimum to avoid truncation.

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
| `signUp(email, password, fullName, captchaToken?)` | Creates Supabase auth user; passes captchaToken when hCaptcha is enabled |
| `signIn(email, password)` | Returns `AuthResponse` |
| `signOut()` | Clears cache + session + biometric pref |
| `getCurrentUser()` | Returns `User?` from Supabase auth |
| `isAuthenticated()` | Returns `bool` |
| `resendConfirmationEmail(email)` | Resends email verification link (OtpType.signup) |
| `refreshSession()` | Refreshes JWT and returns updated User (used to check emailConfirmedAt) |
| `resetPassword(email)` | Sends password reset email via Supabase |
| `updatePassword(newPassword)` | Updates password for logged-in user |
| `deleteAccount(email, password)` | Re-auths → calls `delete_my_account()` RPC → signs out |

Auth state stream: `SupabaseService.instance.client.auth.onAuthStateChange`
Used in `AuthenticationOnboardingFlow` to react to login/logout + `passwordRecovery` events.

---

## BiometricService (M20)

Wraps `local_auth` for fingerprint/Face ID.

```dart
final bio = BiometricService();
await bio.isAvailable()             // bool — device supports biometrics
await bio.authenticate('reason')    // bool — prompts biometric/PIN
await bio.isBiometricEnabled        // bool — stored in SharedPreferences
await bio.setBiometricEnabled(true) // persist preference
```

---

## MfaService (M20)

Wraps Supabase MFA API for TOTP two-factor authentication.

```dart
final mfa = MfaService();
await mfa.enrollTotp()              // returns {qrUri, secret, factorId}
await mfa.verifyEnrollment(factorId: id, code: '123456')
await mfa.listFactors()             // List<Factor>
await mfa.unenroll(factorId)        // disable 2FA
await mfa.isTotpEnabled             // bool
await mfa.verifiedFactorId          // String? — first verified factor ID
await mfa.needsMfaChallenge()       // bool — aal1 but aal2 required
```

**Critical gotchas:**
- `enroll()` REQUIRES `issuer: 'SmartFitAI'` — omitting it throws `ArgumentError: expected an issuer for totp factor type`
- `enrollTotp()` returns `qrUri = totp.uri` (the `otpauth://totp/...` URI, ~100 chars) — this is what `QrImageView(data: ...)` needs
- `totp.qrCode` is an SVG data URI (~2 MB) — passing it to `QrImageView` causes `QrInputTooLongException` (limit is 23648 chars)
- Wrap `QrImageView` in a `SizedBox(width: N, height: N)` — the widget doesn't constrain itself and crashes with infinite height inside `SingleChildScrollView`

---

## SessionService (M20)

Wraps `FlutterSecureStorage` for refresh token persistence and "remember me" preference.

```dart
final session = SessionService();
await session.persistSession(supabaseSession)     // store refresh token
await session.loadPersistedSession()              // restore session on cold start → User?
await session.clearSession()                      // wipe on sign-out
await session.rememberMe                          // bool (default true)
await session.setRememberMe(false)                // persist preference
```

---

## AppCacheService (M19)

Singleton in-memory cache with per-field TTL. Usage pattern:
```dart
// Read (returns null on miss or expiry)
final cached = AppCacheService.instance.getExerciseLibrary();
if (cached != null) { /* use cache */ return; }

// Write
AppCacheService.instance.setExerciseLibrary(data);

// Invalidate on mutation
AppCacheService.instance.invalidateContributions();
```
Food search uses LRU via `LinkedHashMap` — evicts oldest when `>= 20` entries. `invalidateAll()` clears everything (call on sign-out). Body measurements and strength PRs cache fields exist but are not yet wired to screens.

---

## WorkoutService / NutritionService

Standard CRUD services for workout sessions and nutrition logs.
Both follow the same pattern: scope all queries by `user_id`, add `.timeout(15s)`, wrap in try/catch.
`WorkoutService` uses explicit column projections (no `select('*')`) on all list queries (M19). `NutritionService` applies `.limit(50)` on `getUserMeals()` and `getMyContributions()` (M19).

**`WorkoutService.saveCompletedWorkout({sessionId, durationSeconds, setLogs})`** (added M10):
- Calculates `total_volume_kg` (sum of weight_kg × reps for completed sets)
- INSERTs `workout_logs` row → gets `workout_log_id`
- Batch-INSERTs all valid set logs into `workout_set_logs`
- Calls `_autoDetectPRs()`, returns `{'workoutLog': Map, 'newPRs': List}`

**`WorkoutService._autoDetectPRs(userId, setLogs, sessionId)`** (private, M10):
- Groups completed set logs by `exercise_id`, finds max `weight_kg` per exercise
- Compares against existing `strength_progress` max; INSERTs new row if PR beaten
- Returns list of new PR maps `{exercise_id, weight_kg, reps}`

**`WorkoutService.getWorkoutSetLogs(workoutLogId)`** (added M10):
- SELECTs from `workout_set_logs` joined with `exercises` ordered by `session_exercise_id, set_number`

**`WorkoutService.getPlanIdForSession(sessionId)`** (added M10):
- SELECTs `plan_id` from `workout_sessions` WHERE `id = sessionId`

**`NutritionService.submitUserFood(Map food)`** (added M17):
- Inserts with `is_user_contributed = true`, `contributed_by = currentUser.id`, `is_verified = false`
- Stores `detailed_macros` JSONB if present — 22-field shape (see OCR schema below); `calories` must be `.round()` before insert
- Returns full inserted row

**`NutritionService.updateFoodNutrition(String foodId, Map updates)`** (added M17 OCR upgrade):
- UPDATE any food_database row (RLS: any authenticated user — policy `authenticated_can_update_food`)
- Sets `updated_at` automatically; rounds `calories` to integer
- Returns full updated row

**`NutritionService.getMyContributions()`** (added M17):
- Selects from `food_database` where `contributed_by = currentUser.id`, ordered by `created_at DESC`

**`NutritionService.deleteContribution(String foodId)`** (added M17):
- Deletes a contributed food by id; RLS enforces own-rows-only

**`NutritionService.cacheExternalFood(Map externalFood)`** (added M16):
- Strips the `_source` UI key before writing to DB
- Upserts on `(name, brand)` unique constraint — returns existing row if already cached
- Always returns the full DB row including `id` — use this id for `logMeal()`
- Called from `AddFoodModalWidget._addFood()` when `_source != 'Local'`

**`detailed_macros` JSONB schema (M17 OCR upgrade — 22 fields):**
All values per 100g/100ml. Any key can be null (omitted means not on label).
`sugar_g`, `starch_g`, `polyols_g`, `fiber_g` — carb breakdown
`saturated_fat_g`, `monounsaturated_fat_g`, `polyunsaturated_fat_g`, `trans_fat_g` — fat breakdown
`cholesterol_mg`, `sodium_mg`, `salt_g`, `potassium_mg` — minerals
`calcium_mg`, `iron_mg`, `vitamin_a_ug`, `vitamin_c_mg`, `vitamin_d_ug` — vitamins
Old records may have `unsaturated_fat_g` — display handles both old and new shape.

**`food_database` column types (critical — do not get wrong):**
- `calories` → `integer` — always call `.round()` before inserting, never pass a double
- `brand` → `text nullable` — store `null` (not `''`) when brand is empty; affects `UNIQUE(name,brand)` deduplication
- `image_front_url` → `text nullable` — added M16; stores product image URL from OFF

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

## FoodRecognitionService (M18)

File: `food_recognition_service.dart` — Gemini Vision ingredient detection from food photos.

Singleton. Sends base64-encoded image to Gemini 2.5 Flash (temperature 0.1, maxTokens 8192) with a structured prompt requesting JSON array of `{name, estimated_quantity_g, category}`.

```dart
final service = FoodRecognitionService();
final result = await service.recognizeIngredients(imageBytes);
// result.ingredients → List<DetectedIngredient>
```

45-second timeout. Strips markdown code fences before JSON parse.
Categories: `protein`, `carb`, `fat`, `vegetable`, `fruit`, `dairy`, `condiment`.

---

## SmartRecipeService (M18)

File: `smart_recipe_service.dart` — AI recipe generation from detected ingredients.

Singleton. Generates 3–5 diverse protein-rich recipes using ONLY detected ingredients. Fetches user TDEE from `user_profiles.daily_calorie_goal` (best-effort — works without profile).

```dart
final service = SmartRecipeService();
final result = await service.generateRecipes(ingredients);
// result.recipes → List<GeneratedRecipe>
```

Gemini 2.5 Flash (temperature 0.7, maxTokens 8192). 45-second timeout.
Water, salt, pepper, cooking oil are assumed available (not required in photo).

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
| `open_food_facts_service.dart` | Barcode lookup (`lookupBarcode`) + text search (`searchFoods`) via Open Food Facts API (no key required) |
| `usda_food_service.dart` | Text search via USDA FoodData Central (`USDA_API_KEY` in env.json); returns `[]` gracefully if key absent |
| `gemini_nutrition_label_service.dart` | 2-step OCR pipeline: ML Kit on-device text recognition → Gemini 2.5 Flash text parsing; falls back to Gemini Vision if ML Kit fails; 22-field schema; `extractNutritionLabel(Uint8List, {String? imagePath})` |
| `food_recognition_service.dart` | Gemini 2.5 Flash Vision — detects food ingredients from photos; returns `FoodRecognitionResult` with `List<DetectedIngredient>` |
| `smart_recipe_service.dart` | Gemini AI recipe generation from detected ingredients; fetches user TDEE for macro targeting; returns `RecipeGenerationResult` with `List<GeneratedRecipe>` |
| `app_cache_service.dart` | In-memory TTL cache singleton (M19). Caches: profile (10min), streak (5min), nutrition (5min), exercise library (30min), body measurements (5min), strength PRs (5min), food search LRU (3min, max 20 entries via LinkedHashMap), contributions (5min). Call `invalidateAll()` on sign-out. |
| `exercise_db_service.dart` | Free-exercise-db CDN lookup — resolves exercise name to animation frame URLs |
