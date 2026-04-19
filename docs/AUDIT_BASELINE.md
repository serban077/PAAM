# SmartFitAI — Audit Baseline

**Measured:** 2026-04-16  
**Flutter version:** Current stable (flutter upgrade available)  
**Purpose:** Reference point for milestones M23–M33. Every optimization milestone re-measures and compares against this document.

---

## Quick Summary

| Category | Metric | Value | Target |
|---|---|---|---|
| Dart errors (main app) | `flutter analyze` | **0** | 0 |
| Dart warnings (main app) | `flutter analyze` | **10** | 0 |
| Dart infos (main app) | `flutter analyze` | **~100** | <20 |
| Dart errors (PAAM subfolder) | `flutter analyze` | **7** | — (separate project) |
| Raw `print()` calls in lib/ | grep | **2** | 0 |
| `TODO` markers in lib/ | grep | **1** | 0 |
| APK release build | `flutter build apk --release` | **FAILED (R8)** | PASS |
| Direct deps outdated (major) | `flutter pub outdated` | **8** | 0 |
| Direct deps outdated (minor) | `flutter pub outdated` | **8** | 0 |
| Unused packages (confirmed) | import grep | **4** | 0 |
| Security advisors | Supabase | **13 WARN** | 0 |
| Performance advisors | Supabase | **72 (28 WARN, 44 INFO)** | 0 WARN |
| DB tables | Supabase | **18** | — |
| RLS enabled on all tables | Supabase | **Yes (18/18)** | Yes |
| Postgres error logs (24h) | Supabase | **0 errors** | 0 |

---

## 1. Static Analysis (`flutter analyze`)

**Total: 125 issues** — exit code 1 (due to PAAM subfolder errors)

### 1a. Main app `lib/` issues (0 errors, ~10 warnings, ~100 infos)

**Warnings (~10) — fix in M22 fix pass:**

| File | Line | Lint | Issue |
|---|---|---|---|
| `presentation/exercise_library/exercise_library.dart` | 277 | `unused_element` | `_createCustomWorkout` declared but never called |
| `presentation/main_dashboard/main_dashboard_initial_page.dart` | 25 | `unused_field` | `_recentWorkouts` never read |
| `presentation/main_dashboard/main_dashboard_initial_page.dart` | 95 | `unnecessary_non_null_assertion` | `!` on non-nullable value |
| `presentation/main_dashboard/main_dashboard_initial_page.dart` | 157 | `unused_element` | `_calculateNutritionTotals` declared but never called |
| `presentation/main_dashboard/main_dashboard_initial_page.dart` | 192/196 | `unused_local_variable` | `calorieGoal`, `consumedCalories` never used |
| `presentation/nutrition_planning_screen/widgets/ai_meal_plan_section.dart` | 115 | `unused_element` | `_addMealToDay` declared but never called |
| `presentation/progress_tracking_screen/progress_tracking_screen.dart` | 5-7 | `unused_import` | 3 widget imports no longer used |
| `presentation/progress_tracking_screen/progress_tracking_screen.dart` | 64-66 | `unused_local_variable` | `currentWeight`, `targetWeight`, `height` never used |
| `presentation/progress_tracking_screen/widgets/photo_progress_widget.dart` | 23 | `unused_field` | `_capturedImage` never read |
| `presentation/progress_screen/widgets/body_measurements_card.dart` | 5 | `unused_import` | `supabase_service.dart` unused |
| `presentation/strength_progress/exercise_details_screen.dart` | 164 | `unused_local_variable` | `theme` never used |
| `presentation/user_profile_management/user_profile_management.dart` | 25 | `unused_field` | `_isRegenerating` never read |
| `presentation/user_profile_management/widgets/account_management_section_widget.dart` | 37 | `unused_local_variable` | `theme` never used |
| `services/ai_nutrition_service.dart` | 41/250 | `unused_local_variable`, `unused_element` | `prompt` var + `_parseAIResponse` method never used |
| `widgets/custom_app_bar.dart` | 61 | `unused_local_variable` | `colorScheme` never used |

**Infos (~100) — fix in M22/M32 fix pass:**

