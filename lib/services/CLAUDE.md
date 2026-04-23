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

Generates workout + nutrition plans. `GeminiClient.createChat(messages, model, maxTokens, temperature, cancelToken?, responseMimeType?, responseSchema?)` handles retry internally (`_withRetry`, 3 attempts, 2s/4s/6s backoff). `AppLogInterceptor` added M26 (debug only).

Prompt engineering lives in `gemini_ai_service.dart` — do not duplicate elsewhere.
Gemini API key: `const String.fromEnvironment('GEMINI_API_KEY')`

**Thinking model gotcha:** `gemini-2.5-flash` — thought parts consume `maxOutputTokens` budget. Use `maxTokens: 8192` minimum for JSON output to avoid truncation.

**Structured output (M28):** Pass `responseMimeType: 'application/json'` + `responseSchema: {...}` to `createChat()` to eliminate free-text JSON extraction. Schema uses Gemini's OpenAPI subset (uppercase types: `STRING`, `INTEGER`, `NUMBER`, `ARRAY`, `OBJECT`). Add `'nullable': true` to optional numeric fields. All plan/recipe/vision calls now use structured output.

**AI plan cache (M28):** `generateWeeklyWorkoutPlan` and `generateNutritionPlan` check `AppCacheService` before calling Gemini. Cache key = djb2 hash of user's fitness-affecting profile fields (goal, frequency, equipment, etc.), 24h TTL. `generateCompletePlan` fetches user profile once and passes it to both generators to avoid the former double Supabase round-trip.

**SDK decision (M28):** No migration to `google_generative_ai` package. Custom `GeminiClient` is sufficient — it already has retry, cancel, v1beta routing, thinking-part filtering, and structured output via `generationConfig`.

**M32 Model assignments:**

| Call | Model | maxTokens |
|---|---|---|
| `generateWeeklyWorkoutPlan` | gemini-2.5-flash-lite | 8192 |
| `generateNutritionPlan` | gemini-2.5-flash-lite | 8192 |
| `getPersonalizedExercises` | gemini-2.5-flash-lite | 8192 |
| `streamWeeklyWorkoutPlan` / `createChatStream` default | gemini-2.5-flash-lite | 8192 |
| `FoodRecognitionService.recognizeIngredients` | gemini-2.5-flash | 2048 |
| `SmartRecipeService.generateRecipes` | gemini-2.5-flash | 8192 |
| `GeminiNutritionLabelService` text path | gemini-2.5-flash-lite | 4096 |
| `GeminiNutritionLabelService` vision fallback | gemini-2.5-flash | 4096 |

Flash-Lite is ~5× cheaper per token than Flash. Flash-Lite is NOT suitable for multimodal (image) calls — always use Flash for those.

**Note on model upgrades:** The Google AI Studio UI may label models as "Gemini 3.x" but the actual API model ID differs. Always verify the exact API model ID string (e.g. via `ListModels` or the API documentation) before changing model strings — the UI name ≠ the API endpoint name. `_requiresV1Beta` routes `preview`/`exp`/`thinking`/`imagen-` models through `/v1beta`; stable `gemini-2.5-*` models use `/v1`.

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
`WorkoutService` uses explicit column projections on all queries — **never** `select('*')` or bare `select()`. `NutritionService` applies `.limit(50)` on `getUserMeals()` and `getMyContributions()`.

**Supabase RPC — `calculate_user_streak(p_user_id uuid) RETURNS integer` (M27):**
Replaces the former 365-row client-side streak loop in `main_dashboard_initial_page.dart`.
```dart
final result = await SupabaseService.instance.client
    .rpc('calculate_user_streak', params: {'p_user_id': userId})
    .timeout(const Duration(seconds: 15));
return (result as int?) ?? 0;
```
Function is `STABLE`, `SECURITY DEFINER`, `SET search_path = public, pg_catalog`. Backed by `idx_workout_logs_user_completed (user_id, completed_at DESC)`.

