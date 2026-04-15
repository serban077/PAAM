# TASKS.md — SmartFitAI

Milestone-based task tracker. Mark tasks `[x]` as they are completed.
Update `## Current Status` in `CLAUDE.md` at the end of every session.

---

## Current Status

**Last updated:** 2026-04-16
**Last session completed:** M22 — Audit Baseline (static slice): flutter analyze (125 issues — 0 errors in main app), 4 unused packages confirmed (camera/youtube/universal_html/before_after), APK build FAILED (R8 — ProGuard fix ready), 72 DB performance + 13 security advisors logged, postgres logs clean; full report in docs/AUDIT_BASELINE.md
**Next session starts with:** M23 — High Refresh Rate & UI Fluidity (flutter_displaymode, flutter_animate, animations pkg, skeletonizer, widget rebuild reduction)
**Active branches:** main
**Blockers / notes:** `pubspec.lock` gitignored — run `flutter pub get` at session start. `product_found_sheet.dart` unused untracked — safe to delete. USDA_API_KEY in env.json. Gemini 2.5 Flash needs maxTokens ≥ 8192. M20 manual config: "Confirm email" enabled in Supabase ✅; hCaptcha skipped (no free tier needed for PAAM). M19 deferred: pagination UI, streak RPC, lazy ProgressTrackingScreen, SharedPreferences layer, build/bundle (19.9), perf monitoring (19.10). Pre-existing 44 project-wide info/warnings in gemini_ai_service.dart, body_measurements_card.dart etc. — not blocking.

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
- [x] Cache user's active workout plan + sessions (TTL 10 min) — `_activeWorkout` + `_weeklySchedule` fields added; wired to `WeeklyProgressWidget`
- [x] Cache body measurements history (TTL 5 min, invalidate on new measurement) — wired to `BodyMeasurementsCard`
- [x] Cache strength progress / PR data (TTL 5 min) — wired to `StrengthProgressScreen`
- [x] Cache food search results for repeated queries (LRU map, max 20 queries, TTL 3 min) — wired to `AddFoodModalWidget._searchFood()` (check before Supabase/OFF/USDA, set after combining all results)
- [x] Cache `getMyContributions()` results (TTL 5 min, invalidate on add/delete)
- [x] Add `invalidateAll()` call on sign-out — `AuthService.signOut()` now calls it first

### 19.2 — Supabase Query Optimization
- [x] Add `.limit(50)` to `getUserMeals()` and `getMyContributions()` list queries
- [ ] Add pagination to `getMyContributions()` and `getUserMeals()` — fetch 20 at a time with "load more" (deferred)
- [ ] Optimize `_fetchWorkoutStreak()` — replace client-side streak calculation with a Supabase RPC (deferred — requires migration)
- [x] Add `.select()` column projection to WorkoutService queries (getAllWorkoutPlans, getUserActiveWorkout, getAllCategories, getWorkoutPlanDetails join)
- [x] `NutritionPlanningScreen` already uses `Future.wait()` for parallel nutrition calls (confirmed pre-M19)

### 19.3 — Image Performance
- [x] Add `maxWidthDiskCache` / `maxHeightDiskCache` to `CachedNetworkImage` in `CustomImageWidget` (same `.isFinite` guard as `memCacheWidth`)
- [ ] Add `ResizeImage` wrapper for asset images loaded via `Image.asset()` where display size is known (deferred)
- [x] Compress camera-captured images before sending to Gemini Vision — `maxWidth: 1024` in `capture_step.dart` and `user_food_submission_screen.dart` (was 1200)
- [ ] Pre-cache exercise animation frames on `ExerciseLibrary` scroll (deferred — complex)
- [x] Add `fadeInDuration: 200ms` and `memCacheWidth` (with `.isFinite` guard) to `CachedNetworkImage` in `CustomImageWidget`

### 19.4 — Widget Rebuild Optimization
- [x] Extract Photo Recipe CTA from `NutritionPlanningScreen` to `_PhotoRecipeCtaWidget` (stable widget identity, reduces rebuild scope)
- [x] Wrap 4 `SimpleMealCard` instances in `RepaintBoundary` — prevents parent repaints from cascading into cards
- [x] Add `AutomaticKeepAliveClientMixin` — N/A: `IndexedStack` already keeps all tabs alive
- [x] Convert `WeeklyProgressWidget` to cache Supabase query results — `getWeeklySchedule()` + `getActiveWorkout()` cache
- [x] Debounce food search in `AddFoodModalWidget` — 400ms Timer, properly disposed
- [x] Move day-of-year calculation and daily tip selection out of `build()` into `initState()` via `late final String _dailyTip`

### 19.5 — Lazy Loading & Deferred Initialization
- [ ] Lazy-load `ProgressTrackingScreen` child widgets — deferred (significant refactor)
- [x] `google_mlkit_text_recognition` already lazy — only imported in `gemini_nutrition_label_service.dart`
- [x] `youtube_player_flutter` already removed — replaced with free-exercise-db GIFs
- [x] `ScrollController` listener on `ExerciseLibrary` already exists — scroll-driven pagination confirmed

### 19.6 — Network Request Optimization
- [x] Add debounce timer (400ms) to food search in `AddFoodModalWidget`
- [x] HTTP connection pooling — all 3 external API services (OFF, USDA, Gemini) already use singleton Dio instances
- [ ] Add retry with exponential backoff (deferred — risk of introducing bugs in stable flows)
- [ ] Cancel in-flight API requests with CancelToken (deferred — complex)
- [ ] Cache OFF + USDA search results for 10 min (deferred)

