import 'package:flutter/material.dart';
import '../presentation/main_dashboard/main_dashboard.dart';
import '../presentation/main_dashboard/main_dashboard_initial_page.dart';
import '../presentation/exercise_library/exercise_library.dart';
import '../presentation/user_profile_management/user_profile_management.dart';
import '../presentation/progress_tracking_screen/progress_tracking_screen.dart';
import '../presentation/nutrition_planning_screen/nutrition_planning_screen.dart';
import '../presentation/workout_detail_screen/workout_detail_screen.dart';
import '../presentation/auth/login_screen.dart';
import '../presentation/auth/signup_screen.dart';
import '../presentation/auth/onboarding_survey_screen.dart';
import '../presentation/authentication_onboarding_flow/authentication_onboarding_flow.dart';
import '../presentation/ai_workout_generator/ai_workout_generator.dart';
import '../presentation/ai_nutrition_planner/ai_nutrition_planner.dart';
import '../presentation/strength_progress/strength_progress_screen.dart';
import '../presentation/strength_progress/exercise_details_screen.dart';

class AppRoutes {
  static const String mainDashboard = '/main-dashboard';
  static const String mainDashboardInitial = '/main-dashboard-initial';
  static const String exerciseLibrary = '/exercise-library';
  static const String userProfile = '/user-profile';
  static const String progressTracking = '/progress-tracking';
  static const String nutritionPlanning = '/nutrition-planning';
  static const String workoutDetail = '/workout-detail';
  static const String loginScreen = '/login';
  static const String signupScreen = '/signup';
  static const String onboardingSurvey = '/onboarding-survey';
  static const String individualWorkoutPlans = '/individual-workout-plans';
  static const String manualFoodAddition = '/manual-food-addition';
  static const String authenticationOnboardingFlow =
      '/authentication-onboarding-flow';
  static const String aiWorkoutGenerator = '/ai-workout-generator';
  static const String aiNutritionPlanner = '/ai-nutrition-planner';
  static const String strengthProgress = '/strength-progress';
  static const String exerciseDetails = '/exercise-details';

  static Map<String, WidgetBuilder> get routes => {
    mainDashboard: (context) => const MainDashboard(),
    mainDashboardInitial: (context) => const MainDashboardInitialPage(),
    exerciseLibrary: (context) => const ExerciseLibrary(),
    userProfile: (context) => const UserProfileManagement(),
    progressTracking: (context) => const ProgressTrackingScreen(),
    nutritionPlanning: (context) => const NutritionPlanningScreen(),
    workoutDetail: (context) => const WorkoutDetailScreen(),
    loginScreen: (context) => const LoginScreen(),
    signupScreen: (context) => const SignupScreen(),
    onboardingSurvey: (context) => const OnboardingSurveyScreen(),
    authenticationOnboardingFlow: (context) =>
    const AuthenticationOnboardingFlow(),
    aiWorkoutGenerator: (context) => const AIWorkoutGenerator(),
    aiNutritionPlanner: (context) => const AINutritionPlanner(),
    strengthProgress: (context) => const StrengthProgressScreen(),
  };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    if (settings.name == exerciseDetails) {
      final args = settings.arguments as Map<String, dynamic>?;
      return MaterialPageRoute(
        builder: (context) => ExerciseDetailsScreen(
          sessionId: args?['sessionId'] ?? '',
        ),
      );
    }
    return null;
  }
}
