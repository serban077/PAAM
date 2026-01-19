import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/supabase_service.dart';

/// Real-time workout statistics widget
class RealWorkoutStatsWidget extends StatefulWidget {
  const RealWorkoutStatsWidget({super.key});

  @override
  State<RealWorkoutStatsWidget> createState() => _RealWorkoutStatsWidgetState();
}

class _RealWorkoutStatsWidgetState extends State<RealWorkoutStatsWidget> {
  bool _isLoading = true;
  int _completedWorkouts = 0;
  int _scheduledWorkouts = 0;
  int _totalMinutes = 0;
  int _calorieStreak = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      setState(() => _isLoading = true);
      
      final userId = SupabaseService.instance.client.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Get current week start/end
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));

      // Count completed workouts this week
      final logsResponse = await SupabaseService.instance.client
          .from('workout_logs')
          .select('id, duration_seconds')
          .eq('user_id', userId)
          .gte('completed_at', weekStart.toIso8601String())
          .lte('completed_at', weekEnd.toIso8601String());

      final completed = logsResponse.length;
      final totalMinutes = logsResponse.fold<int>(
        0,
        (sum, log) => sum + ((log['duration_seconds'] as int?) ?? 0) ~/ 60,
      );

      // Get scheduled workouts for this week
      final scheduleResponse = await SupabaseService.instance.client
          .from('user_workout_schedules')
          .select('plan_id')
          .eq('user_id', userId)
          .eq('is_active', true)
          .maybeSingle();

      int scheduled = 0;
      if (scheduleResponse != null) {
        final sessionsResponse = await SupabaseService.instance.client
            .from('workout_sessions')
            .select('id')
            .eq('plan_id', scheduleResponse['plan_id']);
        scheduled = sessionsResponse.length;
      }

      // Calculate calorie tracking streak
      final streak = await _calculateCalorieStreak(userId);

      if (mounted) {
        setState(() {
          _completedWorkouts = completed;
          _scheduledWorkouts = scheduled;
          _totalMinutes = totalMinutes;
          _calorieStreak = streak;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<int> _calculateCalorieStreak(String userId) async {
    try {
      // Get all dates with meal entries, ordered descending
      final response = await SupabaseService.instance.client
          .from('user_meals')
          .select('consumed_at')
          .eq('user_id', userId)
          .order('consumed_at', ascending: false);

      if (response.isEmpty) return 0;

      // Extract unique dates
      final dates = response
          .map((meal) => DateTime.parse(meal['consumed_at'] as String))
          .map((dt) => DateTime(dt.year, dt.month, dt.day))
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a)); // Sort descending

      // Count consecutive days from today
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      
      int streak = 0;
      DateTime checkDate = todayDate;

      for (var date in dates) {
        if (date == checkDate) {
          streak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else if (date.isBefore(checkDate)) {
          break; // Gap in streak
        }
      }

      return streak;
    } catch (e) {
      debugPrint('Error calculating streak: $e');
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final completionRate = _scheduledWorkouts > 0
        ? (_completedWorkouts / _scheduledWorkouts * 100).toInt()
        : 0;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistici Săptămână Curentă',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2.h),
            
            // Workout completion
            _buildStatRow(
              icon: Icons.fitness_center,
              label: 'Antrenamente Completate',
              value: '$_completedWorkouts / $_scheduledWorkouts',
              color: Colors.blue,
            ),
            SizedBox(height: 1.h),
            
            // Completion rate
            _buildStatRow(
              icon: Icons.trending_up,
              label: 'Rată Finalizare',
              value: '$completionRate%',
              color: completionRate >= 80 ? Colors.green : Colors.orange,
            ),
            SizedBox(height: 1.h),
            
            // Total minutes
            _buildStatRow(
              icon: Icons.schedule,
              label: 'Minute Active',
              value: '$_totalMinutes min',
              color: Colors.purple,
            ),
            SizedBox(height: 1.h),
            
            // Calorie streak
            _buildStatRow(
              icon: Icons.local_fire_department,
              label: 'Streak Calorii',
              value: '$_calorieStreak zile',
              color: Colors.deepOrange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20.sp),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 14.sp),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