### 19.7 — Local Storage & Offline Resilience
- [ ] Persist exercise library / user profile / nutrition to `SharedPreferences` (deferred — in-memory AppCacheService sufficient for session lifetime)
- [x] Add `connectivity_plus` listener — red offline banner in `MainDashboard` via `Stack(fit: StackFit.expand)` + `Positioned` overlay

### 19.8 — Memory Management
- [~] Dispose all controllers — fixed `water_tracking_card.dart` and `ingredients_review_step.dart`; full audit pending
- [x] Clear image cache on background — `MainDashboardState` now extends `WidgetsBindingObserver`; clears `PaintingBinding.imageCache` on `AppLifecycleState.paused`
- [x] Limit photo progress images loaded in memory — converted `PhotoProgressWidget` to `ListView.builder` + `CustomImageWidget` (was `Column + .map()` + bare `Image.network`)
- [x] Strip URL query params from `image_front_url` in `NutritionService.cacheExternalFood()` before upsert — prevents duplicate DB rows for same image with different params

### 19.9 — Build & Bundle Size (deferred — separate config session)
- [x] Run `flutter analyze` — 0 errors in `lib/`; fixed unnecessary imports, string interpolations, `prefer_collection_literals`, redundant `dart:typed_data`; remaining are pre-existing deprecation infos
- [ ] Add `--split-debug-info` and `--obfuscate` to release build command
- [ ] Audit unused packages in `pubspec.yaml`
- [ ] Enable R8/ProGuard shrinking
- [ ] Tree-shake unused Material icons

### 19.10 — Performance Monitoring (deferred)
- [ ] Add `Stopwatch` timing to service methods in debug mode
- [ ] Measure screen transition times
- [ ] Add frame rate monitoring
- [ ] Create performance report

---

## Milestone 20 — Authentication Security & Account Protection

> Harden the auth flow end-to-end: email verification, password reset, biometric app lock, TOTP two-factor authentication, "Remember me" session persistence, CAPTCHA bot protection on signup, password strength indicator, and a dedicated Security Settings screen.

### 20.1 — Email Verification on Signup ✅
- [ ] Enable "Confirm email" in Supabase Dashboard → Auth → Settings (config only — **manual step**)
- [x] Create `lib/presentation/auth/email_verification_screen.dart`
- [x] Add `AuthService.resendConfirmationEmail()` + `refreshSession()`
- [x] `AuthenticationOnboardingFlow` — detect unconfirmed email → show verification gate
- [x] Route `AppRoutes.emailVerification` registered via `onGenerateRoute`

### 20.2 — Forgot Password / Password Reset ✅
- [x] Add "Forgot password?" link in `LoginFormWidget` → navigates to `ForgotPasswordScreen`
- [x] Create `lib/presentation/auth/forgot_password_screen.dart`
- [x] Create `lib/presentation/auth/update_password_screen.dart` (with strength indicator)
- [x] Handle `AuthChangeEvent.passwordRecovery` in `AuthenticationOnboardingFlow` → push `UpdatePasswordScreen`
- [x] Routes: `AppRoutes.forgotPassword`, `AppRoutes.updatePassword`

### 20.3 — Biometric App Lock (Fingerprint / Face ID) ✅
- [x] Add `local_auth: ^2.3.0` to `pubspec.yaml`
- [x] Android: add `USE_BIOMETRIC` + `USE_FINGERPRINT` permissions to `AndroidManifest.xml`
- [x] iOS: add `NSFaceIDUsageDescription` to `Info.plist`
- [x] Create `lib/services/biometric_service.dart`
- [x] Add Biometric toggle to Security Settings screen (visible only if `isAvailable()`)
- [x] Implement app lock on resume in `MainDashboard.didChangeAppLifecycleState` (>5 min → push AppLockScreen)
- [x] Create `lib/presentation/auth/app_lock_screen.dart`
- [x] Add biometric sign-in button in `LoginFormWidget` (visible when biometric available)

### 20.4 — Two-Factor Authentication (TOTP) ✅
- [x] Create `lib/services/mfa_service.dart`
- [x] Add `qr_flutter: ^4.1.0` to `pubspec.yaml`
- [x] Create `lib/presentation/security_settings_screen/two_factor_setup_screen.dart` (3-step wizard)
- [x] Create `lib/presentation/auth/totp_challenge_screen.dart`
- [x] DB migration: `auth_backup_codes` table with RLS
- [x] `AuthenticationOnboardingFlow` — MFA AAL check → push `TotpChallengeScreen` if needed
- [x] Routes: `AppRoutes.twoFactorSetup`, `AppRoutes.totpChallenge`

### 20.5 — CAPTCHA / Bot Protection on Signup ✅
- [ ] Register free hCaptcha site key at hcaptcha.com → store as `HCAPTCHA_SITE_KEY` in `env.json` (**manual step**)
- [ ] Enable hCaptcha in Supabase Dashboard → Auth → Bot Protection (**manual step**)
- [x] Add `webview_flutter: ^4.9.0` to `pubspec.yaml`
- [x] `AuthService.signUp()` accepts optional `captchaToken` parameter

