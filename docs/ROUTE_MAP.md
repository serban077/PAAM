# Route Map

> Read this when: adding a new screen, modifying navigation, debugging routing issues.

---

## All Named Routes

Defined in `lib/routes/app_routes.dart`. ALWAYS use `AppRoutes` constants — never raw strings.

| Constant | Path | Screen | Notes |
|---|---|---|---|
| `AppRoutes.authenticationOnboardingFlow` | `/authentication-onboarding-flow` | AuthenticationOnboardingFlow | **Initial route** — real entry point |
| `AppRoutes.loginScreen` | `/login` | LoginScreen | — |
| `AppRoutes.signupScreen` | `/signup` | SignupScreen | — |
| `AppRoutes.onboardingSurvey` | `/onboarding-survey` | OnboardingSurveyScreen | — |
| `AppRoutes.mainDashboard` | `/main-dashboard` | MainDashboard | Bottom nav shell |
| `AppRoutes.mainDashboardInitial` | `/main-dashboard-initial` | MainDashboardInitialPage | Home tab content |
| `AppRoutes.aiWorkoutGenerator` | `/ai-workout-generator` | AIWorkoutGenerator | — |
| `AppRoutes.aiNutritionPlanner` | `/ai-nutrition-planner` | AINutritionPlanner | — |
| `AppRoutes.exerciseLibrary` | `/exercise-library` | ExerciseLibrary | — |
| `AppRoutes.progressTracking` | `/progress-tracking` | ProgressTrackingScreen | — |
| `AppRoutes.strengthProgress` | `/strength-progress` | StrengthProgressScreen | — |
| `AppRoutes.exerciseDetails` | `/exercise-details` | ExerciseDetailsScreen | Uses `onGenerateRoute` — arg: `sessionId` |
| `AppRoutes.nutritionPlanning` | `/nutrition-planning` | NutritionPlanningScreen | — |
| `AppRoutes.workoutDetail` | `/workout-detail` | WorkoutDetailScreen | — |
| `AppRoutes.userProfile` | `/user-profile` | UserProfileManagement | — |

---

## Bottom Navigation Tab Order

`MainDashboard` shell maps tab index to routes in exact order:

| Index | Route | Tab label |
|---|---|---|
| 0 | `/main-dashboard` | Home ⚠ currently "Acasă" — M9 fix |
| 1 | `/exercise-library` | Workouts ⚠ currently "Antrenamente" |
| 2 | `/nutrition-planning` | Nutrition ⚠ currently "Nutriție" |
| 3 | `/progress-tracking` | Progress ⚠ currently "Progres" |
| 4 | `/user-profile` | Profile ⚠ currently "Profil" |

---

## Navigation Patterns

```dart
// Simple push
Navigator.pushNamed(context, AppRoutes.aiWorkoutGenerator);

// Push with arguments — only for routes using onGenerateRoute
Navigator.pushNamed(context, AppRoutes.exerciseDetails, arguments: {'sessionId': id});

// Replace (post-login, post-onboarding)
Navigator.pushReplacementNamed(context, AppRoutes.mainDashboard);
```

---

## Adding a New Route

1. Add constant to `AppRoutes` class: `static const String myScreen = '/my-screen';`
2. If **no arguments**: add to the static `routes` map
3. If **has arguments**: add a case in `onGenerateRoute`, not the static map
4. Import the screen file at the top of `app_routes.dart`
5. Add the screen to the Implemented Screens table in `lib/presentation/CLAUDE.md`

---

## Authentication Routing Logic

`AuthenticationOnboardingFlow` is the initial route and acts as a router:

```
App starts
  └─► AuthenticationOnboardingFlow
        ├─► Supabase auth listener fires
        ├─► User logged in?
        │     ├─► Yes → query onboarding_responses table
        │     │         ├─► Row exists → pushReplacement to /main-dashboard
        │     │         └─► No row → show OnboardingSurveyWidget
        │     └─► No → show login/signup form
        └─► Loading → CircularProgressIndicator
```
