# lib/presentation/ — UI & Screen Conventions

Read this file when working on any screen, widget, or navigation change.

---

## Screen Structure

Every screen lives in its own folder with an optional `widgets/` subfolder:

```
lib/presentation/
└── my_new_screen/
    ├── my_new_screen.dart        # Main screen file
    └── widgets/
        └── some_card_widget.dart # Screen-specific widget
```

App-wide reusable components belong in `lib/widgets/`, not here.

---

## Screen Template

```dart
class MyNewScreen extends StatefulWidget {
  const MyNewScreen({super.key});

  @override
  State<MyNewScreen> createState() => _MyNewScreenState();
}

class _MyNewScreenState extends State<MyNewScreen> {
  bool _isLoading = false;
  final _myService = MyService(); // instantiate service here, not injected

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Screen Title'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() { ... }
}
```

After creating a screen, add its route to `lib/routes/app_routes.dart`.

---

## Navigation

```dart
Navigator.pushNamed(context, AppRoutes.aiWorkoutGenerator);

// With arguments — only for routes registered in onGenerateRoute
Navigator.pushNamed(context, AppRoutes.exerciseDetails, arguments: {'sessionId': id});

// Replace stack (after login, after onboarding)
Navigator.pushReplacementNamed(context, AppRoutes.mainDashboard);
```

NEVER use raw string paths — always `AppRoutes.<constant>`.

---

## Authentication Flow

`LoginScreen` (`/login`) is the real `initialRoute`. On `initState` it calls `_checkExistingSession()`:
1. Reads `SupabaseService.instance.client.auth.currentSession` (synchronous, no network)
2. No session → show login form
3. Session exists + biometric enabled → `pushNamed(AppRoutes.appLock).then((_) => pushReplacementNamed(mainDashboard))`
4. Session exists + no biometric → `pushReplacementNamed(mainDashboard)` directly

`AuthenticationOnboardingFlow` is still used as a secondary screen (handles MFA challenge gate, email verification gate, onboarding survey). It has its own `onAuthStateChange` listener.

**AppLockScreen pattern** (M20):
- `SingleTickerProviderStateMixin` — `AnimationController` drives a scale pulse (1.0→1.18, 1s repeat-reverse) on the icon ring while authenticating
- Biometric triggered via `addPostFrameCallback` (needs screen rendered first)
- On success → `Navigator.pushReplacement(PageRouteBuilder(transitionDuration: 450ms, FadeTransition))` — never `pushReplacementNamed` (that uses default slide)
- Route itself uses `PageRouteBuilder` with 300ms fade (not `fullscreenDialog` which creates slide-from-bottom)
- "Use email & password instead" calls `signOut()` then `pushNamedAndRemoveUntil` to `loginScreen`

Read `app_lock_screen.dart` and `authentication_onboarding_flow.dart` before modifying any auth screen.

---

## Bottom Navigation

Shell: `MainDashboard` uses a nested `Navigator` + `CustomBottomBar`.
Tab order (index 0→4): `main-dashboard` / `exercise-library` / `nutrition-planning` / `progress-tracking` / `user-profile`

- Tab labels must match this order exactly in `custom_bottom_bar.dart`
- Labels are now English: Home / Workouts / Nutrition / Progress / Profile

---

## Reusable Widgets

| Widget | Use for |
|---|---|
| `CustomAppBar` | All screen app bars |
| `CustomBottomBar` | Bottom navigation shell only |
| `CustomIconWidget` | ALL icons — never use emoji or raw `Icon()` |
| `CustomImageWidget` | ALL network images — handles caching automatically |
| `CustomErrorWidget` | Error boundary (already wired in `main.dart`) |

---

## Design System

Style: **Contemporary Wellness Minimalism — Energetic Neutrals**
All tokens are in `lib/theme/app_theme.dart`. NEVER use raw hex in screens.

| Color | Hex | Usage |
|---|---|---|
| `primaryLight` | `#2E7D32` | Brand color, primary buttons (forest green) |
| `secondaryLight` | `#1565C0` | Links, interactive elements (professional blue) |
| `accentLight` | `#FF6F00` | CTAs, progress highlights (energetic orange) |
| `errorLight` | `#D32F2F` | Errors, destructive actions |
| `backgroundLight` | `#FAFAFA` | Screen backgrounds |
| `surfaceLight` | `#FFFFFF` | Cards, surfaces |

Access in code: `Theme.of(context).colorScheme.primary`
Dark mode equivalents are in the same file — always implement both.