**N+1 patterns — never introduce these (M27):**
- Do NOT `await` inside a `for` loop over DB rows — use `Future.wait(list.map(...))` for parallel resolution
- Do NOT insert rows one-by-one in a loop — collect into `List<Map>`, then single `.insert(list)` call
- Example fix: `ProgressPhotoService.getUserPhotos()` — parallel signed URL resolution via `Future.wait`
- Example fix: `WorkoutService._autoDetectPRs()` — batch `strength_progress` insert after collecting all PR rows

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

## FoodRecognitionService (M18, rewritten M32)

File: `food_recognition_service.dart` — Gemini Vision ingredient detection from food photos.

Singleton. Sends base64-encoded image to Gemini 2.5 Flash (temperature 0.1, maxTokens 2048).

```dart
final result = await FoodRecognitionService().recognizeIngredients(
  imageBytes,
  cancelToken: cancelToken, // M26: optional — cancel if user leaves screen
);
// result.ingredients → List<DetectedIngredient>
```

45-second timeout. Throws `NetworkOfflineException` when offline.
Categories: `protein`, `carb`, `fat`, `vegetable`, `fruit`, `dairy`, `condiment`.

**Prompt source (M32):** assembled from `kFoodRecognitionPrompt` in `_ai_prompts.dart` — do NOT inline the prompt text. The prompt is split into atomic documentation sections (ROLE / TASK / OUTPUT FIELD SPEC / IDENTIFICATION RULES / QUANTITY ESTIMATION TABLE / AMBIGUITY PROTOCOL / CATEGORY MAPPING / FEW-SHOT EXAMPLES) so the model does one thing per section.

---

## SmartRecipeService (M18, rewritten M32)

File: `smart_recipe_service.dart` — AI recipe generation from detected ingredients.

Singleton. Generates up to 3 recipes; `_fetchUserContext` pulls `daily_calorie_goal` + `fitness_goal` + `dietary_preference` from `user_profiles` (best-effort — works without profile). Throws `NetworkOfflineException` when offline (M26).

```dart
final result = await SmartRecipeService().generateRecipes(ingredients);
// result.recipes → List<GeneratedRecipe>
```

Gemini 2.5 Flash (temperature 0.7, maxTokens 8192). 120-second timeout.

**Prompt source (M32):** prompt is built by `buildRecipePrompt()` in `_ai_prompts.dart` — do NOT inline policy. The prompt enforces:
- Hard per-serving constraints (`RecipeConstraints`): protein ≥ 25g (35g muscle_gain), fat ≤ 20g (25g muscle_gain), sat fat ≤ 5g, added sugar ≤ 10g, sodium ≤ 600mg, fiber ≥ 5g
- Ingredient blocklist (`kBlockedIngredients`)
- Per-100g macro guards (`kMacroGuardsPer100g`)
- Preferred sources bias (`kPreferredSources`)
- Taste boosters (`kTasteBoosters`) — methods never include deep-frying
- Dietary overrides (vegan / vegetarian / gluten_free / dairy_free)

Recipe names / descriptions / steps are emitted in Romanian; ingredient names stay lowercase English to match `DetectedIngredient.name`.

**Extended schema (M32):** every recipe additionally returns `warning` (nullable string), `macro_compliance` (bool, true iff every hard constraint passed), `blocklisted_ingredients_skipped` (array of blocked items the client had but were refused), `protein_density` (g protein per 100 kcal). Consumed by `GeneratedRecipe.fromMap` with safe defaults; UI surface deferred to M33.

---

## AnalyticsService (M29)

File: `analytics_service.dart` — PostHog product analytics singleton.

```dart
// Initialize once in main() after Supabase init
await AnalyticsService.instance.initialize();

// After sign-in
await AnalyticsService.instance.identify(userId);

// Fire an event (no-op if opted out or not initialized)
unawaited(AnalyticsService.instance.track('event_name', {'key': value}));

// Fire once per lifetime (SharedPreferences flag guard)
unawaited(AnalyticsService.instance.trackFirstOnce(
  'first_ai_plan_generated',
  'analytics_first_ai_plan_generated',
));

// On sign-out
await AnalyticsService.instance.reset();

// Opt-out (SecuritySettingsScreen toggle)
await AnalyticsService.instance.setOptOut(true);
```

