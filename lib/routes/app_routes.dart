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
import '../presentation/auth/email_verification_screen.dart';
import '../presentation/auth/forgot_password_screen.dart';
import '../presentation/auth/update_password_screen.dart';
import '../presentation/auth/app_lock_screen.dart';
import '../presentation/auth/totp_challenge_screen.dart';
import '../presentation/authentication_onboarding_flow/authentication_onboarding_flow.dart';
import '../presentation/ai_workout_generator/ai_workout_generator.dart';
import '../presentation/ai_nutrition_planner/ai_nutrition_planner.dart';
import '../presentation/strength_progress/strength_progress_screen.dart';
import '../presentation/strength_progress/exercise_details_screen.dart';
import '../presentation/nutrition_planning_screen/widgets/product_not_found_screen.dart';
import '../presentation/user_food_submission_screen/user_food_submission_screen.dart';
import '../presentation/user_food_submission_screen/my_contributions_screen.dart';
import '../presentation/active_workout_session/active_workout_session.dart';
import '../presentation/photo_recipe_screen/photo_recipe_screen.dart';
import '../presentation/security_settings_screen/security_settings_screen.dart';
import '../presentation/security_settings_screen/two_factor_setup_screen.dart';

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
  static const String productNotFound = '/product-not-found';
  static const String userFoodSubmission = '/user-food-submission';
  static const String myFoodContributions = '/my-food-contributions';
  static const String activeWorkout = '/active-workout';
  static const String photoRecipe = '/photo-recipe';
  static const String emailVerification = '/email-verification';
  static const String forgotPassword = '/forgot-password';
  static const String updatePassword = '/update-password';
  static const String appLock = '/app-lock';
  static const String totpChallenge = '/totp-challenge';
  static const String twoFactorSetup = '/two-factor-setup';
  static const String securitySettings = '/security-settings';

  static Map<String, WidgetBuilder> get routes => {
    mainDashboard: (context) => const MainDashboard(),
    mainDashboardInitial: (context) => const MainDashboardInitialPage(),
    exerciseLibrary: (context) => const ExerciseLibrary(),
    userProfile: (context) => const UserProfileManagement(),
    progressTracking: (context) => const ProgressTrackingScreen(),
    nutritionPlanning: (context) => const NutritionPlanningScreen(),
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
    if (settings.name == workoutDetail) {
      return MaterialPageRoute(
        builder: (context) => const WorkoutDetailScreen(),
        settings: settings,
      );
    }
    if (settings.name == exerciseDetails) {
      final args = settings.arguments as Map<String, dynamic>?;
      return MaterialPageRoute(
        builder: (context) => ExerciseDetailsScreen(
          sessionId: args?['sessionId'] ?? '',
        ),
      );
    }
    if (settings.name == productNotFound) {
      final args = settings.arguments as Map<String, dynamic>?;
      return MaterialPageRoute(
        builder: (context) =>
            ProductNotFoundScreen(barcode: args?['barcode'] as String? ?? ''),
      );
    }
    if (settings.name == userFoodSubmission) {
      final args = settings.arguments as Map<String, dynamic>?;
      return MaterialPageRoute(
        builder: (context) => UserFoodSubmissionScreen(
          barcode: args?['barcode'] as String? ?? '',
          productName: args?['productName'] as String? ?? '',
        ),
      );
    }
    if (settings.name == myFoodContributions) {
      return MaterialPageRoute(
        builder: (context) => const MyContributionsScreen(),
      );
    }
    if (settings.name == activeWorkout) {
      final args = settings.arguments as Map<String, dynamic>?;
      return MaterialPageRoute(
        builder: (context) => ActiveWorkoutSession(
          sessionId: args?['sessionId'] as String? ?? '',
        ),
      );
    }
    if (settings.name == photoRecipe) {
      return MaterialPageRoute(
        builder: (context) => const PhotoRecipeScreen(),
      );
    }
    if (settings.name == emailVerification) {
      final args = settings.arguments as Map<String, dynamic>?;
      return MaterialPageRoute(
        builder: (context) => EmailVerificationScreen(
          email: args?['email'] as String? ?? '',
        ),
      );
    }
    if (settings.name == forgotPassword) {
      return MaterialPageRoute(
        builder: (context) => const ForgotPasswordScreen(),
      );
    }
    if (settings.name == updatePassword) {
      return MaterialPageRoute(
        builder: (context) => const UpdatePasswordScreen(),
      );
    }
    if (settings.name == appLock) {
      return PageRouteBuilder(
        settings: settings,
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => const AppLockScreen(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
      );
    }
    if (settings.name == totpChallenge) {
      final args = settings.arguments as Map<String, dynamic>?;
      return MaterialPageRoute(
        builder: (context) => TotpChallengeScreen(
          factorId: args?['factorId'] as String? ?? '',
        ),
      );
    }
    if (settings.name == twoFactorSetup) {
      return MaterialPageRoute(
        builder: (context) => const TwoFactorSetupScreen(),
      );
    }
    if (settings.name == securitySettings) {
      return MaterialPageRoute(
        builder: (context) => const SecuritySettingsScreen(),
      );
    }
    return null;
  }
}
