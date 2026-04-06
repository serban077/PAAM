import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/supabase_service.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Weekly workout statistics — animated 2×2 stat grid
class RealWorkoutStatsWidget extends StatefulWidget {
  const RealWorkoutStatsWidget({super.key});

  @override
  State<RealWorkoutStatsWidget> createState() =>
      _RealWorkoutStatsWidgetState();
}

class _RealWorkoutStatsWidgetState extends State<RealWorkoutStatsWidget>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  int _completedWorkouts = 0;
  int _scheduledWorkouts = 0;
  int _totalMinutes = 0;
  int _calorieStreak = 0;
  late AnimationController _staggerCtrl;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadStats();
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      setState(() => _isLoading = true);

      final userId =
          SupabaseService.instance.client.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));

      final logsResponse = await SupabaseService.instance.client
          .from('workout_logs')
          .select('id, duration_seconds')
          .eq('user_id', userId)
          .gte('completed_at', weekStart.toIso8601String())
          .lte('completed_at', weekEnd.toIso8601String());

      final completed = logsResponse.length;
      final totalMinutes = logsResponse.fold<int>(
        0,
        (sum, log) =>
            sum + ((log['duration_seconds'] as int?) ?? 0) ~/ 60,
      );

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

      final streak = await _calculateCalorieStreak(userId);

      if (mounted) {
        setState(() {
          _completedWorkouts = completed;
          _scheduledWorkouts = scheduled;
          _totalMinutes = totalMinutes;
          _calorieStreak = streak;
          _isLoading = false;
        });
        _staggerCtrl.forward(from: 0);
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<int> _calculateCalorieStreak(String userId) async {
    try {
      final response = await SupabaseService.instance.client
          .from('user_meals')
          .select('consumed_at')
          .eq('user_id', userId)
          .order('consumed_at', ascending: false);

      if (response.isEmpty) return 0;

      final dates = response
          .map((meal) => DateTime.parse(meal['consumed_at'] as String))
          .map((dt) => DateTime(dt.year, dt.month, dt.day))
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a));

      final today = DateTime.now();
      final todayDate =
          DateTime(today.year, today.month, today.day);
      int streak = 0;
      DateTime checkDate = todayDate;

      for (var date in dates) {
        if (date == checkDate) {
          streak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else if (date.isBefore(checkDate)) {
          break;
        }
      }
      return streak;
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Container(
        height: 22.h,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: theme.colorScheme.primary,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    final completionRate = _scheduledWorkouts > 0
        ? _completedWorkouts / _scheduledWorkouts
        : 0.0;

    final stats = [
      _StatData(
        label: 'Workouts',
        value: '$_completedWorkouts',
        sub: 'of $_scheduledWorkouts planned',
        iconName: 'fitness_center',
        color: theme.colorScheme.primary,
        progress: completionRate,
      ),
      _StatData(
        label: 'Completion',
        value: '${(completionRate * 100).toInt()}%',
        sub: completionRate >= 0.8 ? 'Great week!' : 'Keep going!',
        iconName: 'trending_up',
        color: completionRate >= 0.8
            ? theme.colorScheme.primary
            : theme.colorScheme.tertiary,
        progress: completionRate,
      ),
      _StatData(
        label: 'Active Time',
        value: '$_totalMinutes',
        sub: 'minutes this week',
        iconName: 'schedule',
        color: theme.colorScheme.secondary,
        progress: (_totalMinutes / 300).clamp(0.0, 1.0),
      ),
      _StatData(
        label: 'Streak',
        value: '$_calorieStreak',
        sub: _calorieStreak == 1 ? 'day logged' : 'days logged',
        iconName: 'local_fire_department',
        color: const Color(0xFFFF6F00),
        progress: (_calorieStreak / 7).clamp(0.0, 1.0),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CustomIconWidget(
                    iconName: 'bar_chart',
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                ),
                SizedBox(width: 3.w),
                Text(
                  'This Week',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            // 2×2 grid
            Row(
              children: [
                Expanded(child: _buildStatCard(theme, stats[0], 0)),
                SizedBox(width: 3.w),
                Expanded(child: _buildStatCard(theme, stats[1], 1)),
              ],
            ),
            SizedBox(height: 2.w),
            Row(
              children: [
                Expanded(child: _buildStatCard(theme, stats[2], 2)),
                SizedBox(width: 3.w),
                Expanded(child: _buildStatCard(theme, stats[3], 3)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(ThemeData theme, _StatData stat, int index) {
    // Staggered entrance per card
    final delay = index * 0.15;
    final begin = delay;
    final end = (delay + 0.55).clamp(0.0, 1.0);

    return AnimatedBuilder(
      animation: _staggerCtrl,
      builder: (_, child) {
        final t = _staggerCtrl.value;
        final localT = ((t - begin) / (end - begin)).clamp(0.0, 1.0);
        final curve = Curves.easeOutCubic.transform(localT);
        return Opacity(
          opacity: curve,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - curve)),
            child: child,
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(3.5.w),
        decoration: BoxDecoration(
          color: stat.color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: stat.color.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CustomIconWidget(
                  iconName: stat.iconName,
                  color: stat.color,
                  size: 16,
                ),
                const Spacer(),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: stat.progress),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOut,
                  builder: (_, val, __) => Text(
                    '${(val * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w600,
                      color: stat.color.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              stat.value,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: stat.color,
                height: 1,
              ),
            ),
            SizedBox(height: 0.3.h),
            Text(
              stat.label,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              stat.sub,
              style: TextStyle(
                fontSize: 8.5.sp,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 1.h),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: stat.progress),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOut,
              builder: (_, val, __) => ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: val,
                  minHeight: 4,
                  backgroundColor:
                      stat.color.withValues(alpha: 0.12),
                  valueColor:
                      AlwaysStoppedAnimation(stat.color),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatData {
  final String label;
  final String value;
  final String sub;
  final String iconName;
  final Color color;
  final double progress;

  const _StatData({
    required this.label,
    required this.value,
    required this.sub,
    required this.iconName,
    required this.color,
    required this.progress,
  });
}
