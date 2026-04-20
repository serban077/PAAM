# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Project Overview

**SmartFitAI** is a Flutter mobile app (Android/iOS) generating AI-powered workout and nutrition plans via Google Gemini, with Supabase as backend/auth. University PAAM project (deadline: 19.01.2026). No ads, no in-app purchases.

---

## Current Status

**Last updated:** 2026-04-20
**Last session:** M26 — Network Layer Hardening & Offline Resilience complete. New `lib/services/_dio_interceptors.dart`: `AppLogInterceptor` (debug-only), `NetworkOfflineException`, `assertConnected()`, `withRetry()` (3 retries, 500ms exp backoff). OpenFoodFactsService + UsdaFoodService: logging interceptor, retry, `CancelToken?` param on `searchFoods()`, offline fast-fail. GeminiAIService: `AppLogInterceptor` added. FoodRecognitionService: `CancelToken?` passthrough to `createChat()`, offline guard. SmartRecipeService: offline guard. AppCacheService: external search cache (10 min LRU-20) + vision result cache (10 min). AddFoodModalWidget: `CancelToken` cancels previous query on each new keystroke; external cache checked before hitting OFF+USDA. PhotoRecipeScreen: `CancelToken` cancelled on dispose; `_imageKey()` fingerprint for vision cache read/write. `flutter analyze lib/` → **0 issues**.
**Next session starts with:** M27 — Supabase Query & Index Optimization
**Active branches:** main
**Blockers:** `pubspec.lock` is gitignored — run `flutter pub get` at every session start. `kotlin.incremental=false` in android/gradle.properties — required for Windows cross-drive build (pub cache on C:, project on D:); do not remove. DB enum values fully English. USDA_API_KEY in env.json only. Gemini 2.5 Flash needs `maxTokens ≥ 8192` for OCR. Exercise animations use free-exercise-db CDN. `Stack(fit: StackFit.expand)` required for IndexedStack overlay. `memCacheWidth` needs `.isFinite` guard. M20 manual config: "Confirm email" ✅ enabled; hCaptcha skipped (PAAM project, no paid tier needed). M19 deferred: pagination UI, streak RPC, lazy ProgressTrackingScreen, SharedPreferences layer. `DropdownButtonFormField` uses `initialValue:` not deprecated `value:` (Flutter 3.33+). Supabase remaining (intentional/deferred): 2 food_database rls_policy_always_true (any auth user can add/edit foods — by design), unused_index INFO on FK indexes (expected — just created, no query traffic yet), auth_leaked_password_protection (enable manually: Supabase Dashboard → Auth → Password Security).

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
{ "SUPABASE_URL": "...", "SUPABASE_ANON_KEY": "...", "GEMINI_API_KEY": "...", "STRIPE_PUBLISHABLE_KEY": "..." }
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
