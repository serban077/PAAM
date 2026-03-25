import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import './widgets/metric_card_widget.dart';
import './widgets/today_workout_card_widget.dart';
import './widgets/nutrition_summary_widget.dart';
import './widgets/weekly_progress_widget.dart';

class MainDashboardInitialPage extends StatefulWidget {
  const MainDashboardInitialPage({super.key});

  @override
  State<MainDashboardInitialPage> createState() =>
      _MainDashboardInitialPageState();
}

class _MainDashboardInitialPageState extends State<MainDashboardInitialPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _todayWorkout;
  Map<String, dynamic>? _nutritionData;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isLoading) {
      _loadDashboardData();
    }
  }

  Future<void> _loadDashboardData() async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);

      final userId = SupabaseService.instance.client.auth.currentUser?.id;
      if (userId == null) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        return;
      }

      final profileResponse = await SupabaseService.instance.client
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      Map<String, dynamic>? todaysSession;
      int exerciseCount = 0;

      final scheduleResponse = await SupabaseService.instance.client
          .from('user_workout_schedules')
          .select('plan_id')
          .eq('user_id', userId)
          .eq('is_active', true)
          .maybeSingle();

      if (scheduleResponse != null) {
        final planId = scheduleResponse['plan_id'];
        final currentWeekday = DateTime.now().weekday;

        final sessionResponse = await SupabaseService.instance.client
            .from('workout_sessions')
            .select('id, session_name, estimated_duration_minutes, focus_area')
            .eq('plan_id', planId)
            .eq('day_number', currentWeekday)
            .maybeSingle();

        if (sessionResponse != null) {
          todaysSession = sessionResponse;
          final count = await SupabaseService.instance.client
              .from('session_exercises')
              .count(CountOption.exact)
              .eq('session_id', sessionResponse['id']);
          exerciseCount = count;
          todaysSession['exercises_count'] = exerciseCount;
        }
      }

      final today = DateTime.now();
      final todayStart =
          DateTime(today.year, today.month, today.day).toIso8601String();

      final nutritionResponse = await SupabaseService.instance.client
          .from('user_meals')
          .select('*, food_database(*)')
          .eq('user_id', userId)
          .gte('consumed_at', todayStart);

      double totalCalories = 0;
      double totalProtein = 0;
      double totalCarbs = 0;
      double totalFat = 0;

      for (var meal in nutritionResponse) {
        final food = meal['food_database'] as Map<String, dynamic>?;
        if (food != null) {
          final quantity = (meal['serving_quantity'] as num?)?.toDouble() ?? 1;
          final servingSize =
              (food['serving_size'] as num?)?.toDouble() ?? 100;
          final multiplier = quantity / servingSize;

          totalCalories +=
              ((food['calories'] as num?)?.toDouble() ?? 0) * multiplier;
          totalProtein +=
              ((food['protein_g'] as num?)?.toDouble() ?? 0) * multiplier;
          totalCarbs +=
              ((food['carbs_g'] as num?)?.toDouble() ?? 0) * multiplier;
          totalFat +=
              ((food['fat_g'] as num?)?.toDouble() ?? 0) * multiplier;
        }
      }

      final nutritionData = {
        'consumed_calories': totalCalories.toInt(),
        'consumed_protein': totalProtein.toInt(),
        'consumed_carbs': totalCarbs.toInt(),
        'consumed_fat': totalFat.toInt(),
        'goal_calories': profileResponse?['daily_calorie_goal'] ?? 2000,
      };

      if (!mounted) return;
      setState(() {
        _userProfile = profileResponse;
        _todayWorkout = todaysSession;
        _nutritionData = nutritionData;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading dashboard: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refresh() async {
    HapticFeedback.lightImpact();
    await _loadDashboardData();
  }

  // ── Helpers ────────────────────────────────────────────────────────

  List<Color> _gradientColors(bool isDark) {
    return isDark
        ? [AppTheme.backgroundDark, AppTheme.primaryVariantDark]
        : [AppTheme.primaryVariantLight, AppTheme.primaryLight];
  }

  String _formattedDate() {
    final now = DateTime.now();
    const dayNames = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${dayNames[now.weekday - 1]}, ${monthNames[now.month - 1]} ${now.day}';
  }

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    if (_isLoading) return _buildLoadingScreen(isDark);

    final userName = (_userProfile?['full_name'] ?? 'User') as String;
    final firstName = userName.split(' ').first;
    final currentWeight =
        _userProfile?['current_weight_kg']?.toDouble() ?? 0.0;
    final targetWeight =
        _userProfile?['target_weight_kg']?.toDouble() ?? 0.0;

    return Scaffold(
      body: Stack(
        children: [
          // Full-screen gradient background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _gradientColors(isDark),
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(firstName),
                Expanded(
                  child: _buildContentCard(
                    isDark,
                    theme,
                    currentWeight,
                    targetWeight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header (inside gradient) ───────────────────────────────────────

  Widget _buildHeader(String firstName) {
    return Padding(
      padding: EdgeInsets.fromLTRB(5.w, 1.5.h, 5.w, 2.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hey, $firstName!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                ),
                SizedBox(height: 0.4.h),
                Text(
                  _formattedDate(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                ),
              ],
            ),
          ),
          CircleAvatar(
            radius: 5.5.w,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Content Card ───────────────────────────────────────────────────

  Widget _buildContentCard(
    bool isDark,
    ThemeData theme,
    double currentWeight,
    double targetWeight,
  ) {
    final cardColor = isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: isDark
            ? Border(
                top: BorderSide(
                  color: AppTheme.primaryDark.withValues(alpha: 0.25),
                  width: 1,
                ),
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.35)
                : AppTheme.shadowLight,
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: theme.colorScheme.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(5.w, 2.5.h, 5.w, 4.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Stats
                _buildSectionTitle('Quick Stats', theme),
                SizedBox(height: 1.5.h),
                Row(
                  children: [
                    Expanded(
                      child: MetricCardWidget(
                        title: 'Current Weight',
                        value: currentWeight > 0
                            ? '${currentWeight.toStringAsFixed(1)} kg'
                            : 'N/A',
                        unit: 'kg',
                        icon: 'monitor_weight',
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: MetricCardWidget(
                        title: 'Target',
                        value: targetWeight > 0
                            ? '${targetWeight.toStringAsFixed(1)} kg'
                            : 'N/A',
                        unit: 'kg',
                        icon: 'flag',
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.5.h),

                // Today's Workout
                _buildSectionTitle("Today's Workout", theme),
                SizedBox(height: 1.5.h),
                if (_todayWorkout != null)
                  TodayWorkoutCardWidget(
                    workout: {
                      'title': _todayWorkout!['session_name'] ?? 'Workout',
                      'thumbnailUrl':
                          'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
                      'semanticLabel': 'Workout thumbnail',
                      'duration':
                          '${_todayWorkout!['estimated_duration_minutes'] ?? 60} min',
                      'exercises': _todayWorkout!['exercises_count'] ?? 0,
                    },
                    onStartWorkout: () async {
                      HapticFeedback.lightImpact();
                      final result = await Navigator.pushNamed(
                        context,
                        AppRoutes.workoutDetail,
                        arguments: {'sessionId': _todayWorkout!['id']},
                      );
                      if (result == true) _loadDashboardData();
                    },
                  )
                else
                  _buildNoWorkoutCard(theme),
                SizedBox(height: 2.5.h),

                // Nutrition
                _buildSectionTitle('Nutrition', theme),
                SizedBox(height: 1.5.h),
                NutritionSummaryWidget(
                  consumedCalories:
                      _nutritionData?['consumed_calories'] ?? 0,
                  targetCalories:
                      _nutritionData?['goal_calories'] ?? 2000,
                  proteinG: _nutritionData?['consumed_protein'] ?? 0,
                  carbsG: _nutritionData?['consumed_carbs'] ?? 0,
                  fatsG: _nutritionData?['consumed_fat'] ?? 0,
                ),
                SizedBox(height: 2.5.h),

                // Weekly Progress
                _buildSectionTitle('Weekly Progress', theme),
                SizedBox(height: 1.5.h),
                const WeeklyProgressWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Section Title ──────────────────────────────────────────────────

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );
  }

  // ── No Workout Card ────────────────────────────────────────────────

  Widget _buildNoWorkoutCard(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 3.h, horizontal: 4.w),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.primaryDark.withValues(alpha: 0.08)
            : AppTheme.primaryLight.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppTheme.primaryDark.withValues(alpha: 0.15)
              : AppTheme.primaryLight.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        children: [
          CustomIconWidget(
            iconName: 'event_available',
            size: 36,
            color: theme.colorScheme.primary.withValues(alpha: 0.5),
          ),
          SizedBox(height: 1.h),
          Text(
            'No workout scheduled for today',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Rest day or generate an AI plan',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  // ── Loading Screen ─────────────────────────────────────────────────

  Widget _buildLoadingScreen(bool isDark) {
    final cardColor = isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight;
    final skeletonColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.grey.shade200;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _gradientColors(isDark),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Skeleton header
                Padding(
                  padding: EdgeInsets.fromLTRB(5.w, 1.5.h, 5.w, 2.h),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 2.5.h,
                            width: 40.w,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          SizedBox(height: 1.h),
                          Container(
                            height: 1.8.h,
                            width: 32.w,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      CircleAvatar(
                        radius: 5.5.w,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                      ),
                    ],
                  ),
                ),
                // Skeleton card
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      border: isDark
                          ? Border(
                              top: BorderSide(
                                color: AppTheme.primaryDark
                                    .withValues(alpha: 0.25),
                                width: 1,
                              ),
                            )
                          : null,
                    ),
                    padding: EdgeInsets.fromLTRB(5.w, 2.5.h, 5.w, 4.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section title skeleton
                        Container(
                          height: 2.h,
                          width: 25.w,
                          decoration: BoxDecoration(
                            color: skeletonColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        SizedBox(height: 1.5.h),
                        // Metric cards skeleton
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 10.h,
                                decoration: BoxDecoration(
                                  color: skeletonColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            SizedBox(width: 3.w),
                            Expanded(
                              child: Container(
                                height: 10.h,
                                decoration: BoxDecoration(
                                  color: skeletonColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 2.5.h),
                        // Section title skeleton
                        Container(
                          height: 2.h,
                          width: 32.w,
                          decoration: BoxDecoration(
                            color: skeletonColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        SizedBox(height: 1.5.h),
                        // Workout card skeleton
                        Container(
                          height: 16.h,
                          decoration: BoxDecoration(
                            color: skeletonColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        SizedBox(height: 2.5.h),
                        // Section title skeleton
                        Container(
                          height: 2.h,
                          width: 22.w,
                          decoration: BoxDecoration(
                            color: skeletonColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        SizedBox(height: 1.5.h),
                        // Nutrition skeleton
                        Container(
                          height: 12.h,
                          decoration: BoxDecoration(
                            color: skeletonColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