### 20.6 — Session Security & "Remember Me" ✅
- [x] Add `flutter_secure_storage: ^9.2.2` to `pubspec.yaml`
- [x] Create `lib/services/session_service.dart`
- [x] Add "Remember me" checkbox to `LoginFormWidget` (default: checked)
- [x] `AuthService.signOut()` calls `AppCacheService.invalidateAll()`

### 20.7 — Password Strength Indicator ✅
- [x] Create `lib/widgets/password_strength_indicator.dart` (4 levels, animated LinearProgressIndicator)
- [x] Added to `RegisterFormWidget` below password field
- [x] Added to `UpdatePasswordScreen`
- [x] Signup validation: ≥ 8 chars, 1 uppercase, 1 digit enforced in `RegisterFormWidget`

### 20.8 — Security Settings Screen ✅
- [x] Create `lib/presentation/security_settings_screen/security_settings_screen.dart`
- [x] Entry point: "Security" `ListTile` in `UserProfileManagement`
- [x] `AuthService.deleteAccount()` + `delete_my_account()` RPC migration
- [x] DB migration: `delete_my_account()` RPC
- [x] Route `AppRoutes.securitySettings` registered via `onGenerateRoute`

### 20.9 — Documentation ✅
- [x] Update `lib/services/CLAUDE.md` with `MfaService`, `BiometricService`, `SessionService` docs
- [x] Update `lib/presentation/CLAUDE.md` with all new screens from M20
- [x] Update `CLAUDE.md` current status

---

## Milestone 21 — Exercise Library Expansion

> Massively expand the exercise database from ~20 mock entries to 100+ real exercises across 13 muscle-group categories. Remove all YouTube videoId/videoUrl fields (Exercise3DWidget + MuscleBodyWidget already handle the visual). Unify the two exercise databases into a single source of truth.

### 21.1 — Unified Exercise Database ✅
- [x] Rewrite `verified_exercises_data.dart` — 100+ exercises, 13 categories (Chest, Back, Legs, Glutes, Calves, Shoulders, Arms, Forearms, Abs, Full Body, Stretching, Plyometrics, Cardio)
- [x] Remove `videoId` / `videoUrl` fields from all exercise entries
- [x] Unified schema: `id`, `name` (English), `bodyPart`, `targetMuscles`, `equipment`, `difficulty`, `image`?, `semanticLabel`, `restrictions`, `instructions`, `safetyTips`, `sets`, `reps`, `restSeconds`

### 21.2 — Exercise Library Screen Update ✅
- [x] Replace `_generateMockExercises()` with `VerifiedExercisesData.getAllExercises()` in `exercise_library.dart`
- [x] Update category chips to include all 13 new categories
- [x] Update `filter_bottom_sheet_widget.dart` bodyPart filter options
- [x] Add new equipment types: Kettlebell, Resistance Band, Box

### 21.3 — Card & Animation Polish ✅
- [x] Update `exercise_card_widget.dart` — styled body-part placeholder when no image URL
- [x] Extend `exercise_gif_utils.dart` with mappings for all new exercises

---

## Milestone 22 — App Health Audit & Baseline Metrics

> Measure before optimizing. Establish hard numbers for every perf metric so later milestones have a reference point. All baseline values go into `docs/AUDIT_BASELINE.md`.

### 22.1 — Static Analysis & Lint Baseline
- [x] Run `flutter analyze` and record exact warning/info count per file — **125 issues: 0 errors (main app), ~10 warnings, ~100 infos, 7 errors in PAAM subfolder**
- [ ] Fix remaining pre-existing lints in `gemini_ai_service.dart`, `body_measurements_card.dart` (and any others flagged in M19.9)
- [ ] Audit and delete `lib/presentation/nutrition_planning_screen/widgets/product_found_sheet.dart` (confirmed unused per CLAUDE.md)
- [x] Grep for leftover `print(` / `TODO` / `FIXME` in `lib/` — **2 raw print() in gemini_ai_service.dart; 1 TODO in onboarding_survey_widget.dart; 0 FIXME/HACK**
- [ ] Add stricter lint ruleset via `very_good_analysis` or custom `analysis_options.yaml` (optional — pending user decision)

### 22.2 — Dependency Audit
- [x] Run `flutter pub outdated` — **16 direct deps upgradable: 8 major (sizer/camera/fl_chart/connectivity_plus/flutter_secure_storage/fluttertoast/google_fonts/intl/local_auth/permission_handler), 8 minor (dio/flutter_svg/mobile_scanner/shared_preferences/supabase_flutter/google_mlkit_text_recognition)**
- [x] Identify unused dependencies — **4 confirmed unused (zero imports in lib/): camera, youtube_player_flutter, universal_html, before_after**
- [x] `js` package flagged as **DISCONTINUED** by Dart team (transitive dep)
- [ ] Verify each package is still maintained (last commit < 12 months)

### 22.3 — Performance Baseline Measurement
- [ ] Cold start time (`flutter run --trace-startup --profile`) — record for each of the 3 primary flows: login, dashboard, exercise library **[DEFERRED — needs device]**
- [~] APK size (`flutter build apk --analyze-size`) — **BUILD FAILED: R8 missing ProGuard rules for google_mlkit_text_recognition. Fix ready in docs/AUDIT_BASELINE.md §3a. Re-run after M31.1.**
- [ ] Frame rendering per screen (`flutter run --profile` + DevTools Performance) **[DEFERRED — needs device]**
- [ ] Memory footprint idle + after 5 min navigation loop (DevTools Memory) **[DEFERRED — needs device]**
- [ ] Count total widget rebuilds on dashboard using DevTools "Track Widget Builds" **[DEFERRED — needs device]**

