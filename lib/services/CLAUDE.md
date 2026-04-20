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

**Stored procedure `generate_workout_plan(user_profile_id)`** — uses English enum values; called from `OnboardingSurveyWidget._saveOnboardingData`.

---

## GeminiAIService

File: `gemini_ai_service.dart` — read before any AI work.

Generates workout + nutrition plans. `GeminiClient.createChat(messages, model, maxTokens, temperature, cancelToken?)` handles retry internally (`_withRetry`, 3 attempts, 2s/4s/6s backoff). `AppLogInterceptor` added M26 (debug only).

Prompt engineering lives in `gemini_ai_service.dart` — do not duplicate elsewhere.
Gemini API key: `const String.fromEnvironment('GEMINI_API_KEY')`

**Thinking model gotcha:** `gemini-2.5-flash` — thought parts consume `maxOutputTokens` budget. Use `maxTokens: 8192` minimum for JSON output to avoid truncation.

---

## AINutritionService

File: `ai_nutrition_service.dart` — nutrition-specific AI calls.
Calls Gemini with nutrition-focused prompts. Uses `CalorieCalculatorService` for TDEE.

---

## CalorieCalculatorService

Pure math — no I/O. BMR (Mifflin-St Jeor) × activity multiplier = TDEE. Macros split by user goal.

## BodyMeasurementsService

Reads/writes `body_measurements`. Always scope to `user_id`. `getMeasurementHistory(type, limit)` delegates to `getMeasurements(measurementType: type, limit: limit)`.

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
final cached = AppCacheService.instance.getExerciseLibrary();
if (cached != null) { /* use cache */ return; }
AppCacheService.instance.setExerciseLibrary(data);
AppCacheService.instance.invalidateContributions(); // after mutation
```
Food search LRU (3 min, max 20). `invalidateAll()` on sign-out.

**M26 additions:**
- `getExternalFoodSearch(query)` / `setExternalFoodSearch(query, results)` — OFF+USDA combined, 10 min LRU-20
- `getVisionResult(imageKey)` / `setVisionResult(imageKey, ingredients)` — Gemini Vision result, 10 min; key is `_imageKey()` fingerprint from `PhotoRecipeScreen`

---

## WorkoutService / NutritionService

Standard CRUD services. Pattern: scope all queries by `user_id`, `.timeout(15s)`, wrap in try/catch.
`WorkoutService` uses explicit column projections on all list queries. `NutritionService` applies `.limit(50)` on `getUserMeals()` and `getMyContributions()`.

Key methods:
- `WorkoutService.saveCompletedWorkout({sessionId, durationSeconds, setLogs})` — INSERTs `workout_logs` + `workout_set_logs`, calls `_autoDetectPRs()`, returns `{'workoutLog', 'newPRs'}`
- `WorkoutService.getWorkoutSetLogs(workoutLogId)` — SELECTs from `workout_set_logs` joined with `exercises`
- `NutritionService.submitUserFood(Map food)` — inserts `is_user_contributed=true`; `calories` must be `.round()`; stores `detailed_macros` JSONB (22-field schema)
- `NutritionService.updateFoodNutrition(foodId, updates)` — UPDATE any food row (any authenticated user via RLS)
- `NutritionService.cacheExternalFood(Map food)` — strips `_source` key; upserts on `(name, brand)` unique constraint; returns full DB row with `id`

**`detailed_macros` JSONB (22 fields, all per 100g, any key nullable):** carbs: `sugar_g/starch_g/polyols_g/fiber_g`; fats: `saturated/mono/polyunsaturated/trans_fat_g`; minerals: `cholesterol_mg/sodium_mg/salt_g/potassium_mg`; vitamins: `calcium_mg/iron_mg/vitamin_a_ug/c_mg/d_ug`. Old records may have `unsaturated_fat_g` — display handles both shapes.

**`food_database` critical column types:** `calories` → `integer` (always `.round()`); `brand` → `text nullable` (`null` not `''` — affects `UNIQUE(name,brand)`); `image_front_url` → `text nullable`.

**Calorie formula (critical — do not change):** `kcal = food.calories * serving_quantity / serving_size`
Must stay in sync in 3 places: Supabase RPC `calculate_daily_nutrition_totals`, `SimpleMealCard.totalCalories`, `main_dashboard_initial_page._loadDashboardData`.

---

## FoodRecognitionService (M18)

File: `food_recognition_service.dart` — Gemini Vision ingredient detection from food photos.

Singleton. Sends base64-encoded image to Gemini 2.5 Flash (temperature 0.1, maxTokens 8192).

```dart
final result = await FoodRecognitionService().recognizeIngredients(
  imageBytes,
  cancelToken: cancelToken, // M26: optional — cancel if user leaves screen
);
// result.ingredients → List<DetectedIngredient>
```

45-second timeout. Throws `NetworkOfflineException` when offline. Strips markdown code fences before JSON parse.
Categories: `protein`, `carb`, `fat`, `vegetable`, `fruit`, `dairy`, `condiment`.

---

## SmartRecipeService (M18)

File: `smart_recipe_service.dart` — AI recipe generation from detected ingredients.

Singleton. Generates 3–5 recipes; fetches user TDEE (best-effort, works without profile). Throws `NetworkOfflineException` when offline (M26).

```dart
final result = await SmartRecipeService().generateRecipes(ingredients);
// result.recipes → List<GeneratedRecipe>
```

Gemini 2.5 Flash (temperature 0.7, maxTokens 8192). 45-second timeout.

---

## Network Resilience Patterns (M26)

All external HTTP services (`OpenFoodFactsService`, `UsdaFoodService`, `FoodRecognitionService`, `SmartRecipeService`) now share utilities from `_dio_interceptors.dart`:

```dart
// Offline fast-fail — call at top of any external-API method
await assertConnected(); // throws NetworkOfflineException immediately

// Retry on network errors / 5xx (NOT 4xx, NOT cancel, NOT offline)
return await withRetry(() async { ... }, maxRetries: 3, baseDelay: Duration(milliseconds: 500));

// CancelToken — cancel previous in-flight request when user types new query
CancelToken? _token;
_token?.cancel();
_token = CancelToken();
await service.searchFoods(query, cancelToken: _token);
```

`GeminiAIService` already has its own `_withRetry()` (2s/4s/6s backoff) — do not replace it; it just gained `AppLogInterceptor` in M26.

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
| `app_cache_service.dart` | In-memory TTL cache singleton (M19/M26). profile (5min), streak (10min), nutrition (5min), exercise (30min), measurements (5min), PRs (5min), food search LRU (3min/20), external search LRU (10min/20), vision result (10min), contributions (5min). Call `invalidateAll()` on sign-out. |
| `exercise_db_service.dart` | Free-exercise-db CDN lookup — resolves exercise name to animation frame URLs |
| `_dio_interceptors.dart` | M26 shared Dio utilities: `AppLogInterceptor` (debug only), `NetworkOfflineException`, `assertConnected()` (throws if offline), `withRetry<T>(fn, maxRetries, baseDelay)` (exp backoff, skips 4xx + cancel) |
