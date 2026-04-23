# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Project Overview

**SmartFitAI** is a Flutter mobile app (Android/iOS) generating AI-powered workout and nutrition plans via Google Gemini, with Supabase as backend/auth. University PAAM project (deadline: 19.01.2026). No ads, no in-app purchases.

---

## Current Status

**Last updated:** 2026-04-23
**Last session:** M32 — AI Food Recognition & Recipe Generation Overhaul complete. Model swap: `gemini-2.5-flash-lite` → `gemini-3.1-flash-lite` for all text-only calls (`generateWeeklyWorkoutPlan`, `generateNutritionPlan`, `getPersonalizedExercises`, `streamWeeklyWorkoutPlan`, `createChatStream` default, `GeminiNutritionLabelService` text path); `gemini-2.5-flash` → `gemini-3-flash` for vision/reasoning (`FoodRecognitionService`, `SmartRecipeService`, `GeminiNutritionLabelService` vision fallback). `GeminiAIService._requiresV1Beta` extended to route all `gemini-3*` through `/v1beta` (v1 serves only stable 2.x). New `lib/services/_ai_prompts.dart` — single source of truth for nutrition policy: `kBlockedIngredients`, `kMacroGuardsPer100g`, `kPreferredSources`, `kTasteBoosters`, `kQuantityReferenceG`, `RecipeConstraints`, `kFoodRecognitionPrompt`, `buildRecipePrompt()`. Food recognition prompt restructured as atomic doc sections (ROLE/TASK/SPEC/RULES/TABLE/AMBIGUITY/CATEGORIES/EXAMPLES). Recipe prompt adds hard per-serving constraints (protein ≥25g, fat ≤20g, sat fat ≤5g, sugar ≤10g, sodium ≤600mg, fiber ≥5g), ingredient blocklist, macro guards, preferred sources, dietary overrides, failure modes — Romanian output explicitly required. `GeneratedRecipe` + `_recipeSchema` extended with `warning` (nullable), `macro_compliance` (bool), `blocklisted_ingredients_skipped` (array), `protein_density` (g/100kcal). `smart_recipe_service.dart._fetchUserContext` now pulls `fitness_goal` + `dietary_preference` from `user_profiles` (was macro-only). TASKS.md renumbered: M32 is new, old M32 Accessibility → M33, old M33 Regression → M34. `flutter analyze lib/` → **0 issues**; `flutter test test/unit/ test/widget/` → **79/79 passed**.
**Next session starts with:** M33 — Accessibility & Final Polish
**Active branches:** main
**Blockers:** `pubspec.lock` is gitignored — run `flutter pub get` at every session start. `kotlin.incremental=false` in android/gradle.properties — required for Windows cross-drive build; do not remove. DB enum values fully English. USDA_API_KEY in env.json only. Gemini 2.5/3 Flash needs `maxTokens ≥ 8192` for OCR/plan JSON output. `DropdownButtonFormField` uses `initialValue:` not deprecated `value:` (Flutter 3.33+). Supabase remaining (intentional/deferred): 2 food_database rls_policy_always_true (by design), unused_index INFO, auth_leaked_password_protection (enable manually). M29 manual setup: SENTRY_DSN + POSTHOG_API_KEY in env.json. PostHog 4.x opt-out is SharedPreferences-only. `User.createdAt` returns `String` — use `DateTime.tryParse`. **M30 testing notes**: golden PNGs must be generated via GitHub Actions "Update Goldens" workflow (never on Windows). Ahem test font causes proportional Row text to overflow — use `ignoreOverflowErrors()` for affected tests. Supabase stub init pattern (fake URL + anon key in `setUpAll`) required for screens with `AuthService` field initializer. **M32 note**: nutrition policy (blocklist, macro guards, preferred sources, taste boosters, recipe constraints) lives ONLY in `lib/services/_ai_prompts.dart` — update there, never inline in service files. Gemini 3.x models route through `/v1beta` via `_requiresV1Beta` — adding new 3.x models does not require any call-site change. M30/M31 deferred: `OnboardingSurveyScreen`/`NutritionPlanningScreen` widget tests, Patrol integration tests, `AuthService`/`NutritionService` unit tests, cold-start trace (needs device). M32 deferred: recipe-detail UI surface for `warning`/`blocklisted_ingredients_skipped`/`protein_density` (lands in M33).