### 22.4 — DB Advisor Reports
- [x] Run `mcp__supabase__get_advisors` security — **13 WARN: 10 mutable search_path functions, 2 permissive food_database policies, 1 leaked password protection disabled**
- [x] Run `mcp__supabase__get_advisors` performance — **72 issues: 28 WARN auth_rls_initplan (auth.uid() re-evaluated per row), 14 WARN multiple_permissive_policies, 13 INFO unindexed FKs, 17 INFO unused indexes**
- [x] Run `mcp__supabase__get_logs` postgres — **CLEAN: 0 errors, only connection + checkpoint events**
- [x] All findings documented in `docs/AUDIT_BASELINE.md`

### 22.5 — Baseline Document
- [x] Created `docs/AUDIT_BASELINE.md` — full report with static analysis, deps, build, DB health, priority fix queue
- [ ] Runtime section (§5 of baseline doc) — fill in with device measurements before starting M33

---

## Milestone 23 — High Refresh Rate & UI Fluidity

> Make the app feel buttery-smooth. Unlock 90/120Hz displays, eliminate jank frames, cut widget rebuilds, upgrade animations to a declarative system. Biggest perceived-fluency win.

### 23.1 — High Refresh Rate Display Support
- [ ] Add `flutter_displaymode: ^0.6.0` to `pubspec.yaml`
- [ ] In `main.dart`, call `FlutterDisplayMode.setHighRefreshRate()` after `WidgetsFlutterBinding.ensureInitialized()`
- [ ] Test on a 90/120Hz Android device — record before/after FPS on a scroll-heavy screen
- [ ] Guard call with `Platform.isAndroid` (iOS handles automatically)

### 23.2 — Animation System Upgrade
- [ ] Add `flutter_animate: ^4.5.0` to `pubspec.yaml` — declarative, performant, replaces hand-rolled `AnimationController` boilerplate
- [ ] Add `animations: ^2.0.11` (official Flutter team) — for `OpenContainer` / `SharedAxisTransition` / `FadeThroughTransition` between screens
- [ ] Replace at least 3 hand-rolled `AnimationController` setups with `.animate()` chains (measure LOC reduction)
- [ ] Add `OpenContainer` Hero-style transition from exercise cards → exercise detail
- [ ] Add `SharedAxisTransition` between bottom-nav tabs (opt-in via `PageTransitionsTheme`)

### 23.3 — Skeleton Loading Modernization
- [ ] Add `skeletonizer: ^1.4.2` — modern replacement for `shimmer` package, wraps any widget tree
- [ ] Replace existing `shimmer` usages where skeletonizer's auto-detection is cleaner (exercise library cards, meal cards, contributions list)
- [ ] Keep `shimmer` only where custom shimmer shapes are needed

### 23.4 — Widget Rebuild Reduction
- [ ] DevTools "Track Widget Builds" on dashboard + nutrition + progress — record top 10 rebuild hotspots
- [ ] Add `const` to every eligible widget constructor (scripted fix with `dart fix --apply`)
- [ ] Wrap frequently-repainting widgets in `RepaintBoundary` (ring/arc progress, animated streak card)
- [ ] Extract large inline widgets inside `build()` into top-level stateless widgets with `const` constructors

### 23.5 — Scroll Performance
- [ ] Audit every `ListView` / `Column` with `.map()` — convert to `ListView.builder` where item count > 10
- [ ] Add `cacheExtent` tuning to long lists (exercise library, contributions, meal list)
- [ ] Add `AutomaticKeepAliveClientMixin` where tab switches cause expensive rebuilds (if any remain after M19)

### 23.6 — Motion & Micro-interactions
- [ ] Add subtle press animations on cards (`Tween<double> scale 1.0 → 0.97`) via `flutter_animate`
- [ ] Add staggered entrance animations on list items (`.animate(interval: 40.ms).fadeIn().slideY()`)
- [ ] Add loading → success checkmark animation on "Log Meal" / "Mark Eaten" buttons

---

## Milestone 24 — Image & Asset Optimization

> Images are the heaviest asset class. Compress, cache smarter, strip metadata, and pre-resolve sizes so memory stays low and scroll stays smooth.

### 24.1 — Bundled Asset Compression
- [ ] Audit every file in `assets/images/` — record current size + format
- [ ] Convert PNG/JPG to WebP where visual quality allows (typically 40-60% smaller)
- [ ] For photos: quality 80; for UI graphics: lossless WebP
- [ ] Re-verify paths in code after any rename

### 24.2 — Remote Image Pipeline
- [ ] Verify every `Image.network(` call is replaced with `CustomImageWidget` (grep)
- [ ] Confirm `CachedNetworkImage` has `memCacheWidth`, `memCacheHeight`, `maxWidthDiskCache`, `maxHeightDiskCache` on every usage (with `.isFinite` guard per CLAUDE.md)
- [ ] Add `errorWidget` + `placeholder` to every `CustomImageWidget` call site that doesn't have one
- [ ] Pre-fetch exercise images on `ExerciseLibrary` initial load using `precacheImage`

### 24.3 — Camera Capture Compression
- [ ] Add `flutter_image_compress: ^2.3.0` — run compression **before** base64 encoding for Gemini Vision
- [ ] Target: photos sent to Gemini Vision ≤ 500KB (quality 75, max 1024px)
- [ ] Apply in `capture_step.dart`, `user_food_submission_screen.dart`, any nutrition label flow

