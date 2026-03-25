import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import './widgets/metric_card_widget.dart';
import './widgets/today_workout_card_widget.dart';
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
  int _workoutStreak = 0;

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

      // Calculate workout streak from workout_logs
      int workoutStreak = 0;
      try {
        final logs = await SupabaseService.instance.client
            .from('workout_logs')
            .select('completed_at')
            .eq('user_id', userId)
            .order('completed_at', ascending: false)
            .timeout(const Duration(seconds: 15));

        final logDays = (logs as List).map((l) {
          final dt = DateTime.parse(l['completed_at'] as String);
          return DateTime(dt.year, dt.month, dt.day);
        }).toSet();

        final today = DateTime.now();
        var checkDay = DateTime(today.year, today.month, today.day);
        while (logDays.contains(checkDay)) {
          workoutStreak++;
          checkDay = checkDay.subtract(const Duration(days: 1));
        }
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _userProfile = profileResponse;
        _todayWorkout = todaysSession;
        _workoutStreak = workoutStreak;
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

                // Workout Streak
                _buildSectionTitle('Workout Streak', theme),
                SizedBox(height: 1.5.h),
                _buildWorkoutStreakCard(theme),
                SizedBox(height: 2.5.h),

                // Daily Tip
                _buildSectionTitle("Today's Tip", theme),
                SizedBox(height: 1.5.h),
                _buildDailyTipCard(theme),
                SizedBox(height: 2.5.h),

                // Calorie Target
                _buildSectionTitle('Calorie Target', theme),
                SizedBox(height: 1.5.h),
                _buildTdeeCard(theme),
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

  // ── Workout Streak Card ────────────────────────────────────────────

  Widget _buildWorkoutStreakCard(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final hasStreak = _workoutStreak > 0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 2.5.h, horizontal: 4.w),
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
      child: Row(
        children: [
          CustomIconWidget(
            iconName: 'local_fire_department',
            size: 36,
            color: hasStreak
                ? const Color(0xFFFF6F00)
                : theme.colorScheme.onSurfaceVariant,
          ),
          SizedBox(width: 3.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasStreak ? '$_workoutStreak-day streak' : 'No streak yet',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: hasStreak
                      ? const Color(0xFFFF6F00)
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 0.4.h),
              Text(
                hasStreak
                    ? 'Keep it up!'
                    : 'Log a workout to start your streak',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Daily Tip Card ─────────────────────────────────────────────────

  static const List<String> _fitnessTips = [
    'Drink at least 8 glasses of water today to support performance and recovery.',
    'Aim for 7–9 hours of sleep — that\'s when muscles grow and energy is restored.',
    'Progressive overload is the key: add a little more weight or reps each week.',
    'Compound lifts (squat, deadlift, bench press) build the most muscle per minute.',
    'Rest days are not lazy days — they are when your body actually gets stronger.',
    'Eat protein within 60 minutes after training to maximize muscle recovery.',
    'Consistency beats perfection — an average workout today beats a skipped one.',
    'Track your workouts in the app. What gets measured gets improved.',
    'Always warm up for 5–10 minutes to reduce injury risk and improve performance.',
    'Focus on mind-muscle connection — feel the muscle working, not just moving weight.',
    'A caloric deficit of 300–500 kcal/day is ideal for fat loss without muscle loss.',
    'Stretch after workouts, not before — static stretching before can reduce strength.',
    'Creatine monohydrate is the most well-studied supplement for strength gains.',
    'Try supersets (two exercises back-to-back) to cut rest time and increase intensity.',
    'Squat to depth — thighs parallel to the floor for full leg muscle activation.',
    'Eat fiber-rich vegetables at every meal to stay full and support gut health.',
    'Don\'t skip leg day — leg training triggers the most anabolic hormone release.',
    'Deload every 4–6 weeks: reduce volume by 40% to let joints and tendons recover.',
    'Breathe correctly: exhale on exertion, inhale on the return phase.',
    'Body composition matters more than scale weight — track measurements too.',
    'Core training goes beyond crunches — planks and farmer carries build real strength.',
    'Meal prepping on Sunday prevents poor food choices during a busy week.',
    'Pre-workout meal: complex carbs + protein about 60–90 minutes before training.',
    'Do cardio after weights, not before — save your glycogen for the heavy lifts.',
    'Foam roll your hips and thoracic spine daily to maintain mobility.',
    'HIIT cardio 2–3x per week is more time-efficient for fat loss than steady-state.',
    'Eating slowly (20+ minutes per meal) improves satiety and prevents overeating.',
    'Grip strength predicts overall health — try pull-ups or a hand gripper daily.',
    'Review your past sessions regularly — it\'s the fastest way to spot plateaus.',
    'Enjoy the process. Long-term consistency starts with workouts you actually enjoy.',
  ];

  Widget _buildDailyTipCard(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final tip = _fitnessTips[dayOfYear % _fitnessTips.length];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.secondary.withValues(alpha: 0.08)
            : theme.colorScheme.secondary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.secondary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomIconWidget(
            iconName: 'lightbulb_outline',
            size: 22,
            color: theme.colorScheme.secondary,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(
              tip,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── TDEE Snapshot Card ─────────────────────────────────────────────

  String _activityLevelLabel(String? level) {
    switch (level) {
      case 'sedentary':
        return 'Sedentary';
      case 'lightly_active':
        return 'Lightly Active';
      case 'moderately_active':
        return 'Moderately Active';
      case 'very_active':
        return 'Very Active';
      case 'extremely_active':
        return 'Extremely Active';
      default:
        return 'Active';
    }
  }

  Widget _buildTdeeCard(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final calories = _userProfile?['daily_calorie_goal'] as int? ?? 2000;
    final activityLabel = _activityLevelLabel(
      _userProfile?['activity_level'] as String?,
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
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
      child: Row(
        children: [
          CustomIconWidget(
            iconName: 'bolt',
            size: 32,
            color: theme.colorScheme.primary,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily target: $calories kcal',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    activityLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
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