**Typography:** Google Fonts only. No `assets/fonts/` entries in `pubspec.yaml`.

---

## Sizing & Spacing

NEVER use fixed px values. Use Sizer:
```dart
width: 80.w     // 80% of screen width
height: 20.h    // 20% of screen height
fontSize: 14.sp // responsive font size
```

---

## Implemented Screens

| Screen | Folder | Status |
|---|---|---|
| Auth flow | `authentication_onboarding_flow/` | ✅ |
| Login / Signup / Onboarding survey | `auth/` | ✅ |
| Main Dashboard | `main_dashboard/` | ✅ |
| AI Workout Generator | `ai_workout_generator/` | ✅ |
| AI Nutrition Planner | `ai_nutrition_planner/` | ✅ |
| AI Plan (combined view) | `ai_plan/` | ✅ |
| Exercise Library | `exercise_library/` | ✅ |
| Nutrition Planning | `nutrition_planning_screen/` | ✅ |
| Progress Tracking | `progress_tracking_screen/` | ✅ |
| Strength Progress | `strength_progress/` | ✅ |
| Workout Detail | `workout_detail_screen/` | ✅ |
| User Profile | `user_profile_management/` | ✅ |
| Barcode Scanner | `nutrition_planning_screen/widgets/barcode_scanner_page.dart` | ✅ |
| Product Found Screen | `nutrition_planning_screen/widgets/product_found_screen.dart` | ✅ |
| Product Not Found Screen | `nutrition_planning_screen/widgets/product_not_found_screen.dart` | ✅ |
| User Food Submission (3-step wizard) | `user_food_submission_screen/user_food_submission_screen.dart` | ✅ |
| My Contributions | `user_food_submission_screen/my_contributions_screen.dart` | ✅ |
| Exercise Detail Sheet | `exercise_library/widgets/exercise_detail_sheet.dart` | ✅ |
| Active Workout Session | `active_workout_session/active_workout_session.dart` | ✅ |
| Workout Summary | `active_workout_session/widgets/workout_summary_screen.dart` | ✅ |
| Photo Recipe (4-step wizard) | `photo_recipe_screen/` | ✅ |
| Email Verification | `auth/email_verification_screen.dart` | ✅ |
| Forgot Password | `auth/forgot_password_screen.dart` | ✅ |
| Update Password | `auth/update_password_screen.dart` | ✅ |
| App Lock (biometric) | `auth/app_lock_screen.dart` | ✅ |
| TOTP Challenge | `auth/totp_challenge_screen.dart` | ✅ |
| Security Settings | `security_settings_screen/security_settings_screen.dart` | ✅ |
| Two-Factor Setup (3-step wizard) | `security_settings_screen/two_factor_setup_screen.dart` | ✅ |

---

## Exercise Library — Card & Category Chip Pattern

**Horizontal list card** (`ExerciseCardWidget`):
```dart
// Structure: image | strip | info | chevron
Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
  ClipRRect(borderRadius: only left sides, child: SizedBox(width: 24.w, height: 22.w, child: CustomImageWidget(...))),
  Container(width: 3, height: 22.w, color: diffColor),  // difficulty accent strip
  Expanded(child: Padding(...)),                          // name + muscles + _InfoChip row
  Padding(right: 3.w, child: CustomIconWidget('chevron_right')),
])
```
Difficulty colors: Beginner → `tertiary`, Intermediate → `Color(0xFFFF6F00)`, Advanced → `error`.

**Horizontal category chip bar**:
- State: `String _selectedCategory = 'All'`
- `_onCategoryTap(category)` updates `_selectedCategory` and calls `_applyFilters()`
- Category filter is **independent** from `_activeFilters['bodyPart']` — they stack
- Use `AnimatedContainer(duration: 200ms, curve: Curves.easeOut)` for chip fill animation
- `HapticFeedback.selectionClick()` on tap

---

## Patterns Added Recently

**Gradient Hero + Floating Card** (auth screens + dashboard):
```dart
// Standard layout used by login, signup, onboarding, and home page
Scaffold(
  body: Stack(children: [
    Positioned.fill(child: Container(decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: isDark
          ? [AppTheme.backgroundDark, AppTheme.primaryVariantDark]
          : [AppTheme.primaryVariantLight, AppTheme.primaryLight],
      ),
    ))),
    SafeArea(child: Column(children: [
      _buildHeader(),         // hero/greeting inside gradient
      Expanded(child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: isDark ? Border(top: BorderSide(
            color: AppTheme.primaryDark.withValues(alpha: 0.25), width: 1,
          )) : null,
          boxShadow: [BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.35) : AppTheme.shadowLight,
            blurRadius: 24, offset: Offset(0, -6),
          )],
        ),
        child: /* scrollable content */,
      )),
    ])),
  ]),
)
```
When adding new screens, follow this pattern for visual consistency.
CTA buttons use `colorScheme.tertiary` (orange) with `colorScheme.onTertiary` foreground.

