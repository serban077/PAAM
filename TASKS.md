# TASKS.md — SmartFitAI

Milestone-based task tracker. Mark tasks `[x]` as they are completed.
Update `## Current Status` in `CLAUDE.md` at the end of every session.

---

## Current Status

**Last updated:** 2026-03-31
**Last session completed:** M19 — Performance Optimization & Client-Side Caching (partial — core items done)
**Next session starts with:** M11 — Testing & Quality (widget tests + unit tests + flutter analyze clean)
**Active branches:** main
**Blockers / notes:** `pubspec.lock` gitignored — run `flutter pub get` at session start. PAAM/ folder untracked (check if needed for university submission). DB enum values are now fully English — do NOT reintroduce Romanian strings. `product_found_sheet.dart` is an unused untracked file — safe to delete. USDA_API_KEY is in env.json (not committed). Gemini 2.5 Flash thinking model needs maxTokens ≥ 8192 for OCR calls (thinking tokens consume budget). MuscleWiki GIFs now require paid API — exercise animations use free-exercise-db GitHub CDN instead. M19 note: AppCacheService has body measurements + strength PRs cache fields created but not yet wired to their screens — do in M19 continuation or M11.

---

## Legend

- `[x]` — Done
- `[ ]` — Not started
- `[~]` — In progress / partially done

---

## Milestone 1 — Project Foundation & Setup ✅

- [x] Initialize Flutter project with Dart SDK ^3.9.0
- [x] Configure `pubspec.yaml` with all core dependencies (Supabase, Sizer, Dio, Google Fonts, fl_chart)
- [x] Set up `env.json` pattern for API key injection via `--dart-define-from-file`
- [x] Configure `.vscode/launch.json` for debug / profile / release with env file
- [x] Enforce portrait-only orientation in `main.dart`
- [x] Lock `textScaler` to `1.0` to prevent accessibility text scaling from breaking layout
- [x] Set up custom `ErrorWidget` with 5-second debounce
- [x] Create `lib/theme/app_theme.dart` — full Material 3 light & dark theme (colors, typography, component themes)
- [x] Create `lib/routes/app_routes.dart` — centralized named routes
- [x] Create `lib/core/app_export.dart` — barrel export
- [x] Add `CustomIconWidget`, `CustomImageWidget`, `CustomErrorWidget`, `CustomAppBar`, `CustomBottomBar` to `lib/widgets/`
- [x] Initialize `SupabaseService` singleton with URL and anon key from environment

---

## Milestone 2 — Authentication & Onboarding ✅

- [x] Create `LoginScreen` with email/password form
- [x] Create `SignupScreen` with email, password, full name
- [x] Implement `AuthService` (signUp, signIn, signOut, getCurrentUser, isAuthenticated)
- [x] Add 15-second timeout to all auth calls
- [x] Create `OnboardingSurveyScreen` — multi-step questionnaire collecting fitness goals, level, dietary preferences, and physical stats
- [x] Create `AuthenticationOnboardingFlow` — state machine that:
  - Listens to Supabase auth state changes
  - Checks `onboarding_responses` table for completion
  - Routes to dashboard if complete, onboarding if not, login if unauthenticated
- [x] Commit uncommitted changes to `onboarding_survey_screen.dart` and `auth_service.dart`
- [x] Fix all DB enum values Romanian→English (fitness_goal, activity_level, equipment_type, dietary_preference, gender)
- [x] Fix `generate_workout_plan` stored procedure CASE statement (Romanian enum refs crashed after migration)
- [x] Fix Recalibrate Plan: Step 5 auto-populate from profile data, add weight log to body_measurements
- [x] Set up Supabase MCP server (project-scoped, PAT auth)

---

## Milestone 3 — AI Core (Gemini Integration) ✅

- [x] Create `GeminiAIService` — handles all Gemini API calls via Dio
- [x] Define prompt engineering for workout plan generation
- [x] Define prompt engineering for nutrition plan generation
- [x] Create `AIPlanModels` data models: `AIPlanResponse`, `TrainingPlan`, `Exercise`, `NutritionPlan`, `Meal`, `MealOption`
- [x] Create `AIWorkoutGenerator` screen — UI for requesting a custom workout plan with user parameters
- [x] Create `AINutritionPlanner` screen — UI for requesting a custom meal plan
- [x] Create `AINutritionService` for nutrition-specific AI logic
- [x] Create `CalorieCalculatorService` for TDEE and macro calculations
- [x] Add retry logic for Gemini API failures (currently fails silently)
- [x] Add loading skeleton while AI generates plans (currently shows spinner)

---

## Milestone 4 — Main Dashboard ✅

- [x] Create `MainDashboard` — bottom navigation shell with nested `Navigator`
- [x] Create `MainDashboardInitialPage` — home tab showing daily plan overview
- [x] Implement `CustomBottomBar` with 5 tabs: Home / Workouts / Nutrition / Progress / Profile
- [x] Wire bottom nav tabs to correct routes in exact order
- [x] Dashboard home tab: show today's workout card (linked to AI-generated plan)
- [x] Dashboard home tab: show today's meal summary (calories, macros) — wired to real Supabase data
- [x] Dashboard home tab: show weekly progress ring / streak indicator

