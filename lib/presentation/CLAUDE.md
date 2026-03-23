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

## Authentication Flow (AuthenticationOnboardingFlow)

This screen is the real entry point (`initialRoute`). State machine:
1. Supabase auth listener fires
2. User logged in → query `onboarding_responses` table
3. Row found → `pushReplacementNamed` to `/main-dashboard`
4. No row → show `OnboardingSurveyWidget`
5. No user → show login/signup form

Read `authentication_onboarding_flow.dart` before modifying any auth screen.

---

## Bottom Navigation

Shell: `MainDashboard` uses a nested `Navigator` + `CustomBottomBar`.
Tab order (index 0→4): `main-dashboard` / `exercise-library` / `nutrition-planning` / `progress-tracking` / `user-profile`

- Tab labels must match this order exactly in `custom_bottom_bar.dart`
- ⚠ Labels are currently in Romanian — M9 task replaces them with English

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
