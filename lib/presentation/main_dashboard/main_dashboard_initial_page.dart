import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/supabase_service.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_icon_widget.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Home'), centerTitle: true),
        body: _buildSkeleton(theme),
      );
    }

    final userName = _userProfile?['full_name'] ?? 'User';
    final currentWeight = _userProfile?['current_weight_kg']?.toDouble() ?? 0.0;
    final targetWeight = _userProfile?['target_weight_kg']?.toDouble() ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, $userName!'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      color: Colors.blue,
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
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),

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

              SizedBox(height: 2.h),

              NutritionSummaryWidget(
                consumedCalories: _nutritionData?['consumed_calories'] ?? 0,
                targetCalories: _nutritionData?['goal_calories'] ?? 2000,
                proteinG: _nutritionData?['consumed_protein'] ?? 0,
                carbsG: _nutritionData?['consumed_carbs'] ?? 0,
                fatsG: _nutritionData?['consumed_fat'] ?? 0,
              ),

              SizedBox(height: 3.h),
              Text(
                'Weekly Progress',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 1.h),
              const WeeklyProgressWidget(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoWorkoutCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Center(
          child: Column(
            children: [
              CustomIconWidget(
                iconName: 'event_available',
                size: 32,
                color: theme.colorScheme.onSurfaceVariant.withAlpha(128),
              ),
              SizedBox(height: 1.h),
              Text(
                'No workout scheduled for today',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                'Rest day or generate an AI plan',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: theme.colorScheme.onSurfaceVariant.withAlpha(178),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton(ThemeData theme) {
    final color = theme.colorScheme.surfaceContainerHighest.withAlpha(76);
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 10.h,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Container(
                  height: 10.h,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Container(
            height: 18.h,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          SizedBox(height: 2.h),
          Container(
            height: 14.h,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          SizedBox(height: 3.h),
          Container(height: 3.h, width: 40.w, color: color),
          SizedBox(height: 1.h),
          Container(
            height: 15.h,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }
}
