import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/supabase_service.dart';
import '../../routes/app_routes.dart';
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
  final List<Map<String, dynamic>> _recentWorkouts = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data when returning to dashboard to sync with nutrition screen
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

      // 1. Load user profile
      final profileResponse = await SupabaseService.instance.client
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      // 2. Load today's workout session based on Active Schedule
      Map<String, dynamic>? todaysSession;
      int exerciseCount = 0;
      
      // Get active schedule
      final scheduleResponse = await SupabaseService.instance.client
          .from('user_workout_schedules')
          .select('plan_id')
          .eq('user_id', userId)
          .eq('is_active', true)
          .maybeSingle();
          
      if (scheduleResponse != null) {
        final planId = scheduleResponse['plan_id'];
        final currentWeekday = DateTime.now().weekday; // 1 = Mon, 7 = Sun
        
        // Fetch session for this specific weekday
        final sessionResponse = await SupabaseService.instance.client
            .from('workout_sessions')
            .select('id, session_name, estimated_duration_minutes, focus_area')
            .eq('plan_id', planId)
            .eq('day_number', currentWeekday)
            .maybeSingle();
            
        if (sessionResponse != null) {
          todaysSession = sessionResponse;
          
          // Count exercises for this session
          final count = await SupabaseService.instance.client
              .from('session_exercises')
              .count(CountOption.exact)
              .eq('session_id', sessionResponse['id']);
              
          exerciseCount = count;
          todaysSession!['exercises_count'] = exerciseCount;
        }
      }

      // 3. Load today's nutrition data with proper calculation
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day).toIso8601String();
      
      final nutritionResponse = await SupabaseService.instance.client
          .from('user_meals')
          .select('*, food_database(*)')
          .eq('user_id', userId)
          .gte('consumed_at', todayStart);

      // Calculate nutrition totals
      double totalCalories = 0;
      double totalProtein = 0;
      double totalCarbs = 0;
      double totalFat = 0;

      for (var meal in nutritionResponse) {
        final food = meal['food_database'] as Map<String, dynamic>?;
        if (food != null) {
          final quantity = (meal['serving_quantity'] as num?)?.toDouble() ?? 1;
          final servingSize = (food['serving_size'] as num?)?.toDouble() ?? 100;
          
          final calories = (food['calories'] as num?)?.toDouble() ?? 0;
          final protein = (food['protein_g'] as num?)?.toDouble() ?? 0;
          final carbs = (food['carbs_g'] as num?)?.toDouble() ?? 0;
          final fat = (food['fat_g'] as num?)?.toDouble() ?? 0;
          
          final multiplier = quantity / servingSize;
          
          totalCalories += calories * multiplier;
          totalProtein += protein * multiplier;
          totalCarbs += carbs * multiplier;
          totalFat += fat * multiplier;
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

  Map<String, dynamic> _calculateNutritionTotals(List<dynamic> meals) {
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (var meal in meals) {
      final food = meal['food_database'] as Map<String, dynamic>?;
      if (food != null) {
        final servingQuantity = meal['serving_quantity'] ?? 1.0;
        final servingSize = food['serving_size'] ?? 100.0;
        final multiplier = (servingQuantity * servingSize) / 100.0;

        totalCalories += (food['calories'] ?? 0) * multiplier;
        totalProtein += (food['protein_g'] ?? 0) * multiplier;
        totalCarbs += (food['carbs_g'] ?? 0) * multiplier;
        totalFat += (food['fat_g'] ?? 0) * multiplier;
      }
    }

    return {
      'consumed_calories': totalCalories.round(),
      'consumed_protein': totalProtein.round(),
      'consumed_carbs': totalCarbs.round(),
      'consumed_fat': totalFat.round(),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final userName = _userProfile?['full_name'] ?? 'Utilizator';
    final calorieGoal = _userProfile?['daily_calorie_goal'] ?? 2000;
    final currentWeight = _userProfile?['current_weight_kg']?.toDouble() ?? 0.0;
    final targetWeight = _userProfile?['target_weight_kg']?.toDouble() ?? 0.0;

    final consumedCalories = _nutritionData?['consumed_calories'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Bine ai venit, $userName!'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Metrics row
            Row(
              children: [
                Expanded(
                  child: MetricCardWidget(
                    title: 'Greutate actuală',
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
                    title: 'Țintă',
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

            // Today's workout
            if (_todayWorkout != null)
              TodayWorkoutCardWidget(
                workout: {
                  'title': _todayWorkout!['session_name'] ?? 'Antrenament',
                  'thumbnailUrl': 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80', // Generic gym image
                  'semanticLabel': 'Workout thumbnail',
                  'duration': '${_todayWorkout!['estimated_duration_minutes'] ?? 60} min',
                  'exercises': _todayWorkout!['exercises_count'] ?? 0,
                },
                onStartWorkout: () async {
                  final result = await Navigator.pushNamed(
                    context,
                    AppRoutes.workoutDetail,
                    arguments: {'sessionId': _todayWorkout!['id']},
                  );
                  
                  if (result == true) {
                    _loadDashboardData();
                  }
                },
              )
            else
              Card(
                child: Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Center(
                    child: Text(
                      'Niciun antrenament programat pentru astăzi',
                      style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                    ),
                  ),
                ),
              ),

            SizedBox(height: 2.h),

            // Nutrition summary
            NutritionSummaryWidget(),

            SizedBox(height: 3.h),

            // Weekly progress
            Text(
              'Progres săptămânal',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1.h),
            const WeeklyProgressWidget(), // Removed Expanded here
          ],
        ),
      ),
    );
  }
}