| Category | Count | Lint | Fix |
|---|---|---|---|
| `withOpacity` deprecated | 22+ | `deprecated_member_use` | Replace `.withOpacity(x)` → `.withValues(alpha: x)` |
| `RadioGroup` deprecated | 8 | `deprecated_member_use` | Wrap `Radio` in `RadioGroup` ancestor (Flutter 3.32+) |
| `DropdownButtonFormField value` deprecated | 5 | `deprecated_member_use` | Replace `value:` → `initialValue:` (Flutter 3.33+) |
| `BuildContext` across async gaps | 11 | `use_build_context_synchronously` | Add `if (!mounted) return` before each context use |
| `avoid_print` | 2 | `avoid_print` | Replace with `debugPrint` in gemini_ai_service.dart |
| `empty_catches` | 2 | `empty_catches` | Add at minimum `// ignore` with reason comment |
| `unnecessary_import` | 1 | `unnecessary_import` | Remove `dart:typed_data` from gemini_nutrition_label_service.dart |
| `dangling_library_doc_comments` | 1 | `dangling_library_doc_comments` | Add `library;` directive in smart_recipe_models.dart |
| `unnecessary_to_list_in_spreads` | 2 | `unnecessary_to_list_in_spreads` | Remove `.toList()` from `...list.toList()` |

### 1b. PAAM subfolder `PAAM/lib/` — 7 errors (separate academic project, does NOT affect app build)

| File | Error |
|---|---|
| `PAAM/lib/presentation/exercise_library/exercise_library.dart` | Missing `core/app_export.dart` import |
| `PAAM/lib/presentation/exercise_library/widgets/filter_bottom_sheet_widget.dart` | Missing `core/app_export.dart` import |
| `PAAM/lib/presentation/exercise_library/widgets/filter_chip_widget.dart` | Missing `core/app_export.dart` import |
| `PAAM/lib/presentation/progress_tracking_screen/widgets/weekly_calendar_widget.dart` | Missing `services/supabase_service.dart` + 4× `SupabaseService` undefined |

> **Note:** These errors only appear because `flutter analyze` recurses into the PAAM folder. They have no impact on the app. Fix: either add a `.dart_tool/` suppress or move PAAM out of the project root.

### 1c. Code debris

| Type | Count | Location |
|---|---|---|
| Raw `print()` (not `debugPrint`) | 2 | `lib/services/gemini_ai_service.dart:205, 328` |
| `TODO` marker | 1 | `lib/presentation/authentication_onboarding_flow/widgets/onboarding_survey_widget.dart:240` |
| `FIXME` / `HACK` / `XXX` | 0 | — |

---

## 2. Dependency Health

### 2a. Direct dependencies — version status

| Package | Current | Minor Upgrade | Major Upgrade | Notes |
|---|---|---|---|---|
| `camera` | 0.10.6 | — | **0.12.0+1** | Major; also confirmed **unused** in lib/ → remove |
| `connectivity_plus` | 6.1.5 | — | **7.1.1** | Major |
| `dio` | 5.9.0 | **5.9.2** | — | Safe minor |
| `fl_chart` | 0.65.0 | — | **1.2.0** | Major — likely breaking API changes |
| `flutter_secure_storage` | 9.2.4 | — | **10.0.0** | Major |
| `flutter_svg` | 2.2.3 | **2.2.4** | — | Safe minor |
| `fluttertoast` | 8.2.14 | — | **9.0.0** | Major; Android deprecated APIs in current version |
| `google_fonts` | 6.3.3 | — | **8.0.2** | Major; skips v7 |
| `google_mlkit_text_recognition` | 0.14.0 | **0.15.1** | — | Minor; fixes R8 issues |
| `intl` | 0.19.0 | — | **0.20.2** | Major |
| `local_auth` | 2.3.0 | — | **3.0.1** | Major |
| `mobile_scanner` | 7.1.4 | **7.2.0** | — | Safe minor |
| `permission_handler` | 11.4.0 | — | **12.0.1** | Major |
| `shared_preferences` | 2.5.4 | **2.5.5** | — | Safe minor |
| `sizer` | 2.0.15 | — | **3.1.3** | **CAUTION** — Major; could break all `.h/.w/.sp` sizing |
| `supabase_flutter` | 2.12.0 | **2.12.2** | — | Safe minor |
| `flutter_lints` (dev) | 5.0.0 | — | **6.0.0** | Major (dev only) |