### 24.4 — SVG Optimization
- [ ] Audit every `.svg` in `assets/` — run through `svgo` (or manual cleanup) to strip metadata, whitespace, unnecessary groups
- [ ] Verify `flutter_svg` is only imported where actually needed

### 24.5 — App Icon & Splash Screen
- [ ] Add `flutter_launcher_icons: ^0.14.1` (dev dep) — single source of truth for all icon sizes (Android + iOS)
- [ ] Add `flutter_native_splash: ^2.4.1` (dev dep) — native splash, no Flutter widget flash on cold start
- [ ] Generate assets for both; replace existing splash screen widget with native handoff
- [ ] Measure cold start time change vs M22.3 baseline

---

## Milestone 25 — Memory Management & Leak Audit

> Go through every stateful widget and every service, confirm `dispose()` cleans up, catch leaks via DevTools Memory tab.

### 25.1 — Controller Disposal Audit
- [ ] Grep every `TextEditingController()` instantiation → verify `dispose()` in paired `State.dispose()`
- [ ] Grep every `AnimationController(` → same
- [ ] Grep every `ScrollController(` → same
- [ ] Grep every `PageController(` → same
- [ ] Grep every `FocusNode(` → same
- [ ] Fix any missing dispose (continuation of M19.8 full audit)

### 25.2 — Stream & Subscription Cleanup
- [ ] Audit every `StreamSubscription` → verify `cancel()` in dispose
- [ ] Audit Supabase realtime listeners → verify `removeChannel` / `unsubscribe`
- [ ] Audit `connectivity_plus` listener in `MainDashboard` → verify cleanup

### 25.3 — DevTools Memory Profiling
- [ ] Record heap snapshot before and after navigating: dashboard → exercise library → scroll 100 items → back (repeat 5 times)
- [ ] Identify any class with unexpected retained instances
- [ ] Compare `ImageCache` size before/after the M19.8 `imageCache.clear()` on background
- [ ] Document results in `docs/AUDIT_BASELINE.md`

### 25.4 — Isolate Heavy Work
- [ ] Identify heavy JSON parse / data transform on main thread (Gemini response parsing, food search merge)
- [ ] Move to `compute()` isolates where payload > 50KB
- [ ] Benchmark main-thread blocking before/after

---

## Milestone 26 — Network Layer Hardening & Offline Resilience

> Every external call should be resilient, timed-out, retry-aware, and survive brief connectivity loss. Offline banner already exists (M19.7) — next step is graceful degradation.

### 26.1 — Dio Interceptor Centralization
- [ ] Create `lib/services/_dio_interceptors.dart` — shared interceptors: logging (debug only), timeout, retry, error normalization
- [ ] Apply to all Dio instances: `GeminiAiService`, `GeminiNutritionLabelService`, `OpenFoodFactsService`, `UsdaFoodService`, `FoodRecognitionService`, `SmartRecipeService`

### 26.2 — Retry with Exponential Backoff
- [ ] Add `dio_smart_retry: ^7.0.1` OR implement custom `RetryInterceptor` (3 retries, exponential backoff 500ms → 1s → 2s)
- [ ] Apply only on 5xx and timeout — NOT on 4xx
- [ ] Gemini calls: max 2 retries (expensive), OFF/USDA: max 3

### 26.3 — Request Cancellation
- [ ] Add `CancelToken` to food search: cancel previous in-flight request when user types new query
- [ ] Add `CancelToken` to Gemini Vision: cancel if user pops `CaptureStep` before response arrives

### 26.4 — External Search Cache
- [ ] Cache OFF + USDA search results for 10 min (deferred from M19.6) — LRU map in `AppCacheService`, key = normalized query
- [ ] Cache Gemini Vision result for same `imageBytes` hash (10 min) — avoid re-billing on retry

### 26.5 — Offline Mode Stub (partial)
- [ ] When `connectivity_plus` reports offline, Gemini/OFF/USDA calls fail fast with clear error toast (not 15s timeout)
- [ ] Saved AI plans / cached exercises remain readable from `AppCacheService`
- [ ] Record action queue for later sync (DEFERRED to full offline mode if time permits)

---

## Milestone 27 — Supabase Query & Index Optimization

> Use Supabase advisors + log analysis to catch slow queries, missing indexes, and RLS overhead before they bite in production.

### 27.1 — Index Audit
- [ ] Run `mcp__supabase__list_tables` — for every table, identify columns used in WHERE / ORDER BY in Dart code
- [ ] Create migration adding missing indexes: `nutrition_logs(user_id, date)`, `workout_logs(user_id, created_at DESC)`, `food_database(name, brand)` if missing, `progress_photos(user_id, created_at DESC)`, `body_measurements(user_id, measured_at DESC)`, `workout_set_logs(session_id, exercise_id)`
- [ ] Verify no duplicate indexes

### 27.2 — Query Projection
- [ ] Every `.select()` call must list explicit columns — no implicit `*` on wide tables (continuation of M19.2)
- [ ] Audit WorkoutService, NutritionService, BodyMeasurementsService, ProgressPhotoService

### 27.3 — N+1 Query Audit
- [ ] Identify any `for (...) { await supabase.from(...).select(...) }` patterns → replace with a single join or `in_` batch call