**Bottom-sheet detail panel** (`ExerciseDetailSheet`):
```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  builder: (context) => ExerciseDetailSheet(exercise: data),
);
```
Uses `DraggableScrollableSheet` inside. `YoutubePlayer` shown only when `videoId != null`.

**Reactive theme toggle** (profile screen):
```dart
ValueListenableBuilder<ThemeMode>(
  valueListenable: ThemeService.themeNotifier,
  builder: (context, themeMode, child) => SwitchListTile(
    value: themeMode == ThemeMode.dark,
    onChanged: (isDark) => ThemeService.setDarkMode(isDark),
    ...
  ),
)
```
Do NOT use `setState` to update the toggle — `ValueListenableBuilder` handles it.

**Meal type keys** — Romanian internal keys are kept in DB; display names are English:
| DB key | Display |
|---|---|
| `mic_dejun` | Breakfast |
| `pranz` | Lunch |
| `cina` | Dinner |
| `gustare_dimineata` | Snack |

**Meal type picker bottom sheet** (M14.2 — `ai_meal_plan_section.dart`):
When user action needs a meal type choice, use `showModalBottomSheet<String>` returning the DB key:
```dart
Future<String?> _showMealTypePicker(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(4.w, 1.5.h, 4.w, 4.h),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // drag handle + title + Wrap of 4 ActionChips + Cancel TextButton
      ]),
    ),
  );
}
// Usage: final mealType = await _showMealTypePicker(context);
// if (mealType == null || !mounted) return;  // abort on cancel
```

**Barcode scan flow** (M15 + M17):
- Found → `Navigator.pushReplacement` to `ProductFoundScreen` (scanner replaced in stack)
- Not found → `Navigator.pushReplacement` to `ProductNotFoundScreen(barcode: ...)` (M17)
- `ProductFoundScreen` calls `onFoodAdded()` callback before `Navigator.pop()` to trigger parent refresh
- `MobileScannerController.stop()` called immediately on first detection — camera never scans in a loop

**User food contribution flow** (M17):
`ProductNotFoundScreen` → "Add This Product" → `UserFoodSubmissionScreen` (3 steps: Info → Label Photo + OCR → Review) → on submit → `ProductFoundScreen` with newly inserted row.
`GeminiNutritionLabelService.extractNutritionLabel(Uint8List, {String? imagePath})`: ML Kit OCR → Gemini 2.5 Flash text parsing (falls back to Gemini Vision if ML Kit fails). Returns null on failure → user enters macros manually.
`detailed_macros` JSONB (22-field schema) stored in `food_database`, displayed as `ExpansionTile` in `ProductFoundScreen` (hidden when null).

**Active workout session flow** (M10):
`Dashboard "Start Workout"` → `ActiveWorkoutSession(sessionId)` → per-set logging with `SetRowWidget` + `RestTimerWidget` overlay → `_finishWorkout()` calls `WorkoutService.saveCompletedWorkout()` → `WorkoutSummaryScreen`.
- `ExerciseTrackerWidget` renders the current exercise card with set rows (reuses existing `VideoPlayerModal` and `RestTimerWidget`).
- `SetRowWidget`: weight (nullable, "BW" hint for bodyweight) + reps fields; checkmark marks set done.
- `WorkoutSummaryScreen`: duration / volume / sets stats + new PRs amber card + exercise breakdown `ExpansionTile` list.
- PRs auto-detected by `WorkoutService._autoDetectPRs()` — inserts into `strength_progress` if new weight > existing max.
- DB: `workout_set_logs` table stores one row per completed set (FK → `workout_logs`); `workout_logs.total_volume_kg` added M10.

**Food correction flow** (M17 OCR upgrade):
`ProductFoundScreen` shows ✏️ icon next to macro chips → navigates to `UserFoodSubmissionScreen(existingFood: food)`.
Edit mode: starts at Step 2, pre-fills all fields from existing row, "Update Product" submits `NutritionService.updateFoodNutrition()` (UPDATE, not INSERT).
Any authenticated user can correct any food (RLS policy `authenticated_can_update_food`).