**Discontinued packages:**
- `js: ^0.6.7` — **DISCONTINUED** by Dart team. Must be replaced. Likely a transitive dep — check what depends on it.

### 2b. Unused packages — confirmed by import grep in `lib/`

All 4 packages below have **zero imports** in `lib/` — safe to remove:

| Package | pubspec.yaml version | Was used for | Safe to remove? |
|---|---|---|---|
| `youtube_player_flutter` | ^9.1.3 | Exercise demo videos (replaced by GIFs in M19) | ✅ Yes |
| `universal_html` | ^2.2.4 | Unknown — never imported | ✅ Yes |
| `before_after` | ^3.2.0 | Photo comparison (removed from progress screen) | ✅ Yes |
| `camera` | ^0.10.5+5 | Active workout camera (replaced by `image_picker`) | ✅ Yes |

> **Estimated APK savings from removing these 4:** ~2–5 MB (youtube_player alone is significant)

### 2c. Safe minor upgrades (low risk, can do in one pass)

`dio`, `flutter_svg`, `mobile_scanner`, `shared_preferences`, `supabase_flutter`, `google_mlkit_text_recognition`

---

## 3. Build Size

### 3a. Release APK — **BUILD FAILED**

**Reason:** R8 shrinking fails on `google_mlkit_text_recognition` — references optional script recognizer classes (Chinese/Devanagari/Japanese/Korean) that are not bundled.

**Blocker severity:** HIGH — no release APK can be generated without this fix.

**Fix (generated by Gradle):** Add these 8 lines to `android/app/proguard-rules.pro` (file must be created/referenced in `build.gradle.kts`):

```
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions
```

**Milestone responsible:** M31.1 (Build Flags) — fix this first, then re-measure APK size.

### 3b. Runtime measurements (deferred — needs device)

Fill in during a device session with `flutter run --profile`:

| Metric | Baseline Value | Re-measure after M31 |
|---|---|---|
| Cold start — login screen | ___ ms | ___ ms |
| Cold start — dashboard (returning user) | ___ ms | ___ ms |
| APK size (release, arm64) | ___ MB | ___ MB |
| Frame render time — exercise library scroll (avg) | ___ ms | ___ ms |
| Jank frames per 1000 on dashboard | ___ | ___ |
| Dashboard idle memory | ___ MB | ___ MB |
| Memory after 5-min navigation loop | ___ MB | ___ MB |
| FPS on 90/120Hz device | ___ fps | ___ fps (after M23) |

> **How to measure:** `flutter run --trace-startup --profile` → DevTools → Performance tab + Memory tab

---

## 4. Database Health (Supabase)

### 4a. Tables overview

**18 tables, 18/18 with RLS enabled.**

| Table | RLS | Rows | Notes |
|---|---|---|---|
| `food_database` | ✅ | 375 | Has permissive INSERT/UPDATE policies (see security) |
| `onboarding_responses` | ✅ | 204 | OK |
| `workout_sessions` | ✅ | 141 | Multiple permissive policies |
| `session_exercises` | ✅ | 72 | Multiple permissive policies |
| `workout_plans` | ✅ | 8 | Most policy issues concentrated here |
| `exercises` | ✅ | 16 | Multiple permissive SELECT policies |
| `daily_nutrition_goals` | ✅ | 12 | OK |
| `body_measurements` | ✅ | 11 | 4 `auth_rls_initplan` warnings |
| `user_meals` | ✅ | 11 | OK |
| `ai_nutrition_plans` | ✅ | 6 | 4 `auth_rls_initplan` warnings |
| `strength_progress` | ✅ | 5 | Missing 2 FK indexes |
| `workout_logs` | ✅ | 4 | Missing 3 FK indexes |
| `workout_set_logs` | ✅ | 7 | Missing 2 FK indexes |
| `progress_photos` | ✅ | 1 | OK |
| `user_workout_schedules` | ✅ | 1 | Missing 2 FK indexes |
| `user_profiles` | ✅ | 0 | 2 unused indexes |
| `auth_backup_codes` | ✅ | 0 | Missing 1 FK index |
| `workout_categories` | ✅ | 0 | 1 unused index |