---

## Milestone 5 — Exercise Library ✅

- [x] Create static exercise database in `verified_exercises_data.dart`
- [x] Create `ExerciseLibrary` screen with grid/list of exercises
- [x] Create `ExerciseCardWidget` with image, name, target muscles, equipment
- [x] Fix overflow bug in skeleton card
- [x] Create `ExerciseDetailsScreen` — shows sets, reps, rest time for a session
- [x] Add search bar with real-time filter by name
- [x] Add filter chips for muscle group and equipment type
- [x] Integrate `youtube_player_flutter` to show exercise demo video on detail screen

---

## Milestone 6 — Nutrition Planning ✅

- [x] Create `NutritionPlanningScreen` — manual food tracking interface
- [x] Create `NutritionService` for CRUD operations on Supabase nutrition table
- [x] Implement food search (search by name, return macros) — debounced Supabase ilike query
- [x] Implement `mobile_scanner` barcode scan to look up food by barcode
- [x] Add daily calorie and macro progress bars (using fl_chart or linear indicators)
- [x] Display AI-generated meal plan in nutrition tab
- [x] Allow marking individual meals as eaten — circular checkbox with strikethrough

---

## Milestone 7 — Progress & Measurements Tracking ✅

- [x] Create `ProgressTrackingScreen` with fl_chart charts (weight over time, workouts per week)
- [x] Create `StrengthProgressScreen` for tracking personal records per exercise
- [x] Create `BodyMeasurementsService` for storing body measurements in Supabase
- [x] Add body measurements tracking UI (chest, waist, hips, arms, etc.)
- [x] Connect body measurements to fl_chart LineChart with metric selector chips
- [x] Add before/after photo comparison using `before_after` widget (draggable divider)
- [x] Show PR (personal record) badges on strength exercises — amber badge with trophy icon

---

## Milestone 8 — User Profile ✅

- [x] Create `UserProfileManagement` screen — display and edit profile info
- [x] Show user name, email, fitness goals from onboarding
- [x] Allow editing profile fields (goal, fitness level, dietary preference)
- [x] Allow updating physical stats (weight, height) and recalculating TDEE
- [x] Add sign-out button with confirmation dialog
- [x] Add dark mode toggle — ValueNotifier<ThemeMode> in ThemeService, persisted to SharedPreferences

---

## Milestone 9 — UI Polish & Localization

- [x] Replace all Romanian UI strings with English equivalents
  - [x] `CustomBottomBar` labels, `AuthenticationOnboardingFlow`, `OnboardingSurveyWidget`
  - [x] `NutritionPlanningScreen`, `ProgressTrackingScreen`, `BodyMeasurementsCard`
  - [x] `UserProfileManagement` widgets, `AccountManagementSectionWidget`
  - [x] `AIWorkoutGenerator`, `AINutritionPlanner`, `ExerciseLibrary`, `StrengthProgressScreen`
  - [x] `PhotoProgressWidget`, `SimpleMealCard`, `AIMealPlanSection`, `FoodSearchDialog`
- [x] Add empty states for all screens that load data (no workouts yet, no meals yet, etc.)
- [x] Add pull-to-refresh on all list screens
- [x] Add proper loading shimmer skeletons (replace all `CircularProgressIndicator` for data loads >300ms)
- [x] Ensure all tap targets are at minimum 44×44pt
- [x] Review and fix any remaining layout overflow issues on small screens (375px width)
- [x] Add haptic feedback (`HapticFeedback.lightImpact()`) to primary actions (already on bottom nav)
- [x] Implement app splash screen / icon assets in `assets/`
- [x] Redesign login & signup screens with gradient hero + floating card pattern
- [x] Redesign AuthenticationOnboardingFlow with matching gradient + tab switcher
- [x] Remove AI tagline from auth hero sections and splash screen
- [x] Redesign home page (MainDashboardInitialPage) with gradient header + floating card matching auth
- [x] Fix raw `Colors.blue`/`Colors.green` in dashboard metric cards → theme colors

---

## Milestone 10 — Workout Session Live Tracking ✅

- [x] Create `ActiveWorkoutSession` screen — live view of current workout
- [x] Show current exercise, next exercise, rest timer countdown
- [x] Log completed sets (reps + weight) per exercise
- [x] Save completed session to Supabase with exercises and performance data
- [x] Navigate to session summary screen after workout completion
- [x] Connect completed sessions to `StrengthProgressScreen` to update PRs automatically

---

## Milestone 11 — Testing & Quality

> `flutter_test` dependency is installed but no test files exist yet.

- [ ] Write widget tests for `LoginScreen` (form validation)
- [ ] Write widget tests for `OnboardingSurveyScreen` (step navigation)
- [ ] Write unit tests for `CalorieCalculatorService` (TDEE formula)
- [ ] Write unit tests for `AuthService` (mock Supabase client)
- [ ] Write integration smoke test: launch app → check login screen renders
- [ ] Run `flutter analyze` with zero warnings before M12

---

## Milestone 12 — PAAM Academic Documentation

