# TASKS.md — SmartFitAI

Milestone-based task tracker. Mark tasks `[x]` as they are completed.
Update `## Current Status` in `CLAUDE.md` at the end of every session.

---

## Current Status

**Last updated:** 2026-03-26
**Last session completed:** M14 — Nutrition Screen Overhaul (food DB seeded with 363 verified foods, meal-type bottom sheet picker, home page new cards)
**Next session starts with:** M10 — Workout Session Live Tracking (set-by-set logging with rest timer)
**Active branches:** main
**Blockers / notes:** `pubspec.lock` gitignored — run `flutter pub get` at session start. PAAM/ folder untracked (check if needed for university submission). DB enum values are now fully English — do NOT reintroduce Romanian strings.

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

## Milestone 10 — Workout Session Live Tracking

> Feature not yet started. `WorkoutService` exists but live session tracking is missing.

- [ ] Create `ActiveWorkoutSession` screen — live view of current workout
- [ ] Show current exercise, next exercise, rest timer countdown
- [ ] Log completed sets (reps + weight) per exercise
- [ ] Save completed session to Supabase with exercises and performance data
- [ ] Navigate to session summary screen after workout completion
- [ ] Connect completed sessions to `StrengthProgressScreen` to update PRs automatically

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

---

## Milestone 15 — Barcode Scanner: Open Food Facts Integration

> Replace the Supabase-only barcode lookup with the free Open Food Facts API (3 M+ products), add a scan cooldown, and create a polished product-found flow identical to apps like Eat & Track.

### 15.1 — OpenFoodFactsService
- [ ] Create `lib/services/open_food_facts_service.dart`
  - Method `Future<Map<String, dynamic>?> lookupBarcode(String barcode)`
  - URL: `https://world.openfoodfacts.org/api/v0/product/{barcode}.json` (no API key required)
  - Parse response: extract `product_name`, `nutriments.energy-kcal_100g`, `nutriments.proteins_100g`, `nutriments.carbohydrates_100g`, `nutriments.fat_100g`, `serving_size` (default to 100g if absent), `image_front_url`
  - Wrap in `try/catch` + `.timeout(const Duration(seconds: 15))`
  - Return `null` if status != 1 or product not found

### 15.2 — Barcode Lookup Flow (Supabase → OFF → Not Found)
- [ ] Update `BarcodeScannerPage._onBarcodeDetected()` lookup order:
  1. Query local `food_database` (Supabase) by `barcode` column — instant hit for cached items
  2. If not found, call `OpenFoodFactsService.lookupBarcode(barcode)`
  3. If found via OFF: insert product into Supabase `food_database` (`is_verified = false`, `barcode` = scanned value) and return the new row — **cache for next time**
  4. If still not found: show "Product not found. Try searching by name." snackbar; reset scan state
- [ ] Add `barcode` column to `food_database` if not already present (Supabase migration)

### 15.3 — Scan Cooldown & Camera Control
- [ ] Add `_scanCooldown` flag: after a successful scan, set to `true` for **1.5 seconds** before accepting the next barcode (`Future.delayed(const Duration(milliseconds: 1500), () => setState(() => _scanCooldown = false))`)
- [ ] Pause the `MobileScanner` camera while the product sheet is open; resume on sheet close
  - Use `MobileScannerController` and call `controller.stop()` / `controller.start()`
- [ ] Prevent scanning the same barcode twice in a row without a deliberate re-scan (existing `_lastBarcode` guard is good — ensure it resets on sheet dismiss, not on sheet open)

### 15.4 — ProductFoundSheet (bottom sheet)
- [ ] Create `lib/presentation/nutrition_planning_screen/widgets/product_found_sheet.dart`
- [ ] Content:
  - Product image (`CustomImageWidget`) if `image_front_url` is available, else placeholder icon
  - Product name (bold, large)
  - Macro chips row: kcal / Protein / Carbs / Fat (per 100g from OFF)
  - **Quantity input** — `TextFormField` (numeric, default 100, unit label: g / ml / portion)
  - Live calorie preview: recalculate as user types quantity (`quantity / 100 * kcal_per_100g`)
  - **Meal type selector** — 4 segmented buttons: Breakfast / Lunch / Dinner / Snack
  - "Add to Meal" CTA button (orange, full width) — inserts to `user_meals` and pops sheet
- [ ] On "Add to Meal": call `NutritionService.addMeal(...)` with selected `meal_type`, `food_id`, and `serving_quantity`; call `_loadNutritionData()` to refresh daily totals

### 15.5 — Scanner UX Polish
- [ ] Update barcode scanner overlay: add animated scan-line animation inside the guide rectangle
- [ ] Show product name in the bottom instruction chip immediately after scan (before sheet opens): "Found: Monster Energy — loading..."
- [ ] If camera permission is denied, show actionable empty state: icon + "Camera permission required" + "Open Settings" button

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