### 4b. Security advisors — 13 WARN

**`function_search_path_mutable` (10 functions) — WARN**

All 10 Postgres functions lack a fixed `search_path`, making them vulnerable to search-path injection:

`delete_my_account`, `delete_user_custom_plans`, `calculate_daily_calories`, `deactivate_old_nutrition_plans`, `update_body_measurements_updated_at`, `get_safe_workout_plans`, `generate_workout_plan`, `handle_new_user`, `calculate_daily_nutrition_totals`, `search_food`

**Fix:** Add `SET search_path = public` to each function definition (migration required).  
**Milestone:** M27.5 — Ref: [Supabase Docs](https://supabase.com/docs/guides/database/database-linter?lint=0011_function_search_path_mutable)

---

**`rls_policy_always_true` (2 policies) — WARN**

| Table | Policy | Issue |
|---|---|---|
| `food_database` | `authenticated_can_add_food` (INSERT) | `WITH CHECK (true)` — any authenticated user can insert any row |
| `food_database` | `authenticated_can_update_food` (UPDATE) | Both USING and WITH CHECK are `true` — any user can update any food |

**Fix:** Tighten INSERT to require `contributed_by = auth.uid()` check; UPDATE to only allow own rows.  
**Milestone:** M27.5 — Ref: [Supabase Docs](https://supabase.com/docs/guides/database/database-linter?lint=0024_permissive_rls_policy)

---

**`auth_leaked_password_protection` (1) — WARN**

HaveIBeenPwned.org password check is disabled in Supabase Auth settings.

**Fix:** Enable in Supabase Dashboard → Auth → Password Strength.  
**Milestone:** M27.5

### 4c. Performance advisors — 72 issues (28 WARN, 44 INFO)

**`auth_rls_initplan` (28 WARN) — HIGH PRIORITY**

28 RLS policies use `auth.uid()` as a scalar call instead of `(SELECT auth.uid())`. This forces re-evaluation on every row scan rather than once per query — a significant performance overhead on large tables.

Affected tables: `user_profiles`, `onboarding_responses`, `workout_plans` (×5), `workout_sessions` (×2), `session_exercises` (×2), `ai_nutrition_plans` (×4), `user_meals`, `daily_nutrition_goals`, `workout_logs`, `user_workout_schedules`, `body_measurements` (×4), `exercises`, `strength_progress`, `food_database` (×3), `workout_set_logs`, `auth_backup_codes`, `progress_photos`

**Fix:** Replace `auth.uid()` → `(SELECT auth.uid())` in all 28 RLS policy definitions.  
**Milestone:** M27.5 — Ref: [Supabase Docs](https://supabase.com/docs/guides/database/database-linter?lint=0013_rls_enabled_no_policy)

---

**`multiple_permissive_policies` (14 WARN)**

Tables with redundant overlapping policies for the same role+action (query planner evaluates ALL of them):

| Table | Action | Roles affected |
|---|---|---|
| `workout_plans` | SELECT/INSERT/UPDATE/DELETE | authenticated, anon, authenticator, dashboard_user, supabase_privileged_role |
| `workout_sessions` | SELECT | authenticated |
| `session_exercises` | SELECT | authenticated |
| `exercises` | SELECT | authenticated |
| `food_database` | INSERT, UPDATE | authenticated |

**Fix:** Merge overlapping policies into a single policy per action per role.  
**Milestone:** M27.5

---

**`unindexed_foreign_keys` (13 INFO)**

FK relationships without a covering index — causes full-table scans on joins:

| Table | Missing index on FK |
|---|---|
| `auth_backup_codes` | `user_id` |
| `food_database` | `contributed_by` |
| `strength_progress` | `exercise_id`, `session_id` |
| `user_meals` | `food_id` |
| `user_workout_schedules` | `plan_id`, `user_id` |
| `workout_logs` | `plan_id`, `session_id`, `user_id` |
| `workout_plans` | `creator_id` |
| `workout_set_logs` | `exercise_id`, `session_exercise_id` |

**Fix:** Migration adding `CREATE INDEX` for each FK column.  
**Milestone:** M27.1

---

**`unused_index` (17 INFO)**

17 indexes that have never been scanned since creation — they consume write overhead with no read benefit:

`user_profiles`: `idx_user_profiles_email`, `idx_user_profiles_onboarding`  
`workout_plans`: `idx_workout_plans_user_id`, `idx_workout_plans_active`, `idx_workout_plans_goal`, `idx_workout_plans_frequency`  
`exercises`: `idx_exercises_equipment`, `idx_exercises_difficulty`, `idx_exercises_category_id`  
`session_exercises`: `idx_session_exercises_exercise_id`  
`body_measurements`: `idx_body_measurements_date`  
`workout_categories`: `idx_workout_categories_name`  
`workout_sessions`: `idx_workout_sessions_category_id`, `idx_workout_sessions_day`  
`food_database`: `idx_food_database_brand`  
`user_meals`: `idx_user_meals_meal_type`  
`daily_nutrition_goals`: `idx_daily_nutrition_goals_date`

**Fix:** Evaluate if any will be used by queries in M27; drop the rest.  
**Milestone:** M27.1

### 4d. Postgres logs (last 24h)

**Status: CLEAN — 0 errors, 0 warnings, 0 slow queries.**

Log entries were all `LOG` level:
- Normal connection received events
- Normal checkpoint complete events
- 1× "could not receive data from client: Connection reset by peer" — normal network teardown

---

## 5. Runtime Measurements (Deferred — fill in with device)

Run these commands to gather runtime metrics:

```bash
# Cold start trace
flutter run --trace-startup --profile --dart-define-from-file=env.json

# APK size (after fixing R8 first)
flutter build apk --release --analyze-size --dart-define-from-file=env.json
flutter build apk --release --split-per-abi --dart-define-from-file=env.json
```

Then open DevTools (`flutter pub global run devtools`) and use:
- **Performance tab** → record on exercise library scroll, dashboard load
- **Memory tab** → snapshot at idle, snapshot after 5-min navigation loop

---

## 6. Priority Fix Queue (for milestone planning)

Issues found in this audit, ordered by impact × effort:

| Priority | Issue | Impact | Milestone |
|---|---|---|---|
| 🔴 BLOCKER | R8 build failure (ProGuard rules) | Release APK impossible | M31.1 |
| 🔴 HIGH | 28 `auth_rls_initplan` WARN — every query re-evaluates auth | DB perf on all tables | M27.5 |
| 🔴 HIGH | 4 unused packages in pubspec (camera, youtube, universal_html, before_after) | APK size + build time | M31.2 |
| 🟠 MEDIUM | 14 multiple permissive policies — redundant policy evaluation | DB query overhead | M27.5 |
| 🟠 MEDIUM | 13 missing FK indexes — full-table scans on joins | DB query perf | M27.1 |
| 🟠 MEDIUM | 10 functions with mutable search_path — security risk | Security | M27.5 |
| 🟠 MEDIUM | 2 permissive food_database policies — any user can modify any food | Security | M27.5 |
| 🟡 LOW | ~22 `withOpacity` → `.withValues()` deprecations | Deprecation warning | M22 fix pass |
| 🟡 LOW | 8 `RadioGroup` deprecation warnings | Deprecation warning | M22 fix pass |
| 🟡 LOW | 11 `BuildContext` across async gaps | Potential crash after widget disposed | M22 fix pass |
| 🟡 LOW | 10 unused fields/elements/variables/imports | Dead code | M22 fix pass |
| 🟡 LOW | 17 unused DB indexes | Write overhead | M27.1 |
| 🟡 LOW | 2 raw `print()` in production code | Log leakage in release | M22 fix pass |
| 🟡 LOW | 1 discontinued `js` package | Future breakage | M31.2 |
| 🟡 LOW | `fluttertoast` deprecated Android APIs | Android build warnings | M31.2 |
| 🟡 LOW | PAAM folder errors (7) — separate project, no app impact | Noise in flutter analyze | Optional |

---

## 7. Open Questions

- [ ] **`sizer` major upgrade (2.0.15 → 3.1.3):** API changed — could break ALL `.h/.w/.sp` calls app-wide. Evaluate changelog before upgrading.
- [ ] **PAAM subfolder in project root:** `flutter analyze` recurses into it, showing 7 false errors. Options: (a) add `exclude:` entry to `analysis_options.yaml`, (b) move PAAM out of the root.
- [ ] **Leaked password protection:** Enable in Supabase Auth settings (Dashboard → Auth → Password Strength → Enable).
- [ ] **`flutter_lints` major (5→6):** May introduce new required lint fixes. Upgrade together with the next lint-cleanup pass.

---

## M25 — Memory Management & Leak Audit (2026-04-19)

### 25.1 — Controller Disposal Audit

All `AnimationController`, `ScrollController`, `PageController`, and class-field `TextEditingController` instances were verified to have correct `dispose()` calls in their owning `State.dispose()`. No issues found in those categories.

**Confirmed leaks (fixed):**

| File | Issue | Fix |
|---|---|---|
| `user_profile_management/widgets/account_management_section_widget.dart:30–32` | 3 inline `TextEditingController`s in `_handleChangePassword()` created before `await showDialog()` — never disposed | Added 3 `.dispose()` calls after the awaited dialog |
| `auth/totp_challenge_screen.dart:56` | `backupController` in `void _showBackupCodeDialog()` — `showDialog()` not awaited, no dispose | Added `.then((_) => backupController.dispose())` |
| `nutrition_planning_screen/widgets/simple_meal_card.dart:246` | `controller` in `void _showEditQuantityDialog()` — `showDialog()` not awaited, no dispose | Added `.then((_) => controller.dispose())` |
| `strength_progress/exercise_details_screen.dart:105–106` | `weightController` + `repsController` created before `await showDialog()` in `_addPR()` — never disposed | Added 2 `.dispose()` calls after the awaited dialog |

**Verified OK (no changes needed):**
- All `AnimationController`s, `ScrollController`s, `PageController`s — properly disposed
- `GrammageInputDialog`, `QuantityInputDialog`, `RegisterFormWidget`, both `BodyMeasurementsCard` variants, `PhotoProgressWidget` — correct `dispose()`
- `security_settings_screen.dart:163` — inline `passwordController.dispose()` at line 189 ✅
- `water_tracking_card.dart:49` — inline `controller.dispose()` at line 87 ✅
- `ingredients_review_step.dart:52` — `.then((_) => controller.dispose())` pattern ✅

### 25.2 — Stream & Subscription Cleanup

All clean — no action needed:
- `authentication_onboarding_flow.dart` — `StreamSubscription<AuthState>?` `cancel()`ed in `dispose()` ✅
- `main_dashboard.dart` — `StreamSubscription<List<ConnectivityResult>>?` `cancel()`ed in `dispose()` ✅
- No Supabase realtime channels found anywhere in the codebase
- `add_food_modal_widget.dart` debounce `Timer?` — `cancel()`ed in `dispose()` ✅

### 25.3 — DevTools Memory Profiling

**Deferred** — requires physical/emulated device. Same deferral status as M22.3 and M23.1.

### 25.4 — Compute Isolate Evaluation

All Gemini response payloads measured below the 50KB threshold defined for compute migration:
- `gemini_ai_service.dart` workout plan (`maxTokens: 4096`) → ~15KB
- `smart_recipe_service.dart` recipe generation (`maxTokens: 8192`) → ~25KB
- `add_food_modal_widget.dart` food search merge (60–180 items × ~500B) → ~30KB

No `compute()` migration warranted. All JSON parsing can remain on the main isolate.

**`flutter analyze lib/`:** **0 issues** after all fixes.