---

## Commands

```bash
flutter pub get                                   # Install deps — run at session start
flutter run --dart-define-from-file=env.json      # Run app — REQUIRED, crashes without env.json
flutter analyze                                   # Lint
flutter build apk --release                       # Android build
flutter build ios --release                       # iOS build
```

---

## Important Rules

### NEVER
- **NEVER** add `Co-Authored-By` or any Claude attribution to commit messages — all commits are authored by `serban077 <serban.07@yahoo.com>` only
- **NEVER** hardcode API keys — use `const String.fromEnvironment('KEY_NAME')`
- **NEVER** use fixed px values — use Sizer: `10.h` / `40.w` / `14.sp`
- **NEVER** use emoji as icons — use `CustomIconWidget` from `lib/widgets/`
- **NEVER** remove the `textScaler: TextScaler.linear(1.0)` block in `main.dart`
- **NEVER** add argument-based routes to the static `routes` map — use `onGenerateRoute`
- **NEVER** access Supabase directly — always `SupabaseService.instance.client`
- **NEVER** commit `env.json` — it is gitignored and contains live secrets
- **NEVER** introduce Provider / Riverpod / Bloc — app uses vanilla `setState` intentionally
- **NEVER** use Romanian strings for DB enum columns — all enum values are English: `weight_loss`, `muscle_gain`, `sedentary`, `lightly_active`, `moderately_active`, `very_active`, `extremely_active`, `gym`, `home_no_equipment`, `home_basic_equipment`, `mix`, `gluten_free`, `dairy_free`, `male`, `female`, `other`, `prefer_not_to_say`

### ALWAYS
- **ALWAYS** run with `--dart-define-from-file=env.json`
- **ALWAYS** wrap async calls in `try/catch` + `.timeout(const Duration(seconds: 15))`
- **ALWAYS** place new screens in their own folder: `lib/presentation/<screen_name>/`
- **ALWAYS** reference routes via `AppRoutes` constants, never raw strings
- **ALWAYS** implement both light and dark variants when adding color tokens to `app_theme.dart`
- **ALWAYS** use `CustomImageWidget` for network images

### Naming
- Classes: `PascalCase` → `WorkoutDetailScreen`
- Files: `snake_case` → `workout_detail_screen.dart`
- Services: `camelCase` verbs → `signIn()`, `generatePlan()`
- Private fields: `_camelCase` → `_isLoading`, `_currentUser`

---

## Environment Variables

`env.json` at project root (gitignored):
```json
{ "SUPABASE_URL": "...", "SUPABASE_ANON_KEY": "...", "GEMINI_API_KEY": "...", "STRIPE_PUBLISHABLE_KEY": "...", "SENTRY_DSN": "...", "POSTHOG_API_KEY": "..." }
```
Access in Dart: `const String.fromEnvironment('GEMINI_API_KEY')`

---

## Reference Docs — Read on Demand

> These files contain details that are **not needed every session**.
> Read them only when the task requires it.

| File | Read when... |
|---|---|
| `docs/PROJECT_STRUCTURE.md` | Exploring the codebase, adding files, unsure where something lives |
| `docs/ROUTE_MAP.md` | Adding a screen, changing navigation, debugging routing |
| `docs/TECH_STACK.md` | Adding a package, debugging a dependency, checking versions |
| `lib/presentation/CLAUDE.md` | Working on any screen, widget, or UI pattern |
| `lib/services/CLAUDE.md` | Working on Supabase queries, Gemini AI, or service logic |
| `lib/data/CLAUDE.md` | Working on data models or the exercise database |

---

## Session Workflow

Kickoff + end-of-session prompts → `SESSION_WORKFLOW.md`