**Exercise animation in ActiveWorkoutSession** (2026-03-28 hotfix):
`_ExerciseAnimationWidget` (StatefulWidget in `exercise_tracker_widget.dart`) crossfades between 2-frame JPGs from the free-exercise-db GitHub CDN every 1.1 s using `AnimatedSwitcher` + `CachedNetworkImage`. Frame URLs resolved by `lib/utils/exercise_gif_utils.dart`.
- **NEVER** use `exercise['image']` — the `exercises` Supabase table has NO `image` column; always resolves to null, which when passed to `CustomImageWidget` as `''` triggers Asset not found crash.
- **NEVER** hotlink MuscleWiki GIFs directly — their media moved behind `api.musclewiki.com` (paid API, `X-API-Key` required). Old static paths return 404.
- When navigating to any argument-based route (e.g., `/active-workout`) from inside a `MainDashboard` tab, **always** use `Navigator.of(context, rootNavigator: true).pushNamed(...)` — the inner tab navigator has no `onGenerateRoute` and will throw.

**Photo-to-Recipe wizard flow** (M18):
`NutritionPlanningScreen` CTA → `PhotoRecipeScreen` (4-step PageView wizard):
1. `CaptureStep` — camera/gallery via image_picker → `Uint8List` bytes
2. `IngredientsReviewStep` — editable ingredient chips (remove/edit quantity) + shimmer loading
3. `RecipesStep` — recipe cards with macro chips → tap for `RecipeDetailSheet` bottom sheet
4. `LogRecipeStep` — meal type picker + serving count → `submitUserFood()` + `logMeal()`

Recipe logging creates a temp `food_database` row (`serving_size=1`, `serving_quantity=1`) matching the AI meal pattern.
Navigation uses `rootNavigator: true` from NutritionPlanningScreen (nested navigator context).

**Offline connectivity banner** (M19):
`MainDashboard` listens to `Connectivity().onConnectivityChanged` (returns `List<ConnectivityResult>` in v6).
Layout uses `Stack(fit: StackFit.expand, ...)` — **critical**: `StackFit.expand` gives bounded constraints to `IndexedStack` (matching Scaffold.body behavior). `StackFit.loose` would pass unbounded height, crashing all tab screens. The `Positioned` banner is unaffected by `fit`.
```dart
body: Stack(
  fit: StackFit.expand,  // REQUIRED — do not remove
  children: [
    IndexedStack(index: currentIndex, children: _tabs),
    if (_isOffline) Positioned(top: 0, left: 0, right: 0, child: /* red banner */),
  ],
)
```

**Controller disposal pattern for inline dialogs** (M19):
```dart
// Non-async callers: chain .then() on showDialog
final controller = TextEditingController();
showDialog(...).then((_) => controller.dispose());

// Async callers: explicit dispose after await
final result = await showDialog<int>(...);
controller.dispose();
```

**AppCacheService in screens** (M19):
Check cache before network; write cache after network; invalidate before force-refresh:
```dart
final cached = AppCacheService.instance.getExerciseLibrary();
if (cached != null) { setState(() => _exercises = cached); return; }
// ... fetch ...
AppCacheService.instance.setExerciseLibrary(exercises);
```

---

## Localization — M9 Complete (2026-03-25)

All user-visible Romanian strings have been translated to English across all 50 presentation files.

### Intentionally remaining Romanian (do NOT translate):
- `lib/services/gemini_ai_service.dart` — AI prompt text instructs Gemini to generate Romanian content (meal plans, coaching tips). Changing these would break AI output.
- `ai_meal_plan_section.dart` — `mealTypeMap` removed (M14.2); meal type is now selected via bottom sheet so no string matching is needed.
- `exercise_detail_sheet.dart` switch cases `'începător'`/`'intermediar'`/`'avansat'` — backward-compat fallbacks alongside the English cases.

### Critical sync: exercise data ↔ filter chips
`verified_exercises_data.dart` `bodyPart` values **must** match `filter_bottom_sheet_widget.dart` filter chip strings exactly (uses `.contains()` for filtering). Both are now English:
`Chest / Back / Legs / Shoulders / Arms / Abs / Cardio`

### Shimmer skeletons (M9)
Use `shimmer` package for data loads >300ms. Pattern:
```dart
Shimmer.fromColors(
  baseColor: Colors.grey.shade300,
  highlightColor: Colors.grey.shade100,
  child: _buildSkeletonCard(),
)
```
Shimmer is shown while `_isLoading == true`; replaced with real content on data arrival.
