# Project Structure

> Read this when: exploring the codebase, adding a new file, unsure where something lives.

---

## Directory Tree

```
smartfitai/
├── lib/
│   ├── main.dart                          # Entry point — Sizer + MaterialApp + portrait lock
│   │                                      # ⚠ NEVER remove textScaler: TextScaler.linear(1.0) block
│   ├── core/
│   │   └── app_export.dart                # Barrel export — imported by most screens
│   ├── routes/
│   │   └── app_routes.dart                # All named routes + onGenerateRoute for arg-based routes
│   ├── theme/
│   │   └── app_theme.dart                 # Complete Material 3 light + dark theme (895 lines)
│   │                                      # ALL color tokens live here — never raw hex in screens
│   ├── services/                          # Business logic singletons → lib/services/CLAUDE.md
│   │   ├── supabase_service.dart          # Client init — use SupabaseService.instance.client
│   │   ├── auth_service.dart              # signUp / signIn / signOut / getCurrentUser
│   │   ├── gemini_ai_service.dart         # All Gemini AI plan generation (918 lines)
│   │   ├── ai_nutrition_service.dart      # Nutrition-specific AI calls
│   │   ├── calorie_calculator_service.dart# TDEE + macro math (pure, no I/O)
│   │   ├── body_measurements_service.dart # Body metrics CRUD (added M7)
│   │   ├── nutrition_service.dart         # Food log CRUD
│   │   └── workout_service.dart           # Workout session CRUD
│   ├── data/                              # Models + static data → lib/data/CLAUDE.md
│   │   ├── models/
│   │   │   └── ai_plan_models.dart        # AIPlanResponse → TrainingPlan / NutritionPlan
│   │   ├── services/
│   │   │   └── ai_plan_service.dart       # Persist/load AI plans to Supabase
│   │   └── verified_exercises_data.dart   # Static exercise database (source of truth)
│   ├── presentation/                      # One folder per screen → lib/presentation/CLAUDE.md
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   ├── signup_screen.dart
│   │   │   └── onboarding_survey_screen.dart
│   │   ├── authentication_onboarding_flow/  # Real initial route — auth state machine
│   │   │   ├── authentication_onboarding_flow.dart
│   │   │   └── widgets/
│   │   │       ├── login_form_widget.dart
│   │   │       ├── register_form_widget.dart
│   │   │       └── onboarding_survey_widget.dart
│   │   ├── main_dashboard/
│   │   │   ├── main_dashboard.dart          # Bottom nav shell with nested Navigator
│   │   │   ├── main_dashboard_initial_page.dart
│   │   │   └── widgets/
│   │   ├── ai_workout_generator/
│   │   │   ├── ai_workout_generator.dart
│   │   │   └── widgets/
│   │   ├── ai_nutrition_planner/
│   │   │   ├── ai_nutrition_planner.dart
│   │   │   └── widgets/
│   │   ├── ai_plan/                         # Combined AI plan view (workout + nutrition tabs)
│   │   │   ├── ai_plan_screen.dart
│   │   │   └── widgets/
│   │   ├── exercise_library/
│   │   │   ├── exercise_library.dart
│   │   │   └── widgets/
│   │   ├── nutrition_planning_screen/
│   │   │   ├── nutrition_planning_screen.dart
│   │   │   └── widgets/
│   │   ├── progress_tracking_screen/
│   │   │   ├── progress_tracking_screen.dart
│   │   │   └── widgets/
│   │   ├── strength_progress/
│   │   │   ├── strength_progress_screen.dart
│   │   │   └── exercise_details_screen.dart
│   │   ├── workout_detail_screen/
│   │   │   ├── workout_detail_screen.dart
│   │   │   └── widgets/
│   │   └── user_profile_management/
│   │       ├── user_profile_management.dart
│   │       └── widgets/
│   └── widgets/                             # App-wide reusable components
│       ├── custom_app_bar.dart
│       ├── custom_bottom_bar.dart           # ⚠ Labels in Romanian — fix in M9
│       ├── custom_icon_widget.dart          # Bundled icon library (469KB) — use for ALL icons
│       ├── custom_image_widget.dart         # Cached network image wrapper
│       └── custom_error_widget.dart
├── assets/
│   └── images/
├── docs/                                    # Reference files — read on demand, not every session
│   ├── PROJECT_STRUCTURE.md               ← this file
│   ├── ROUTE_MAP.md                       # Full route table + bottom nav order
│   └── TECH_STACK.md                      # All packages + versions + why each is used
├── env.json                                 # API keys (gitignored — never commit)
├── pubspec.yaml                             # Dependencies
├── CLAUDE.md                               # Root context — read every session
├── TASKS.md                                # Milestone tracker
└── SESSION_WORKFLOW.md                     # Kickoff + end-of-session prompts
```

---

## Data Flow

```
Screen (StatefulWidget + setState)
  └─► Service singleton
        ├─► Supabase (PostgreSQL) — auth, user data, workout logs, measurements
        └─► Gemini HTTP API — AI plan generation
              └─► Response parsed into typed model or raw Map<String, dynamic>
                    └─► setState() → UI rebuild
```

State management: vanilla `StatefulWidget` + `setState`. No Provider / Bloc / Riverpod.

---

## Key Files to Read Before Touching a Feature

| Before working on... | Read this first |
|---|---|
| Any navigation change | `lib/routes/app_routes.dart` + `docs/ROUTE_MAP.md` |
| Any color / typography | `lib/theme/app_theme.dart` |
| Auth flow or onboarding | `lib/presentation/authentication_onboarding_flow/authentication_onboarding_flow.dart` |
| AI plan generation | `lib/services/gemini_ai_service.dart` (918 lines) |
| AI response parsing | `lib/data/models/ai_plan_models.dart` |
| Exercise library or data | `lib/data/verified_exercises_data.dart` |
| Body measurements | `lib/services/body_measurements_service.dart` |
