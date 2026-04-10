import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/supabase_service.dart';
import '../../services/app_cache_service.dart';
import '../../services/gemini_ai_service.dart';
import '../../services/calorie_calculator_service.dart';
import '../../services/theme_service.dart';
import '../../services/nutrition_service.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/personal_info_section_widget.dart';
import './widgets/fitness_preferences_section_widget.dart';
import './widgets/notification_settings_section_widget.dart';
import './widgets/account_management_section_widget.dart';
import '../authentication_onboarding_flow/widgets/onboarding_survey_widget.dart';

/// User Profile Management Screen
/// Modern gradient-hero layout with stats row + grouped settings cards
class UserProfileManagement extends StatefulWidget {
  const UserProfileManagement({super.key});

  @override
  State<UserProfileManagement> createState() => _UserProfileManagementState();
}

class _UserProfileManagementState extends State<UserProfileManagement> {
  bool _isLoading = true;
  Map<String, dynamic>? _userProfile;
  int _contributionCount = 0;

  final _nutritionService = NutritionService(SupabaseService.instance.client);

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadContributionCount();
  }

  Future<void> _loadContributionCount({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh) {
        final cached = AppCacheService.instance.getContributions();
        if (cached != null) {
          if (mounted) setState(() => _contributionCount = cached.length);
          return;
        }
      }
      final data = await _nutritionService.getMyContributions();
      AppCacheService.instance.setContributions(data);
      if (mounted) setState(() => _contributionCount = data.length);
    } catch (_) {}
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() => _isLoading = true);
      final userId = SupabaseService.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }
      final response = await SupabaseService.instance.client
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      setState(() {
        _userProfile = response;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _regenerateAIPlan() async {
    try {
      if (!mounted) return;
      final userId = SupabaseService.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      await GeminiAIService().generateCompletePlan(userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your plan has been updated with new preferences!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error regenerating plan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateSessionDurations(
      String userId, int newDurationMinutes) async {
    try {
      final scheduleResponse = await SupabaseService.instance.client
          .from('user_workout_schedules')
          .select('plan_id')
          .eq('user_id', userId)
          .eq('is_active', true)
          .maybeSingle();
      if (scheduleResponse == null) return;
      final planId = scheduleResponse['plan_id'];
      await SupabaseService.instance.client
          .from('workout_sessions')
          .update({'estimated_duration_minutes': newDurationMinutes}).eq(
              'plan_id', planId);
    } catch (e) {
      debugPrint('Error updating session durations: $e');
    }
  }

  Future<void> _handleLogout() async {
    try {
      AppCacheService.instance.invalidateAll();
      await SupabaseService.instance.client.auth.signOut();
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
          AppRoutes.authenticationOnboardingFlow,
          (_) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error signing out: $e')));
      }
    }
  }

  Future<void> _handleRecalibrate() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OnboardingSurveyWidget(
          isEditing: true,
          initialData: _userProfile,
        ),
      ),
    );
    if (result == true) _loadUserProfile();
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
        body: _buildLoadingSkeleton(isDark),
      );
    }

    if (_userProfile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Profile unavailable')),
      );
    }

    final fullName = _userProfile!['full_name'] ?? 'User';
    final email = _userProfile!['email'] ?? '';
    final workoutFrequency = _userProfile!['weekly_training_frequency'] ?? 3;
    final sessionDuration =
        ((_userProfile!['available_training_hours_per_session'] ?? 1.0) * 60)
            .toInt();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A1628) : AppTheme.primaryVariantLight,
      body: Stack(
        children: [
          // Full-height gradient background (bleeds behind status bar)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 44.h,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF0A1628), const Color(0xFF1B3A5E)]
                      : [AppTheme.primaryVariantLight, AppTheme.primaryLight],
                ),
              ),
            ),
          ),
          // Main content
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeroHeader(
                    context, isDark, fullName, email, workoutFrequency, sessionDuration),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(28)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isDark ? 0.35 : 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, -6),
                        ),
                      ],
                    ),
                    child: _buildBody(context, isDark),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Hero Header ─────────────────────────────────────────────────────────

  Widget _buildHeroHeader(BuildContext context, bool isDark, String fullName,
      String email, int workoutFrequency, int sessionDuration) {
    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U';
    final goal = _userProfile!['fitness_goal']?.toString() ?? 'fitness';
    final activity =
        _userProfile!['activity_level']?.toString() ?? 'moderately_active';

    return Padding(
      padding: EdgeInsets.fromLTRB(5.w, 1.h, 5.w, 3.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + name + badges
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildAvatarRing(initial, isDark),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 0.4.h),
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 1.2.h),
                    Row(
                      children: [
                        _ProfileBadge(
                          label: _goalDisplay[goal] ?? goal.replaceAll('_', ' '),
                          solid: true,
                        ),
                        SizedBox(width: 2.w),
                        _ProfileBadge(
                          label: _activityDisplay[activity] ??
                              activity.replaceAll('_', ' '),
                          solid: false,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.5.h),
          // Stats glass pill
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.5.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.18),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem('$workoutFrequency×', 'per week', 'fitness_center'),
                _buildStatDivider(),
                _buildStatItem('${sessionDuration}m', 'per session', 'timer'),
                _buildStatDivider(),
                _buildStatItem(
                    '$_contributionCount', 'foods added', 'restaurant'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarRing(String initial, bool isDark) {
    return Container(
      width: 18.w,
      height: 18.w,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF6F00), Color(0xFFFFB300)],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(0.5.w),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF1a3a5c), const Color(0xFF0d2137)]
                  : [const Color(0xFF43A047), const Color(0xFF2E7D32)],
            ),
          ),
          child: Center(
            child: Text(
              initial,
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, String iconName) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconWidget(
              iconName: iconName,
              color: Colors.white.withValues(alpha: 0.75),
              size: 16),
          SizedBox(height: 0.4.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.sp,
              color: Colors.white.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 6.h,
      color: Colors.white.withValues(alpha: 0.2),
    );
  }

  // ─── Body ─────────────────────────────────────────────────────────────────

  Widget _buildBody(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(4.w, 1.5.h, 4.w, 14.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 10.w,
              height: 0.45.h,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          SizedBox(height: 2.5.h),

          // ── Profile Settings ──
          _buildSectionLabel(context, 'PROFILE SETTINGS'),
          SizedBox(height: 1.h),
          PersonalInfoSectionWidget(
            age: _userProfile!['age'] ?? 0,
            weight: (_userProfile!['weight_kg'] ?? 0.0).toDouble(),
            height: (_userProfile!['height_cm'] ?? 0.0).toDouble(),
            targetWeight:
                (_userProfile!['target_weight_kg'] as num?)?.toDouble(),
            targetTimeframeWeeks:
                _userProfile!['target_timeframe_weeks'] as int?,
            activityLevel: _userProfile!['activity_level']?.toString() ??
                'moderately_active',
            onUpdate: (data) async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                final userId =
                    SupabaseService.instance.client.auth.currentUser?.id;
                if (userId == null) return;
                await SupabaseService.instance.client
                    .from('user_profiles')
                    .update({
                  'age': data['age'],
                  'weight_kg': data['weight'],
                  'height_cm': data['height'],
                  'current_weight_kg': data['weight'],
                  'target_weight_kg': data['targetWeight'],
                  'target_timeframe_weeks': data['targetTimeframeWeeks'],
                  'activity_level': data['activityLevel'],
                }).eq('id', userId);
                try {
                  final nutritionGoals =
                      CalorieCalculatorService.calculateNutritionGoals(
                    weightKg: (data['weight'] as num).toDouble(),
                    heightCm: (data['height'] as num).toDouble(),
                    age: data['age'] as int,
                    gender: _userProfile!['gender'] ?? 'masculin',
                    weeklyTrainingFrequency:
                        _userProfile!['weekly_training_frequency'] ?? 3,
                    fitnessGoal:
                        _userProfile!['fitness_goal'] ?? 'maintenance',
                    targetWeightKg:
                        (data['targetWeight'] as num?)?.toDouble(),
                    targetTimeframeWeeks:
                        data['targetTimeframeWeeks'] as int?,
                  );
                  await SupabaseService.instance.client
                      .from('user_profiles')
                      .update({
                    'daily_calorie_goal':
                        nutritionGoals['daily_calorie_goal'],
                    'protein_goal_g': nutritionGoals['protein_goal_g'],
                    'carbs_goal_g': nutritionGoals['carbs_goal_g'],
                    'fat_goal_g': nutritionGoals['fat_goal_g'],
                  }).eq('id', userId);
                  await SupabaseService.instance.client
                      .from('daily_nutrition_goals')
                      .delete()
                      .eq('user_id', userId);
                } catch (e) {
                  debugPrint('Error calculating nutrition goals: $e');
                }
                await _loadUserProfile();
                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Personal information saved!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red),
                  );
                }
              }
            },
          ),
          SizedBox(height: 1.5.h),
          FitnessPreferencesSectionWidget(
            workoutFrequency: _userProfile!['weekly_training_frequency'] ?? 3,
            sessionDuration:
                ((_userProfile!['available_training_hours_per_session'] ?? 1.0) *
                        60)
                    .toInt(),
            availableEquipment: _userProfile!['equipment_available'] != null
                ? [_userProfile!['equipment_available'].toString()]
                : ['gym'],
            fitnessGoal: _userProfile!['fitness_goal']?.toString() ??
                'body_recomposition',
            onUpdate: (data) async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                final userId =
                    SupabaseService.instance.client.auth.currentUser?.id;
                if (userId == null) return;
                final oldFrequency =
                    _userProfile!['weekly_training_frequency'];
                final oldDuration =
                    _userProfile!['available_training_hours_per_session'];
                final newFrequency = data['workoutFrequency'];
                final newDuration = data['sessionDuration'] / 60.0;
                final shouldRegenerate = (oldFrequency != newFrequency) ||
                    ((oldDuration ?? 1.0) != newDuration);
                await SupabaseService.instance.client
                    .from('user_profiles')
                    .update({
                  'weekly_training_frequency': newFrequency,
                  'available_training_hours_per_session': newDuration,
                  'equipment_available':
                      data['availableEquipment'].isNotEmpty
                          ? data['availableEquipment'][0]
                          : 'gym',
                  'fitness_goal': data['fitnessGoal'],
                }).eq('id', userId);
                try {
                  final nutritionGoals =
                      CalorieCalculatorService.calculateNutritionGoals(
                    weightKg:
                        (_userProfile!['weight_kg'] as num?)?.toDouble() ??
                            70.0,
                    heightCm:
                        (_userProfile!['height_cm'] as num?)?.toDouble() ??
                            170.0,
                    age: _userProfile!['age'] ?? 30,
                    gender: _userProfile!['gender'] ?? 'masculin',
                    weeklyTrainingFrequency: newFrequency,
                    fitnessGoal: data['fitnessGoal'],
                    targetWeightKg:
                        (_userProfile!['target_weight_kg'] as num?)?.toDouble(),
                    targetTimeframeWeeks:
                        _userProfile!['target_timeframe_weeks'] as int?,
                  );
                  await SupabaseService.instance.client
                      .from('user_profiles')
                      .update({
                    'daily_calorie_goal':
                        nutritionGoals['daily_calorie_goal'],
                    'protein_goal_g': nutritionGoals['protein_goal_g'],
                    'carbs_goal_g': nutritionGoals['carbs_goal_g'],
                    'fat_goal_g': nutritionGoals['fat_goal_g'],
                  }).eq('id', userId);
                  await SupabaseService.instance.client
                      .from('daily_nutrition_goals')
                      .delete()
                      .eq('user_id', userId);
                } catch (e) {
                  debugPrint('Error calculating nutrition goals: $e');
                }
                await _loadUserProfile();
                if (!shouldRegenerate &&
                    (oldDuration ?? 1.0) != newDuration &&
                    mounted) {
                  await _updateSessionDurations(
                      userId, (newDuration * 60).toInt());
                }
                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Preferences saved!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
                if (shouldRegenerate && mounted) {
                  await _regenerateAIPlan();
                }
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red),
                  );
                }
              }
            },
          ),
          SizedBox(height: 3.h),

          // ── Notifications ──
          _buildSectionLabel(context, 'NOTIFICATIONS'),
          SizedBox(height: 1.h),
          NotificationSettingsSectionWidget(
            workoutReminders: _userProfile!['workout_reminders'] ?? true,
            progressUpdates: _userProfile!['progress_updates'] ?? true,
            motivationalMessages:
                _userProfile!['motivational_messages'] ?? true,
            onUpdate: (data) async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                final userId =
                    SupabaseService.instance.client.auth.currentUser?.id;
                if (userId == null) return;
                await SupabaseService.instance.client
                    .from('user_profiles')
                    .update({
                  'workout_reminders': data['workoutReminders'],
                  'progress_updates': data['progressUpdates'],
                  'motivational_messages': data['motivationalMessages'],
                }).eq('id', userId);
                await _loadUserProfile();
                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Notification settings saved!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Supabase error: $e'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              }
            },
          ),
          SizedBox(height: 3.h),

          // ── Appearance ──
          _buildSectionLabel(context, 'APPEARANCE'),
          SizedBox(height: 1.h),
          _buildDarkModeCard(context),
          SizedBox(height: 3.h),

          // ── AI Plan ──
          _buildSectionLabel(context, 'AI PLAN'),
          SizedBox(height: 1.h),
          _buildRecalibrateCard(context, isDark),
          SizedBox(height: 3.h),

          // ── Activity ──
          _buildSectionLabel(context, 'ACTIVITY'),
          SizedBox(height: 1.h),
          _buildSettingsTile(
            context,
            iconName: 'restaurant',
            label: 'My Food Contributions',
            subtitle: _contributionCount == 0
                ? 'No contributions yet'
                : '$_contributionCount food${_contributionCount == 1 ? '' : 's'} added',
            badge: _contributionCount > 0 ? '$_contributionCount' : null,
            onTap: () async {
              await Navigator.of(context, rootNavigator: true)
                  .pushNamed(AppRoutes.myFoodContributions);
              AppCacheService.instance.invalidateContributions();
              _loadContributionCount(forceRefresh: true);
            },
          ),
          SizedBox(height: 1.5.h),
          _buildSettingsTile(
            context,
            iconName: 'security',
            label: 'Security',
            subtitle: 'Password, 2FA, biometric',
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.securitySettings),
          ),
          SizedBox(height: 3.h),

          // ── Account ──
          _buildSectionLabel(context, 'ACCOUNT'),
          SizedBox(height: 1.h),
          AccountManagementSectionWidget(onLogout: _handleLogout),
        ],
      ),
    );
  }

  // ─── Helper widgets ───────────────────────────────────────────────────────

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Padding(
      padding: EdgeInsets.only(left: 1.w),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withValues(alpha: 0.7),
              letterSpacing: 1.3,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildDarkModeCard(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeService.themeNotifier,
        builder: (context, themeMode, child) {
          return SwitchListTile(
            contentPadding:
                EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.8.h),
            secondary: Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomIconWidget(
                iconName: themeMode == ThemeMode.dark
                    ? 'dark_mode'
                    : 'light_mode',
                color: theme.colorScheme.primary,
                size: 22,
              ),
            ),
            title: Text(
              'Dark Mode',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Switch between light and dark theme',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            value: themeMode == ThemeMode.dark,
            onChanged: (isDark) => ThemeService.setDarkMode(isDark),
          );
        },
      ),
    );
  }

  Widget _buildRecalibrateCard(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1B3A5E), const Color(0xFF0A1628)]
              : [AppTheme.primaryLight, AppTheme.primaryVariantLight],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryLight.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: _handleRecalibrate,
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.white.withValues(alpha: 0.1),
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(2.5.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const CustomIconWidget(
                    iconName: 'auto_awesome',
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recalibrate AI Plan',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14.sp,
                        ),
                      ),
                      SizedBox(height: 0.4.h),
                      Text(
                        'Re-run onboarding to regenerate your plan',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                CustomIconWidget(
                  iconName: 'arrow_forward',
                  color: Colors.white.withValues(alpha: 0.75),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required String iconName,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    String? badge,
  }) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.h),
        leading: Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: CustomIconWidget(
              iconName: iconName, color: theme.colorScheme.primary, size: 22),
        ),
        title: Text(label,
            style: theme.textTheme.bodyLarge
                ?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant)),
        trailing: badge != null
            ? Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: theme.colorScheme.onTertiary,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : CustomIconWidget(
                iconName: 'chevron_right',
                color: theme.colorScheme.onSurfaceVariant,
                size: 20),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLoadingSkeleton(bool isDark) {
    return Column(
      children: [
        // Gradient header skeleton
        Container(
          height: 36.h,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF0A1628), const Color(0xFF1B3A5E)]
                  : [AppTheme.primaryVariantLight, AppTheme.primaryLight],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.5,
            ),
          ),
        ),
        Expanded(
          child: Container(
            color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
          ),
        ),
      ],
    );
  }

  // ─── Label maps ───────────────────────────────────────────────────────────

  static const _goalDisplay = {
    'weight_loss': 'Weight Loss',
    'muscle_gain': 'Muscle Gain',
    'endurance': 'Endurance',
    'body_recomposition': 'Recomposition',
    'maintenance': 'Maintenance',
    'toning': 'Toning',
  };

  static const _activityDisplay = {
    'sedentary': 'Sedentary',
    'lightly_active': 'Light',
    'moderately_active': 'Moderate',
    'very_active': 'Very Active',
    'extremely_active': 'Athlete',
  };
}

// ─── Badge widget ─────────────────────────────────────────────────────────────

class _ProfileBadge extends StatelessWidget {
  final String label;
  final bool solid;

  const _ProfileBadge({required this.label, required this.solid});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.45.h),
      decoration: BoxDecoration(
        color: solid
            ? const Color(0xFFFF6F00).withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: solid
            ? null
            : Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 9.sp,
          fontWeight: solid ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}