> Deadline: **19.01.2026** (W14). Documentation: 3–7 pages, Times New Roman 12, 1–1.15 spacing, justified text.

- [x] Create `documentation.md` template with all required sections
- [ ] Section 1 — Introduction: finalize "What?" and "Why?" paragraphs in English
- [ ] Section 2 — State of the Art: expand Fitbod / Freeletics comparison table with SmartFitAI's unique advantages (AI nutrition planning, no ads)
- [ ] Section 3 — Design & Implementation: add UML use case diagram, architecture diagram, list all key libraries with justification
- [ ] Section 4 — System Usage: add real app screenshots (Dashboard, AI Generator, Nutrition) with captions (Fig. 1, Fig. 2, ...)
- [ ] Section 5 — Conclusions: add what was learned, what was hard, what worked well
- [ ] Add References section with Fitbod, Freeletics, Flutter docs, Supabase docs, Gemini API docs
- [ ] Export to Word/PDF with correct formatting (A4, Times New Roman 12, page numbers)
- [ ] Add team member names to title page

---

## Milestone 13 — Release Build Preparation

- [ ] Add final app icon (all sizes for Android and iOS)
- [ ] Add native splash screen (replace default Flutter splash)
- [ ] Set correct `applicationId` / `bundleIdentifier` in Android/iOS configs
- [ ] Test release APK on physical Android device
- [ ] Test release build on iOS simulator
- [ ] Verify `env.json` secrets are NOT included in the final build artifact
- [ ] Set `minSdkVersion` and `targetSdkVersion` in `android/app/build.gradle.kts`
- [ ] Configure ProGuard / R8 rules for release build if needed

---

## Milestone 14 — Nutrition Screen Overhaul

> Deep improvements to the Nutrition tab: richer food database, correct calorie math, smarter AI-plan integration, and a cleaner Home page.

### 14.1 — Food Database Expansion ✅
- [x] Write Supabase migration to pre-populate `food_database` with 200+ common foods — 363 verified rows inserted across breakfast, proteins, carbs, vegetables, fruits, dairy, nuts/seeds, Romanian dishes, fast food, snacks, beverages, condiments
- [x] Calorie multiplier formula verified: `calories * (serving_quantity / serving_size)` is correct and consistent with how `AddFoodModalWidget` saves quantities

### 14.2 — AI Plan → Meal Type Picker ✅
- [x] Replace the hard-coded `mealTypeMap` lookup in `ai_meal_plan_section.dart` `_addOptionToDay()`
- [x] When user taps "Add to Today" on an AI meal option, show a `showModalBottomSheet` with 4 meal type chips: Breakfast / Lunch / Dinner / Snack (mapped to DB enums)
- [x] If user cancels, abort the insert (null check + mounted guard)

### 14.3 — Home Page Unique Content ✅
- [x] **Remove** the "Nutrition" section from `main_dashboard_initial_page.dart` (NutritionSummaryWidget + import)
- [x] **Add: Workout Streak card** — queries `workout_logs` for consecutive days; flame icon; "No streak yet" state
- [x] **Add: Daily Fitness Tip** — static list of 30 tips; rotated by `dayOfYear % 30`; lightbulb icon
- [x] **Add: TDEE Snapshot card** — `daily_calorie_goal` + `activity_level` from already-loaded `_userProfile`; activity level pill

