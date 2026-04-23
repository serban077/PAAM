# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Project Overview

**SmartFitAI** is a Flutter mobile app (Android/iOS) generating AI-powered workout and nutrition plans via Google Gemini, with Supabase as backend/auth. University PAAM project (deadline: 19.01.2026). No ads, no in-app purchases.

---

## Current Status

**Last updated:** 2026-04-24
**Last session:** M32 continued — fixed two issues + fine-tuned recipe prompt. (1) Food recognition was failing with `FormatException: Unterminated string at "category"` because `gemini-3-flash-preview` is a thinking model and thought tokens consumed the 2048-token output budget, truncating JSON mid-emit. Fixed by bumping `FoodRecognitionService` `maxTokens` to 8192 and setting `thinkingBudget: 0` (added optional `thinkingBudget` param to `GeminiClient.createChat` → wires into `generationConfig.thinkingConfig.thinkingBudget`). Correct preview model IDs verified via ListModels: `gemini-3-flash-preview` and `gemini-3.1-flash-lite-preview` (the `-preview` suffix is handled by existing `_requiresV1Beta` predicate). `SmartRecipeService` uses `thinkingBudget: 2048` (reasoning task, keeps 8192 output); nutrition-label text path `thinkingBudget: 0`; nutrition-label vision fallback `thinkingBudget: 512`. (2) "Log this meal" from PhotoRecipe wasn't showing under the selected meal type — `NutritionPlanningScreen` was calling `_loadNutritionData()` without `forceRefresh`, hitting the 5-min stale cache. Fix: `_cache.invalidateNutrition(_dateKey); _loadNutritionData(forceRefresh: true);` + `if (!mounted) return;` guard on the photo-recipe return. (3) Recipe-generation prompt heavily extended in `_ai_prompts.dart`: new `kNutritionKnowledgeSection` covers FAT QUALITY (saturated/trans/mono/poly caps + cooking fat rules), PROTEIN QUALITY (DIAAS, leucine 2.5 g threshold, legume+grain complementation, IARC processed-meat warning), CARB QUALITY (whole vs refined, WHO <25 g added sugar/day, 25–30 g fiber/day), SODIUM (hidden-source catalogue), MICRONUTRIENT DENSITY (per-meal targets), COOKING METHODS (ranked best→worst, deep-fry forbidden), HYDRATION/TIMING, SATIETY DESIGN. `kRecipePreferredSourcesSection` and `kRecipeTasteBoostersSection` rewritten with per-group explanations (turmeric+piperine, Romanian mirepoix, etc.). `kRecipeFailureModesSection` now a 10-item self-check + extended OUTPUT FIELDS including `protein_density ≥ 8 g/100 kcal` target and Romanian descriptions that highlight the nutritional win. `buildRecipePrompt()` wired to include the new section between USER CONTEXT and HARD CONSTRAINTS. `flutter analyze lib/` → **0 issues**; `flutter test test/unit/ test/widget/` → **79/79 passed**.
**Next session starts with:** M33 — Accessibility & Final Polish
**Active branches:** main
**Blockers:** `pubspec.lock` is gitignored — run `flutter pub get` at every session start. `kotlin.incremental=false` in android/gradle.properties — required for Windows cross-drive build; do not remove. DB enum values fully English. USDA_API_KEY in env.json only. Gemini 2.5/3 Flash needs `maxTokens ≥ 8192` for JSON output. `DropdownButtonFormField` uses `initialValue:` not deprecated `value:` (Flutter 3.33+). Supabase remaining (intentional/deferred): 2 food_database rls_policy_always_true (by design), unused_index INFO, auth_leaked_password_protection (enable manually). M29 manual setup: SENTRY_DSN + POSTHOG_API_KEY in env.json. PostHog 4.x opt-out is SharedPreferences-only. `User.createdAt` returns `String` — use `DateTime.tryParse`. **M30 testing notes**: golden PNGs must be generated via GitHub Actions "Update Goldens" workflow (never on Windows). Ahem test font causes proportional Row text to overflow — use `ignoreOverflowErrors()` for affected tests. Supabase stub init pattern (fake URL + anon key in `setUpAll`) required for screens with `AuthService` field initializer. **M32 notes**: (a) nutrition policy (blocklist, macro guards, preferred sources, taste boosters, recipe constraints, full nutrition-knowledge section) lives ONLY in `lib/services/_ai_prompts.dart` — update there, never inline. (b) Google AI Studio UI labels ≠ API model IDs — always verify with `ListModels` before switching model strings; current production IDs are `gemini-3-flash-preview` (vision/reasoning) and `gemini-3.1-flash-lite-preview` (text/plans) — the `-preview` suffix makes them route via `/v1beta` automatically. (c) **Thinking-model rule**: any Gemini 3.x call that returns structured JSON MUST set an explicit `thinkingBudget` in `createChat` — use `0` for pure perception/parsing (food recognition, OCR text parse), `512` for vision fallback with light reasoning, `2048` for recipe generation / planning. Omitting it causes thought tokens to eat the `maxTokens` budget and truncate JSON. (d) After any parent-refresh pop from a sub-screen (e.g. PhotoRecipe → NutritionPlanning), call `_cache.invalidateNutrition(_dateKey)` before `_loadNutritionData(forceRefresh: true)` — otherwise the 5-min AppCache hides the freshly logged row. M30/M31 deferred: `OnboardingSurveyScreen`/`NutritionPlanningScreen` widget tests, Patrol integration tests, `AuthService`/`NutritionService` unit tests, cold-start trace (needs device). M32 deferred: recipe-detail UI surface for `warning`/`blocklisted_ingredients_skipped`/`protein_density` (lands in M33).

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
