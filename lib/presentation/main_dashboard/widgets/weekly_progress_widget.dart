import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/supabase_service.dart';

class WeeklyProgressWidget extends StatefulWidget {
  const WeeklyProgressWidget({super.key});

  @override
  State<WeeklyProgressWidget> createState() => _WeeklyProgressWidgetState();
}

class _WeeklyProgressWidgetState extends State<WeeklyProgressWidget> {
  bool _isLoading = true;
  List<int> _scheduledDays = []; // List of day numbers (1=Mon, 7=Sun)
  
  @override
  void initState() {
    super.initState();
    _loadScheduledDays();
  }

  Future<void> _loadScheduledDays() async {
    try {
      setState(() => _isLoading = true);
      
      final userId = SupabaseService.instance.client.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Get active workout schedule
      final scheduleResponse = await SupabaseService.instance.client
          .from('user_workout_schedules')
          .select('plan_id')
          .eq('user_id', userId)
          .eq('is_active', true)
          .maybeSingle();

      if (scheduleResponse == null) {
        if (mounted) {
          setState(() {
            _scheduledDays = [];
            _isLoading = false;
          });
        }
        return;
      }

      final planId = scheduleResponse['plan_id'];

      // Get all workout sessions for this plan
      final sessionsResponse = await SupabaseService.instance.client
          .from('workout_sessions')
          .select('day_number, day_of_week')
          .eq('plan_id', planId);

      final days = <int>{};
      for (var session in sessionsResponse) {
        // Try day_number first, fallback to day_of_week
        final dayNum = session['day_number'] ?? session['day_of_week'];
        if (dayNum != null) {
          days.add(dayNum as int);
        }
      }

      if (mounted) {
        setState(() {
          _scheduledDays = days.toList()..sort();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading scheduled days: $e');
      if (mounted) {
        setState(() {
          _scheduledDays = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Generate weekly data based on scheduled days
    final dayNames = ["L", "M", "M", "J", "V", "S", "D"];
    final List<Map<String, dynamic>> weeklyData = List.generate(7, (index) {
      final dayNumber = index + 1;
      return {
        "day": dayNames[index],
        "workouts": _scheduledDays.contains(dayNumber) ? 1 : 0,
      };
    });

    final completedWorkouts = _scheduledDays.length;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Activitate Săptămână', style: theme.textTheme.titleMedium),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: AppTheme.successLight.withAlpha(25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'local_fire_department',
                      color: AppTheme.successLight,
                      size: 16,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      '$completedWorkouts/7 zile',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.successLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),

          // Weekly chart
          SizedBox(
            height: 20.h,
            child: Semantics(
              label: "Grafic activitate săptămânală cu antrenamente programate",
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 2,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < weeklyData.length) {
                            return Padding(
                              padding: EdgeInsets.only(top: 1.h),
                              child: Text(
                                weeklyData[value.toInt()]["day"] as String,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(
                    weeklyData.length,
                    (index) => BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: (weeklyData[index]["workouts"] as int)
                              .toDouble(),
                          color: weeklyData[index]["workouts"] > 0
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline.withAlpha(76),
                          width: 8.w,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: 2.h),

          // Weekly summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                context,
                'Zile Programate',
                '$completedWorkouts',
                'fitness_center',
                theme.colorScheme.primary,
              ),
              Container(
                width: 1,
                height: 6.h,
                color: theme.colorScheme.outline.withAlpha(51),
              ),
              _buildSummaryItem(
                context,
                'Zile Odihnă',
                '${7 - completedWorkouts}',
                'hotel',
                theme.colorScheme.secondary,
              ),
              Container(
                width: 1,
                height: 6.h,
                color: theme.colorScheme.outline.withAlpha(51),
              ),
              _buildSummaryItem(
                context,
                'Frecvență',
                '${(completedWorkouts / 7 * 100).toInt()}%',
                'local_fire_department',
                theme.colorScheme.tertiary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String value,
    String icon,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: CustomIconWidget(iconName: icon, color: color, size: 20),
        ),
        SizedBox(height: 1.h),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