### 27.4 — Streak RPC (deferred from M19.2)
- [ ] Create Postgres RPC `calculate_user_streak(user_id uuid) RETURNS int`
- [ ] Replace client-side `_fetchWorkoutStreak()` calculation with RPC call
- [ ] Index `workout_logs(user_id, completed_at DESC)` if not already present

### 27.5 — RLS Policy Audit
- [ ] For every table, run `mcp__supabase__execute_sql` `SELECT * FROM pg_policies WHERE tablename = '...'`
- [ ] Verify each user-scoped table has `auth.uid() = user_id` check
- [ ] Verify `food_database` has the M17 contribution-level policies intact

### 27.6 — Advisor Follow-ups
- [ ] Re-run `mcp__supabase__get_advisors` after 27.1–27.5 — target 0 critical findings

---

## Milestone 28 — AI Pipeline Optimization (Gemini)

> Cut token cost, cut latency, improve reliability on every AI call: workout plan, nutrition plan, vision OCR, photo recipe.

### 28.1 — Prompt Token Audit
- [ ] For each of the 5 Gemini prompts (workout plan, nutrition plan, OCR, food recognition, recipe generation), count token size before call
- [ ] Trim redundant instructions, move large static lists to structured output schema where possible
- [ ] Record baseline input + output tokens per call

### 28.2 — Structured Output Schema
- [ ] Migrate from free-text JSON to Gemini's `response_mime_type: "application/json"` + `response_schema`
- [ ] Eliminates "extract JSON from markdown" fragility; reduces parse failures to ~0
- [ ] Apply to: workout plan, nutrition plan, food recognition, recipe generation

### 28.3 — Native SDK Migration Consideration
- [ ] Evaluate replacing custom Dio + REST calls with `google_generative_ai: ^0.4.6` (official Dart SDK)
- [ ] Benefits: automatic retry, structured output helpers, streaming support, safer type boundaries
- [ ] Cost: migration effort. Decide go/no-go after spike on 1 service

### 28.4 — Response Streaming
- [ ] Where UX allows (workout plan generation screen), switch to streaming response → show tokens as they arrive
- [ ] Perceived latency cut by >50% even if total time unchanged

### 28.5 — Model Selection per Task
- [ ] Evaluate Gemini 2.5 Flash-Lite for cheaper short tasks (food search disambiguation, meal type suggestion)
- [ ] Keep Gemini 2.5 Flash for vision + plan generation (quality required)
- [ ] Document decision in `lib/services/CLAUDE.md`

### 28.6 — Prompt Result Caching
- [ ] Hash `(prompt + user TDEE + preferences)` → cache generated plan for 24h
- [ ] Users regenerating without profile change get instant result + $0 cost

---

## Milestone 29 — Crash Reporting, Analytics & Observability

> You can't fix what you can't see. Integrate a free-tier crash + analytics stack so real-world issues surface before users complain.

### 29.1 — Sentry Integration
- [ ] Register free project at sentry.io (5k events/month free)
- [ ] Add `sentry_flutter: ^8.9.0` + `SENTRY_DSN` in `env.json`
- [ ] Wrap `runApp` in `SentryFlutter.init` — auto-captures uncaught exceptions + frame drops
- [ ] Add manual `Sentry.captureException` in every `catch` block of critical flows (auth, Gemini, payment)
- [ ] Verify PII scrubbing — no user email in stack traces

### 29.2 — Performance Tracing
- [ ] Enable Sentry's `tracesSampleRate: 0.2` — 20% of transactions traced
- [ ] Add manual transactions on: AI plan generation, barcode scan, food search, photo recipe end-to-end
- [ ] Monitor dashboard for slow transactions > 3s

### 29.3 — Product Analytics (PostHog)
- [ ] Register free project at posthog.com (1M events/month free, EU-hosted option)
- [ ] Add `posthog_flutter: ^4.8.0` + `POSTHOG_API_KEY` in `env.json`
- [ ] Track key funnel events: `signup_started`, `onboarding_completed`, `first_ai_plan_generated`, `first_workout_logged`, `first_meal_logged`, `photo_recipe_generated`, `barcode_scanned`
- [ ] Privacy: opt-in toggle in Security Settings (GDPR-aware)

### 29.4 — In-App Review Prompt
- [ ] Add `in_app_review: ^2.0.9`
- [ ] Trigger review request after: 3rd completed workout session AND 7 days since signup AND never asked before
- [ ] Store "asked" flag in `SharedPreferences`

### 29.5 — Version Update Checker
- [ ] Add `upgrader: ^11.0.0` OR custom check against a Supabase `app_config` table
- [ ] On cold start, if server version > local version, show non-blocking banner with "Update" link

---

## Milestone 30 — Testing, CI & Quality Gate (expands M11)

> Replace M11's small scope with a comprehensive quality gate. Target: 40% coverage on services, smoke test every screen, golden tests for reusable widgets, CI that runs on every commit.

### 30.1 — Test Infrastructure
- [ ] Create `test/` directory with folders `unit/`, `widget/`, `golden/`, `integration/`
- [ ] Add dev deps: `mocktail: ^1.0.4`, `golden_toolkit: ^0.15.0`, `patrol: ^3.11.0` (real-device integration), `coverage: ^1.9.2`
- [ ] Create `test/helpers/test_app_wrapper.dart` — reusable MaterialApp wrapper for widget tests