**PostHog 4.x gotchas:**
- No native `optOut()` / `optIn()` methods — opt-out is SharedPreferences-only (`_isOptedOut` bool checked before every `track()` call)
- EU-hosted: `https://eu.posthog.com` (GDPR-friendly)
- API key: `const String.fromEnvironment('POSTHOG_API_KEY')`

**7 tracked funnel events:**

| Event | File | Trigger |
|---|---|---|
| `signup_started` | `register_form_widget.dart` | Form submit tap |
| `onboarding_completed` | `onboarding_survey_widget.dart` | After `_saveOnboardingData()` |
| `first_ai_plan_generated` | `ai_workout_generator.dart` | After plan saved; fires once via `trackFirstOnce` |
| `first_workout_logged` | `active_workout_session.dart` | After `saveCompletedWorkout()`; fires once |
| `first_meal_logged` | `nutrition_planning_screen.dart` | After first `logMeal()`; fires once |
| `photo_recipe_generated` | `photo_recipe_screen.dart` | After recipes step loads; every use |
| `barcode_scanned` | `barcode_scanner_page.dart` | After barcode resolved (found or not found) |

---

## Sentry Patterns (M29)

```dart
import 'dart:async';
import 'package:sentry_flutter/sentry_flutter.dart';

// In catch blocks — always capture stack trace
} catch (e, stack) {
  unawaited(Sentry.captureException(e, stackTrace: stack,
      hint: Hint.withMap({'service': 'MyService', 'method': 'methodName'})));
  rethrow; // or setState error
}

// Performance transaction around a slow operation
final txn = Sentry.startTransaction('operation-name', 'task');
try {
  // ... do work ...
  txn.status = const SpanStatus.ok();
  return result;
} catch (e, stack) {
  txn.status = const SpanStatus.internalError();
  unawaited(Sentry.captureException(e, stackTrace: stack));
  rethrow;
} finally {
  await txn.finish();
}
```

Active transactions: `ai-workout-plan` (gemini_ai_service), `ai-nutrition-plan` (gemini_ai_service), `food-recognition` (food_recognition_service).

PII scrubbing: `beforeSend` in `main.dart` strips `user` from every event — no email/identity in Sentry.

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
| `_ai_prompts.dart` | M32 shared AI policy constants + prompt fragments: `kBlockedIngredients`, `kMacroGuardsPer100g`, `kPreferredSources`, `kTasteBoosters`, `kQuantityReferenceG`, `RecipeConstraints`, `kFoodRecognitionPrompt`, `buildRecipePrompt({ingredientLines, macroContext, fitnessGoal, dietaryPreference})`. Single source of truth — update here, never inline in callers. |
| `analytics_service.dart` | M29 PostHog singleton — `track()`, `trackFirstOnce()`, `identify()`, `reset()`, `setOptOut()`. SharedPreferences-based opt-out. EU-hosted. |

---

## Testing Services (M30)

**Pure-logic services** (no I/O): test directly — no mocks. `CalorieCalculatorService` all-static; `AppCacheService` singleton — call `AppCacheService.instance.invalidateAll()` in `setUp()` to reset between tests.

**Supabase-dependent services** (`AuthService`, `NutritionService`, etc.): field initializers call `SupabaseService.instance.client` at construction, which throws if Supabase is not initialized. Pattern for widget tests that load these screens:
```dart
setUpAll(() async {
  SharedPreferences.setMockInitialValues({});
  try { await Supabase.initialize(url: 'https://test.supabase.co', anonKey: 'eyJ...placeholder'); } catch (_) {}
});
```
Unit tests for these services are deferred (M30 partial) — require complex mocking of the singleton pattern.