### 14.4 — Calorie Formula Hotfix ✅
- [x] Fix RPC `calculate_daily_nutrition_totals`: formula was `calories * serving_quantity * serving_size / 100` (wrong — multiplied instead of divided). Fixed to `calories * serving_quantity / serving_size`
- [x] Fix `AddFoodModalWidget`: now accepts grams directly (default = food's serving_size, e.g. 100 for 100g foods). `serving_quantity` stored in DB is now raw grams, not a multiplier. Formula in preview and RPC are now consistent.

---

## Milestone 15 — Barcode Scanner: Open Food Facts Integration

> Replace the Supabase-only barcode lookup with the free Open Food Facts API (3 M+ products), add a scan cooldown, and create a polished product-found flow identical to apps like Eat & Track.

### 15.1 — OpenFoodFactsService
- [x] Create `lib/services/open_food_facts_service.dart`
  - Method `Future<Map<String, dynamic>?> lookupBarcode(String barcode)`
  - URL: `https://world.openfoodfacts.org/api/v0/product/{barcode}.json` (no API key required)
  - Parse response: extract `product_name`, `nutriments.energy-kcal_100g`, `nutriments.proteins_100g`, `nutriments.carbohydrates_100g`, `nutriments.fat_100g`, `serving_size` (default to 100g if absent), `image_front_url`
  - Wrap in `try/catch` + `.timeout(const Duration(seconds: 15))`
  - Return `null` if status != 1 or product not found

### 15.2 — Barcode Lookup Flow (Supabase → OFF → Not Found)
- [x] Update `BarcodeScannerPage._onBarcodeDetected()` lookup order:
  1. Query local `food_database` (Supabase) by `barcode` column — instant hit for cached items
  2. If not found, call `OpenFoodFactsService.lookupBarcode(barcode)`
  3. If found via OFF: insert product into Supabase `food_database` (`is_verified = false`, `barcode` = scanned value) and return the new row — **cache for next time**
  4. If still not found: pop scanner and show "Product not found" SnackBar on NutritionPlanningScreen
- [x] `barcode` column already present in `food_database` — no migration needed

### 15.3 — Scan Cooldown & Camera Control
- [x] Camera stops immediately (`_controller.stop()`) on first barcode detection — no infinite scan loop
- [x] On error: camera resumes and state resets so user can retry
- [x] `_lastBarcode` guard prevents duplicate detections

### 15.4 — ProductFoundScreen (full page — changed from bottom sheet per UX feedback)
- [x] Create `lib/presentation/nutrition_planning_screen/widgets/product_found_screen.dart`
  - Full Scaffold page (not bottom sheet) — pushed via `Navigator.pushReplacement` from scanner
  - Product image (`CustomImageWidget`), name, brand
  - Macro chips row: kcal / Protein / Carbs / Fat (per 100g)
  - Quantity `TextFormField` with live calorie + macro preview
  - Meal type `ChoiceChip` selector (Breakfast / Lunch / Dinner / Snack)
  - Fixed "Add to Meal" CTA at bottom — calls `NutritionService.logMeal()`, refreshes parent

### 15.5 — Scanner UX Polish
- [x] Animated scan-line inside guide rectangle (`AnimationController`, 2 s repeat-reverse)
- [x] Status chip shows lookup progress ("Looking up barcode…" / "Searching Open Food Facts…")
- [x] Permission-denied empty state: icon + "Camera permission required" + "Open Settings" button

---

## Milestone 16 — Food Database: External API Search Integration

> Extend the food search bar (currently queries only the 363-row local Supabase table) to fetch results from Open Food Facts (text search) and USDA FoodData Central, giving users access to millions of real foods with accurate macronutrients.

### 16.1 — Open Food Facts Text Search
- [x] Add text search method to `OpenFoodFactsService` (created in M15):
  - Method `Future<List<Map<String, dynamic>>> searchFoods(String query, {int page = 1})`
  - URL: `https://world.openfoodfacts.org/cgi/search.pl?search_terms={query}&json=1&page_size=20&page={page}`
  - Parse each product: `product_name`, `nutriments.energy-kcal_100g`, `nutriments.proteins_100g`, `nutriments.carbohydrates_100g`, `nutriments.fat_100g`, `serving_size` (default 100g if absent), `image_front_url`
  - Filter out results with missing `energy-kcal_100g` (unusable)
  - Wrap in `try/catch` + `.timeout(const Duration(seconds: 15))`

### 16.2 — USDA FoodData Central Integration
- [x] Create `lib/services/usda_food_service.dart`
  - API key stored in `env.json` as `USDA_API_KEY` (registered and active)
  - Method `Future<List<Map<String, dynamic>>> searchFoods(String query)`
  - URL: `https://api.nal.usda.gov/fdc/v1/foods/search?query={query}&api_key={key}&pageSize=20`
  - Parse `foods[].description`, `foods[].foodNutrients` (nutrient IDs: 1008=kcal, 1003=protein, 1005=carbs, 1004=fat)
  - Graceful fallback: returns `[]` immediately if key is absent
  - Wrap in `try/catch` + `.timeout(const Duration(seconds: 15))`

### 16.3 — Unified Food Search in NutritionPlanningScreen
- [x] Updated `AddFoodModalWidget` (the active search widget) with **3-tier lookup**:
  1. Query local Supabase `food_database` (instant, shown first)
  2. OFF + USDA always run in parallel in background (no threshold — always fires)
  3. Results appended with source badge chips: Local / Open Food Facts / USDA
- [x] Deduplicate results by normalized `name|brand` key — local takes priority
- [x] Cache any externally-fetched food into Supabase `food_database` (`is_verified = false`) on first use via `NutritionService.cacheExternalFood()`
- [x] DB migration: added `UNIQUE(name, brand)` constraint + deduplicated existing rows + added `image_front_url TEXT` column

### 16.4 — Pagination & UX
- [x] "Load more results" button at bottom of search list (triggers next OFF page)
- [x] Shimmer skeleton (AnimationController) while external APIs are fetching — local results visible immediately
- [x] Empty state: "No results found. Try a different spelling or scan the barcode." / "Start searching for foods"

---

## Milestone 17 — Community Food Database: User Contributions + Nutritional Label OCR

> Allow users to add missing products to the shared food database by scanning the barcode and photographing the nutritional label. Gemini Vision extracts macros automatically. Products added by any user become available to all users on next barcode scan — the database grows with every contribution.

### 17.1 — DB Schema: Extended Food Contributions ✅
- [x] Supabase migration: add `contributed_by UUID REFERENCES auth.users(id) NULL` to `food_database`
- [x] Supabase migration: add `is_user_contributed BOOLEAN NOT NULL DEFAULT false` to `food_database`
- [x] Supabase migration: add `detailed_macros JSONB NULL` — stores extended nutrition per 100g: `{ sugar, saturated_fat, unsaturated_fat, fiber, sodium }` (values that are not in the main columns)
- [x] Add RLS policy: authenticated users can INSERT rows with `contributed_by = auth.uid()`; can UPDATE/DELETE only rows where `contributed_by = auth.uid()`

### 17.2 — GeminiNutritionLabelService (Vision OCR) ✅
- [x] `image_picker: ^1.0.4` already in `pubspec.yaml` — no change needed
- [x] Create `lib/services/gemini_nutrition_label_service.dart`
  - Method `Future<Map<String, dynamic>?> extractNutritionLabel(Uint8List imageBytes)`
  - Encodes image to base64, calls Gemini multimodal API (`gemini-1.5-flash`) with inline image part
  - System prompt: instructs the model to return STRICT JSON with keys `calories`, `protein_g`, `carbs_g`, `sugar_g`, `fat_g`, `saturated_fat_g`, `unsaturated_fat_g`, `fiber_g`, `sodium_mg`, `serving_size_g` — all values per 100g, null if not found on label
  - Validates JSON shape before returning; returns `null` on parse failure or missing critical fields (`calories`, `protein_g`, `carbs_g`, `fat_g`)
  - Wrap in `try/catch` + `.timeout(const Duration(seconds: 30))` (Vision calls are slower than text)

### 17.3 — ProductNotFoundScreen ✅
- [x] Create `lib/presentation/nutrition_planning_screen/widgets/product_not_found_screen.dart`
  - Full Scaffold page (pushed via `Navigator.pushReplacement` from scanner when all lookup tiers fail)
  - Shows scanned barcode value, "No product found for this barcode" heading
  - Two CTAs: "Scan Again" (pops back to scanner) and "Add This Product" (pushes `UserFoodSubmissionScreen` with `barcode` argument)

### 17.4 — UserFoodSubmissionScreen (3-step wizard) ✅
- [x] Create `lib/presentation/user_food_submission_screen/user_food_submission_screen.dart`
- [x] Step 1 — Product Info: name + brand TextFormFields; barcode pre-filled read-only; "Next" validates
- [x] Step 2 — Label Photo: camera/gallery pick; Gemini Vision extraction with shimmer loading; "Enter Manually" skip
- [x] Step 3 — Review & Submit: required macro fields + optional detailed nutrition ExpansionTile; "Submit Product" validates and calls submitUserFood()
- [x] On submit: navigates to ProductFoundScreen with newly inserted row
- [x] Route `AppRoutes.userFoodSubmission` registered in `app_routes.dart` via `onGenerateRoute`

### 17.5 — Barcode Flow Update: "Not Found → Contribute" ✅
- [x] Update `BarcodeScannerPage._onBarcodeDetected()`: when all lookup tiers return null, push `ProductNotFoundScreen` (replaces pop with kNotFound sentinel)

### 17.6 — NutritionService: submitUserFood() & getMyContributions() ✅
- [x] `submitUserFood()` — inserts with is_user_contributed=true, contributed_by, is_verified=false; stores detailed_macros JSONB; returns inserted row
- [x] `getMyContributions()` — selects where contributed_by = current uid, ordered by created_at DESC
- [x] `deleteContribution()` — deletes by id (RLS enforces own-rows-only)

### 17.7 — Detailed Macros Display in ProductFoundScreen ✅
- [x] `_DetailedMacrosExpansion` widget: ExpansionTile hidden when detailed_macros is null; shows sugar, saturated fat, unsaturated fat, fiber, sodium — per 100g and scaled to entered quantity
- [x] "User Added" Chip badge when `is_user_contributed = true`

### 17.8 — "My Contributions" in User Profile ✅
- [x] "My Food Contributions" ListTile with count badge in UserProfileManagement; count refreshes on return
- [x] Create `lib/presentation/user_food_submission_screen/my_contributions_screen.dart` — shimmer skeleton, swipe-to-delete with confirm dialog, empty state, pull-to-refresh
- [x] Route `AppRoutes.myFoodContributions` registered in `app_routes.dart`

---

## Milestone 18 — Smart Photo-to-Recipe Generator ✅

> Star feature: user photographs food items from fridge/table → Gemini Vision detects ingredients → app generates protein-rich recipes using ONLY those ingredients → user logs a recipe as a meal with full macro breakdown.

### 18.1 — Data Models
- [x] Create `lib/data/models/smart_recipe_models.dart`
  - `DetectedIngredient` (name, estimatedQuantityG, category)
  - `FoodRecognitionResult` (ingredients list, rawResponse)
  - `RecipeIngredientLine` (ingredientName, quantityG, displayUnit)
  - `GeneratedRecipe` (name, description, prepTime, cookTime, servings, difficulty, ingredients, steps, macrosPerServing)
  - `RecipeGenerationResult` (recipes list, rawResponse)
  - All classes: `fromMap()` + `toMap()` constructors

### 18.2 — FoodRecognitionService (Gemini Vision)
- [x] Create `lib/services/food_recognition_service.dart`
  - Method `Future<FoodRecognitionResult> recognizeIngredients(Uint8List imageBytes)`
  - Base64-encode image → Gemini 2.5 Flash multimodal call (temperature 0.1, maxTokens 8192)
  - Prompt: identify all food items, return JSON array with name/estimated_quantity_g/category
  - Parse response → `FoodRecognitionResult`
  - try/catch + `.timeout(const Duration(seconds: 45))`

### 18.3 — SmartRecipeService (Recipe Generation)
- [x] Create `lib/services/smart_recipe_service.dart`
  - Method `Future<RecipeGenerationResult> generateRecipes(List<DetectedIngredient> ingredients)`
  - Fetches user TDEE/macro goals via `CalorieCalculatorService`
  - Text-only Gemini call (temperature 0.7, maxTokens 8192)
  - Prompt: generate 3-5 diverse protein-rich recipes using ONLY the listed ingredients; include gram amounts + macros per serving
  - Parse response → `RecipeGenerationResult`
  - try/catch + `.timeout(const Duration(seconds: 45))`

### 18.4 — PhotoRecipeScreen: Wizard Shell
- [x] Create `lib/presentation/photo_recipe_screen/photo_recipe_screen.dart`
  - PageView + PageController + NeverScrollableScrollPhysics (same pattern as UserFoodSubmissionScreen)
  - 4 steps: Capture → Ingredients Review → Recipes → Log Meal
  - Step indicator widget at top
  - Back button per step (pops on step 1)

### 18.5 — Step 1: Capture Photo
- [x] Create `lib/presentation/photo_recipe_screen/widgets/capture_step.dart`
  - Camera + gallery pick via `image_picker` (imageQuality: 85, maxWidth: 1200)
  - Image preview with retake button
  - "Analyze Ingredients" CTA → triggers FoodRecognitionService → advances to step 2

### 18.6 — Step 2: Ingredients Review
- [x] Create `lib/presentation/photo_recipe_screen/widgets/ingredients_review_step.dart`
  - Shimmer loading state during Gemini Vision call
  - Detected ingredients as removable/editable chips (name + quantity)
  - Category color coding (protein=red, carb=amber, vegetable=green, etc.)
  - "Generate Recipes" CTA (disabled if 0 ingredients) → triggers SmartRecipeService → advances to step 3
  - Empty state: "No food items detected" + retake photo button

### 18.7 — Step 3: Browse Recipes
- [x] Create `lib/presentation/photo_recipe_screen/widgets/recipes_step.dart`
  - Shimmer loading state during recipe generation
  - Card list of 3-5 recipes: name, description, prep+cook time, difficulty badge, calorie/protein preview
  - Tap card → bottom sheet with full recipe detail (ingredients with grams, steps, full macros)
- [x] Create `lib/presentation/photo_recipe_screen/widgets/recipe_detail_sheet.dart`
  - Scrollable bottom sheet: recipe name, macros summary row, ingredient list (with gram amounts), numbered steps
  - "Log This Meal" CTA at bottom → advances to step 4 with selected recipe

### 18.8 — Step 4: Log Recipe as Meal
- [x] Create `lib/presentation/photo_recipe_screen/widgets/log_recipe_step.dart`
  - Selected recipe summary (name, macros per serving)
  - Meal type picker: Breakfast / Lunch / Dinner / Snack (ChoiceChips, same pattern as ProductFoundScreen)
  - Serving count selector (default 1, range 1–10)
  - "Log Meal" CTA:
    1. Create temp `food_database` row (name=recipe name, calories=round(), protein/carbs/fat, serving_size=1, is_verified=false, is_user_contributed=true)
    2. Call `NutritionService.logMeal(foodId, mealType, servingQuantity)`
    3. Navigate back to nutrition screen with success feedback

### 18.9 — Route & Entry Point
- [x] Add `static const String photoRecipe = '/photo-recipe';` to `AppRoutes`
- [x] Register in `onGenerateRoute` (no arguments needed)
- [x] Add CTA button on `NutritionPlanningScreen` — between water tracking and AI meal plan section
  - Camera/recipe icon + "Generate Recipe from Photo" label

### 18.10 — Edge Cases & Polish
- [x] No food detected → empty state with retry
- [x] API timeout → error state with retry button
- [x] <2 ingredients → warning chip "Few ingredients — recipes may be limited"
- [x] Invalid JSON from Gemini → "Could not process — try again"
- [x] User removes all ingredients → disable "Generate Recipes" button
- [x] 0 recipes returned → "Could not generate recipes with these ingredients"
- [x] No user profile → generate recipes without calorie targeting
- [x] Camera permission denied → image_picker native dialog + catch with SnackBar

### 18.11 — Documentation
- [x] Update `lib/services/CLAUDE.md` with FoodRecognitionService + SmartRecipeService docs
- [x] Update `lib/presentation/CLAUDE.md` with PhotoRecipeScreen docs
- [x] Update `CLAUDE.md` current status

---

## Milestone 19 — Performance Optimization & Client-Side Caching

> Make the app feel instant: eliminate redundant network calls, cache aggressively, optimize heavy widgets, and reduce memory pressure from images. Target: every screen loads in <300ms on repeat visits.

### 19.1 — AppCacheService Expansion (In-Memory Cache Layer)
- [x] Extend `AppCacheService` to cache exercise library data (static list — long TTL, 30 min)
- [ ] Cache user's active workout plan + sessions (TTL 10 min, invalidate on plan change)
- [x] Cache body measurements history (TTL 5 min, invalidate on new measurement) — cache field created, not yet wired to screen
- [x] Cache strength progress / PR data (TTL 5 min, invalidate after workout session) — cache field created, not yet wired to screen
- [x] Cache food search results for repeated queries (LRU map, max 20 queries, TTL 3 min)
- [x] Cache `getMyContributions()` results (TTL 5 min, invalidate on add/delete)
- [ ] Add `invalidateAll()` call on sign-out flow to clear stale user data

### 19.2 — Supabase Query Optimization
- [x] Add `.limit(50)` to `getUserMeals()` and `getMyContributions()` list queries
- [ ] Add pagination to `getMyContributions()` and `getUserMeals()` — fetch 20 at a time with "load more"
- [ ] Optimize `_fetchWorkoutStreak()` — replace client-side streak calculation with a Supabase RPC that returns the streak count directly (eliminates fetching up to 365 rows)
- [x] Add `.select()` column projection to WorkoutService queries (getAllWorkoutPlans, getUserActiveWorkout, getAllCategories, getWorkoutPlanDetails join)
- [x] `NutritionPlanningScreen` already uses `Future.wait()` for parallel nutrition calls (confirmed pre-M19)

### 19.3 — Image Performance
- [ ] Add `cacheWidth` / `cacheHeight` to all `CachedNetworkImage` calls — decode at display size, not full resolution (reduces GPU memory)
- [ ] Add `ResizeImage` wrapper for asset images loaded via `Image.asset()` where display size is known
- [ ] Compress camera-captured images before sending to Gemini Vision (photo recipe + OCR) — resize to max 1024px wide before base64 encoding (currently sends up to 1200px)
- [ ] Pre-cache exercise animation frames on `ExerciseLibrary` scroll (prefetch frame 0 + frame 1 for next 3 visible items)
- [x] Add `fadeInDuration: 200ms` and `memCacheWidth` (with `.isFinite` guard) to `CachedNetworkImage` in `CustomImageWidget`

### 19.4 — Widget Rebuild Optimization
- [ ] Extract heavy sub-widgets from `NutritionPlanningScreen` into `const` StatelessWidgets where possible to prevent full-tree rebuilds on `setState`
- [ ] Add `AutomaticKeepAliveClientMixin` — N/A: `IndexedStack` already keeps all tabs alive; mixin only applies to `PageView`/`TabBarView`
- [ ] Convert `WeeklyProgressWidget` to cache its Supabase query result instead of re-fetching every time the home tab rebuilds
- [x] Debounce food search in `AddFoodModalWidget` — 400ms Timer, properly disposed
- [x] Move day-of-year calculation and daily tip selection out of `build()` into `initState()` via `late final String _dailyTip`

### 19.5 — Lazy Loading & Deferred Initialization
- [ ] Lazy-load `ProgressTrackingScreen` child widgets (charts, photo grid) — show shimmer skeleton and load chart data only when tab is first selected
- [ ] Defer `google_mlkit_text_recognition` initialization until user actually navigates to barcode/OCR flow (ML Kit loads native libraries on import)
- [ ] Lazy-load `youtube_player_flutter` — only initialize when user opens exercise detail sheet (not on library screen mount)
- [ ] Add `ScrollController` listener to exercise library to load next page only when user scrolls near bottom (already has pagination — verify it works correctly)

### 19.6 — Network Request Optimization
- [x] Add debounce timer (400ms) to food search in `AddFoodModalWidget` — done in 19.4
- [ ] Add HTTP connection pooling — reuse `Dio` instance across services instead of creating new instances per call
- [ ] Add retry with exponential backoff for Supabase queries that fail due to network issues (max 2 retries, 1s → 2s delay)
- [ ] Cancel in-flight API requests when user navigates away from screen (use `CancelToken` with Dio for Gemini/OFF/USDA calls)
- [ ] Cache Open Food Facts + USDA search results locally for 10 minutes to avoid duplicate API calls for same query

### 19.7 — Local Storage & Offline Resilience
- [ ] Persist exercise library data to `SharedPreferences` or local JSON file — load from cache on app start, refresh from static data only if version changes
- [ ] Cache user profile to `SharedPreferences` — show cached data immediately on app start, refresh from Supabase in background
- [ ] Cache last viewed daily nutrition data to `SharedPreferences` — show stale data with "refreshing…" indicator instead of full loading skeleton
- [x] Add `connectivity_plus` listener — red offline banner in `MainDashboard` via `Stack(fit: StackFit.expand)` + `Positioned` overlay

### 19.8 — Memory Management
- [~] Dispose all `ScrollController`, `TextEditingController`, `AnimationController` instances — fixed `water_tracking_card.dart` and `ingredients_review_step.dart`; full audit pending
- [ ] Clear image cache when app goes to background (use `WidgetsBindingObserver` + `imageCache.clear()`) to free memory on low-RAM devices
- [ ] Limit photo progress images loaded in memory — use `ListView.builder` with `cacheExtent` instead of loading all photos at once
- [ ] Compress stored food images URLs — strip unnecessary URL parameters from Open Food Facts image URLs before caching to DB

### 19.9 — Build & Bundle Size
- [ ] Run `flutter analyze` — fix all warnings and info-level lints
- [ ] Add `--split-debug-info` and `--obfuscate` to release build command for smaller APK
- [ ] Audit unused packages in `pubspec.yaml` (e.g., `web`, `universal_html`) — remove if not needed
- [ ] Enable R8/ProGuard shrinking for release builds — verify no runtime crashes after minification
- [ ] Tree-shake unused Material icons with `--no-tree-shake-icons` removed (ensure only used icons are bundled)

### 19.10 — Performance Monitoring & Measurement
- [ ] Add `Stopwatch` timing to all service methods in debug mode — log slow queries (>500ms) to console
- [ ] Measure and log screen transition times (push → first frame) for the 5 main tabs
- [ ] Add frame rate monitoring in debug mode — flag jank (frames >16ms) during scroll in exercise library and nutrition meal list
- [ ] Create a simple performance report at end of session: average load times per screen, cache hit ratio, slowest queries

---

## Backlog (Nice to Have)

- [ ] Push notifications for workout reminders (daily reminder at user-set time)
- [ ] Stripe premium subscription flow (`STRIPE_PUBLISHABLE_KEY` is already configured in env)
- [ ] Google OAuth sign-in (OAuth client ID is in env but not wired up)
- [ ] Offline mode — cache last AI plan and exercise data locally
- [ ] Workout plan sharing (generate shareable link or image)
- [ ] Weekly summary push notification (calories, workouts completed)
- [ ] Apple Health / Google Fit integration for step count and heart rate

---

## Session Log

| Date | Session | Completed | Next |
|---|---|---|---|
| 2026-03-23 | M7 — Body measurements | BodyMeasurementsService, measurements UI, pending commits | Commit pending changes → M9 UI Polish |
| 2026-03-24 | Docs setup | CLAUDE.md hierarchy, TASKS.md, SESSION_WORKFLOW.md, docs/ reference files | M9 — Romanian → English UI strings |
| 2026-03-24 | M1–M8 sub-tasks | Retry logic, shimmer skeletons, real nutrition data, YouTube player, meal eaten toggle, barcode scan, measurements LineChart, PR badges, dark mode toggle | M9 remaining polish tasks |
| 2026-03-24 | M9 complete | Shimmer skeletons, pull-to-refresh, haptic feedback, empty states, tap targets, overflow fixes, splash screen, flutter analyze clean, full Romanian→English localization (50 files) | M10 — Workout Session Live Tracking |
| 2026-03-25 | Exercise Library UI | Horizontal list cards + category chip bar redesign | Auth + Dashboard UI redesign |
| 2026-03-25 | Auth + Dashboard UI | Gradient hero + floating card on login/signup/onboarding + home page redesign, AI tagline removed | M10 — Workout Session Live Tracking |
| 2026-03-26 | Planning | Added M14 (Nutrition Overhaul) + M15 (Barcode/OFF Integration) to TASKS.md based on user requirements | M14 — Nutrition Screen Overhaul |
| 2026-03-26 | Planning | Added M16 (External Food Database: OFF text search + USDA FoodData Central) for full food search expansion | M10 → M15 → M16 |
| 2026-03-26 | M16 complete | OFF searchFoods() + UsdaFoodService + 3-tier AddFoodModalWidget + cacheExternalFood() + DB schema fixes | M10 — Workout Session Live Tracking |
| 2026-03-26 | Planning | Added M17 (Community Food Database: user contributions via barcode + Gemini Vision nutritional label OCR) | M10 — Workout Session Live Tracking |
| 2026-03-27 | M17 OCR upgrade | ML Kit + Gemini 2.5 Flash 2-step pipeline; 22-field schema; EU label calibration; food correction feature | OCR fix session |
| 2026-03-27 | OCR fix | Fix thinking model token truncation (maxTokens 1024→8192), thinking-aware response parsing, auto-trigger extraction, debug logging | M10 — Workout Session Live Tracking |
| 2026-03-27 | M10 complete | ActiveWorkoutSession screen, SetRowWidget, ExerciseTrackerWidget, WorkoutSummaryScreen, workout_set_logs DB table, auto PR detection, dashboard nav update | M11 — Testing & Quality |
| 2026-03-28 | Hotfixes | fix: active workout route null (rootNavigator: true); fix: exercise image crash (imageUrl??'' asset error) + replaced MuscleWiki dead URLs with free-exercise-db 2-frame animations | M11 — Testing & Quality |
| 2026-03-28 | M18 planning | MuscleBodyWidget rewrite (muscle_selector pkg); M18 milestone planned — Photo-to-Recipe Generator (11 new files, 5 modified, 2 services, 4-step wizard) | M18 implementation |
| 2026-03-28 | M18 complete | RecipeDetailSheet + LogRecipeStep created; route registered; CTA on NutritionPlanningScreen; shimmer dep added; all CLAUDE.md docs updated | M11 — Testing & Quality |