### 30.2 — Unit Tests (Services)
- [ ] `CalorieCalculatorService` — TDEE formula, macro splits, edge cases (extreme weight, 0 activity)
- [ ] `AuthService` — mocked Supabase, cover signIn/signUp/signOut/currentUser
- [ ] `NutritionService` — mocked, cover logMeal, getUserMeals, cacheExternalFood, submitUserFood
- [ ] `BiometricService` — mocked `local_auth`, cover isAvailable/authenticate/denied
- [ ] `SessionService` — mocked `flutter_secure_storage`
- [ ] `AppCacheService` — TTL expiry, invalidation, LRU eviction

### 30.3 — Widget Tests (Screens)
- [ ] `LoginScreen` — form validation, error state, successful navigation
- [ ] `SignupScreen` — password strength indicator, CAPTCHA placeholder
- [ ] `OnboardingSurveyScreen` — step navigation, enum value submission
- [ ] `MainDashboard` — bottom nav switches tabs, offline banner appears
- [ ] `ExerciseLibrary` — filter chips work, scroll pagination triggers
- [ ] `NutritionPlanningScreen` — add food modal, meal type picker
- [ ] `AddFoodModalWidget` — 3-tier search merge, source badges, debounce

### 30.4 — Golden Tests (Reusable Widgets)
- [ ] `CustomBottomBar`, `CustomAppBar`, `CustomIconWidget`, `CustomImageWidget` (error/loading states)
- [ ] `ExerciseCardWidget`, `SimpleMealCard`, `BodyMeasurementsCard`, `PhotoProgressWidget`
- [ ] Test in light + dark theme

### 30.5 — Integration Smoke Tests (Patrol)
- [ ] Happy path: launch → login → dashboard → exercise library → back
- [ ] Happy path: dashboard → nutrition → add food (search) → log meal
- [ ] Happy path: dashboard → progress → body measurements entry

### 30.6 — Coverage Gate
- [ ] Run `flutter test --coverage` — generate `coverage/lcov.info`
- [ ] Target: services ≥ 40%, overall ≥ 25%
- [ ] Add `lcov` HTML report to `.gitignore`, generate on demand

### 30.7 — CI Pipeline (GitHub Actions)
- [ ] Create `.github/workflows/ci.yml`
- [ ] Jobs: `flutter pub get` → `flutter analyze` (must pass) → `flutter test` (must pass) → coverage upload
- [ ] Cache pub + Gradle
- [ ] Trigger on push + PR to `main`

### 30.8 — Pre-commit Hook
- [ ] Add `.git/hooks/pre-commit` (script, not a package) — runs `flutter analyze` + `dart format --set-exit-if-changed`
- [ ] Document in `SESSION_WORKFLOW.md`

---

## Milestone 31 — Build, Bundle & Startup Optimization

> Reduce APK size and time-to-interactive. The user-visible result: faster install, faster launch, less RAM on entry.

### 31.1 — Build Flags
- [ ] Add to release build: `--split-debug-info=build/symbols --obfuscate`
- [ ] Enable R8 shrinking + resource shrinking in `android/app/build.gradle.kts`
- [ ] Enable `minifyEnabled true` + `shrinkResources true` for release
- [ ] Add ProGuard rules for Supabase, Gemini, mobile_scanner, local_auth (to prevent over-aggressive removal)

### 31.2 — Tree Shaking
- [ ] Tree-shake Material icons (`--tree-shake-icons` — usually on by default, verify)
- [ ] Remove unused Google Fonts — lock to 1-2 families via `google_fonts` (each family adds ~200KB)
- [ ] Audit unused packages from M22.2 and remove

### 31.3 — ABI Split
- [ ] Build `--split-per-abi` APKs — users download only their arch (typically arm64-v8a), cuts ~40% size
- [ ] Document in `SESSION_WORKFLOW.md`

### 31.4 — Deferred Component Loading (optional, advanced)
- [ ] Evaluate Flutter's `deferred as` for heavy screens (PhotoRecipeScreen, ActiveWorkoutSession) — only loaded on first navigation
- [ ] Measure APK split before/after

### 31.5 — Startup Trace
- [ ] Run `flutter run --trace-startup --profile` → compare to M22.3 baseline
- [ ] Defer non-critical service init: `BiometricService.isAvailable()`, `SessionService.restore()`, `AppCacheService` warmup happen in parallel via `Future.wait` after first frame
- [ ] Target: cold start < 2.5s on mid-range Android (Redmi Note / Moto G class)

### 31.6 — First Frame Optimization
- [ ] `main()` runs absolute minimum work before `runApp`
- [ ] Heavy Supabase session restore happens in `AuthenticationOnboardingFlow` with splash, not in `main()`
- [ ] Native splash from M24.5 covers the entire boot until first real frame

---

## Milestone 32 — Accessibility & Final Polish

> Make the app usable by everyone (TalkBack, VoiceOver, larger touch targets, sufficient contrast) and apply the last round of visual polish before regression.

### 32.1 — Semantics Labels
- [ ] Every icon-only `IconButton` → add `tooltip` + `Semantics(label: ...)`
- [ ] Every `GestureDetector` with no visible text → add semantic label
- [ ] Run with screen reader on 1 happy path (login → dashboard → add meal)

### 32.2 — Touch Target Audit
- [ ] Verify every tappable region ≥ 48×48 logical pixels (Material guideline)
- [ ] Automated check via `flutter_test` semantics assertions

