# TASKS.md — SmartFitAI

Milestone-based task tracker. Mark tasks `[x]` as they are completed.
Update `## Current Status` in `CLAUDE.md` at the end of every session.

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
- [~] Commit uncommitted changes to `onboarding_survey_screen.dart` and `auth_service.dart`

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
- [ ] Add retry logic for Gemini API failures (currently fails silently)
- [ ] Add loading skeleton while AI generates plans (currently shows spinner)

---

## Milestone 4 — Main Dashboard ✅

- [x] Create `MainDashboard` — bottom navigation shell with nested `Navigator`
- [x] Create `MainDashboardInitialPage` — home tab showing daily plan overview
- [x] Implement `CustomBottomBar` with 5 tabs: Home / Workouts / Nutrition / Progress / Profile
- [x] Wire bottom nav tabs to correct routes in exact order
- [x] Dashboard home tab: show today's workout card (linked to AI-generated plan)
- [x] Dashboard home tab: show today's meal summary (calories, macros)
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
- [ ] Integrate `youtube_player_flutter` to show exercise demo video on detail screen

---

## Milestone 6 — Nutrition Planning ✅

- [x] Create `NutritionPlanningScreen` — manual food tracking interface
- [x] Create `NutritionService` for CRUD operations on Supabase nutrition table
- [ ] Implement food search (search by name, return macros)
- [ ] Implement `mobile_scanner` barcode scan to look up food by barcode
- [ ] Add daily calorie and macro progress bars (using fl_chart or linear indicators)
- [ ] Display AI-generated meal plan in nutrition tab
- [ ] Allow marking individual meals as eaten

---

## Milestone 7 — Progress & Measurements Tracking ✅

- [x] Create `ProgressTrackingScreen` with fl_chart charts (weight over time, workouts per week)
- [x] Create `StrengthProgressScreen` for tracking personal records per exercise
- [x] Create `BodyMeasurementsService` for storing body measurements in Supabase
- [x] Add body measurements tracking UI (chest, waist, hips, arms, etc.)
- [ ] Connect body measurements to charts in `ProgressTrackingScreen`
- [ ] Add before/after photo comparison using `before_after` widget
- [ ] Show PR (personal record) badges on strength exercises

---

## Milestone 8 — User Profile ✅

- [x] Create `UserProfileManagement` screen — display and edit profile info
- [x] Show user name, email, fitness goals from onboarding
- [x] Allow editing profile fields (goal, fitness level, dietary preference)
- [x] Allow updating physical stats (weight, height) and recalculating TDEE
- [x] Add sign-out button with confirmation dialog
- [ ] Add dark mode toggle (ThemeMode is hardcoded to `ThemeMode.light`)

---

## Milestone 9 — UI Polish & Localization

- [~] Replace all Romanian UI strings with English equivalents
  - [ ] `CustomBottomBar` labels: "Acasă" → "Home", "Antrenamente" → "Workouts", "Nutriție" → "Nutrition", "Progres" → "Progress", "Profil" → "Profile"
  - [ ] `AuthenticationOnboardingFlow`: "Conectează-te" → "Sign In", "Creează cont" → "Create Account"
  - [ ] `WorkoutDetailScreen`: "Detalii Antrenament" → "Workout Details", "Detalii..." → actual content
  - [ ] Scan all `presentation/` screens for remaining Romanian strings
- [ ] Add empty states for all screens that load data (no workouts yet, no meals yet, etc.)
- [ ] Add pull-to-refresh on all list screens
- [ ] Add proper loading shimmer skeletons (replace all `CircularProgressIndicator` for data loads >300ms)
- [ ] Ensure all tap targets are at minimum 44×44pt
- [ ] Review and fix any remaining layout overflow issues on small screens (375px width)
- [ ] Add haptic feedback (`HapticFeedback.lightImpact()`) to primary actions (already on bottom nav)
- [ ] Implement app splash screen / icon assets in `assets/`

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