### 32.3 — Contrast & Color
- [ ] Run every text + background combo through WCAG AA checker (4.5:1 normal text, 3:1 large text)
- [ ] Fix any failure in `app_theme.dart` (both light + dark per CLAUDE.md rule)

### 32.4 — Dynamic Text Scale (selective)
- [ ] CLAUDE.md locks `textScaler: 1.0` — confirmed correct for this project
- [ ] But: allow scale **only inside specific screens** where layout can handle it (ExerciseDetail, Settings) via localized `MediaQuery` override — evaluate per screen

### 32.5 — Haptic Consistency
- [ ] Audit every primary action → ensure `HapticFeedback.lightImpact()` on success, `mediumImpact()` on destructive confirm

### 32.6 — Dark Mode Visual Pass
- [ ] Screenshot every screen in dark mode → fix any hardcoded color that slipped through
- [ ] Fix any `Colors.white` / `Colors.black` literal — use theme tokens

---

## Milestone 33 — Regression, Smoke Test & Release Readiness

> The final milestone before release. Re-run every measurement from M22, walk through every user flow manually, sign a checklist.

### 33.1 — Baseline Re-measurement
- [ ] Re-run all metrics from M22.1–M22.4
- [ ] Produce `docs/AUDIT_RESULTS.md` — side-by-side: baseline → final. Commit only if every metric is better or unchanged.

### 33.2 — End-to-End Manual Walkthrough
- [ ] Signup → email verification → onboarding → first AI plan → first workout → first meal → progress photo → security settings → signout
- [ ] Record any UX rough edge in `docs/SMOKE_TEST.md` (table format: screen / issue / severity / fixed?)

### 33.3 — Device Matrix
- [ ] Test on 1 low-end Android (< 3GB RAM)
- [ ] Test on 1 mid-range Android (90/120Hz display)
- [ ] Test on 1 iOS device or simulator
- [ ] Test on a small screen (375px width)

### 33.4 — Network Condition Matrix
- [ ] Offline: correct banner + graceful degradation
- [ ] Slow 3G (Chrome DevTools network throttling via dev menu): all flows still complete without crash
- [ ] Airplane mode mid-workout: local logs survive

### 33.5 — Release Build Verification
- [ ] `flutter build apk --release` → install → happy path works
- [ ] Verify `env.json` secrets NOT leaked in `strings.xml` / `Info.plist`
- [ ] Verify Sentry DSN is scoped to release project, not dev

### 33.6 — Sign-off
- [ ] Update `CLAUDE.md` current status with final metrics
- [ ] Tag release commit
- [ ] Archive audit docs in `docs/`

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
| 2026-04-02 | M20 complete | Email verification screen + forgot/reset password + biometric lock (local_auth) + TOTP 2FA (Supabase MFA + qr_flutter) + password strength indicator + security settings screen + session persistence (flutter_secure_storage) + "remember me" + CAPTCHA-ready signup; 4 new packages, 2 DB migrations, 11 new files, 7 modified; flutter analyze 0 errors | M11 — Testing & Quality |
| 2026-04-05 | M20 hotfixes | fix: Kotlin incremental cache cross-drive crash (flutter clean); fix: TOTP enrollment missing issuer param; fix: totp.qrCode→totp.uri (SVG 2MB caused QrInputTooLongException); fix: QrImageView infinite height (SizedBox wrapper); fix: LoginScreen session restore on cold start + biometric gate; redesign: AppLockScreen with pulse animation + fade-to-dashboard transition; fix: appLock route slide-from-bottom→fade (PageRouteBuilder) | M11 — Testing & Quality |
| 2026-04-07 | Progress screen UI overhaul | SliverAppBar + parallax header; shimmer skeleton; animated weekly calendar (AnimatedContainer + HapticFeedback + progress bar); arc weight progress card (CustomPaint, bidirectional goal logic, count-up animation); 2×2 stat grid with staggered entrance animations; 3D body silhouette (bezier + LinearGradient depth) with diagram-style measurement pins (LayoutBuilder, dots + connector lines + pill labels); flutter analyze 0 issues | M11 — Testing & Quality |
| 2026-04-15 | M21 complete | Exercise library expansion: 100+ exercises across 13 categories (Chest/Back/Legs/Glutes/Calves/Shoulders/Arms/Forearms/Abs/Full Body/Stretching/Plyometrics/Cardio); Unsplash photos per exercise; full GIF animation mapping in exercise_gif_utils.dart; new equipment types (Kettlebell/Resistance Band/Box); pagination + scroll-driven load-more; styled body-part placeholder cards; getExerciseListForPrompt() helper for Gemini prompts; fixed 2 warnings in photo_recipe_screen.dart | M11 — Testing & Quality |
| 2026-04-16 | M22 baseline (static) | flutter analyze: 125 issues (0 errors main app, 7 PAAM subfolder, ~10 warn, ~100 info); 4 unused packages confirmed (camera/youtube_player_flutter/universal_html/before_after); APK build FAILED (R8 ProGuard — fix documented); flutter pub outdated: 8 major + 8 minor upgrades; js package discontinued; Supabase: 13 security WARN + 72 perf issues (28 auth_rls_initplan WARN, 14 multiple_permissive_policies, 13 unindexed FKs, 17 unused indexes); postgres logs clean; docs/AUDIT_BASELINE.md created | M23 — High Refresh Rate & UI Fluidity |
