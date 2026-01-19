import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:fl_chart/fl_chart.dart';

/// Workout analytics widget with completion rates and strength progression
class WorkoutAnalyticsWidget extends StatefulWidget {
  const WorkoutAnalyticsWidget({super.key});

  @override
  State<WorkoutAnalyticsWidget> createState() => _WorkoutAnalyticsWidgetState();
}

class _WorkoutAnalyticsWidgetState extends State<WorkoutAnalyticsWidget> {
  String _selectedPeriod = 'Lună';
  final List<String> _periods = ['Săptămână', 'Lună', '3 Luni'];

  // Mock workout data
  final Map<String, dynamic> _workoutStats = {
    "totalWorkouts": 24,
    "completionRate": 85.7,
    "averageDuration": 52,
    "caloriesBurned": 8640,
    "currentStreak": 5,
    "longestStreak": 12,
  };

  final List<Map<String, dynamic>> _weeklyWorkouts = [
    {"day": "L", "completed": 1, "total": 1},
    {"day": "M", "completed": 1, "total": 1},
    {"day": "M", "completed": 0, "total": 1},
    {"day": "J", "completed": 1, "total": 1},
    {"day": "V", "completed": 1, "total": 1},
    {"day": "S", "completed": 1, "total": 1},
    {"day": "D", "completed": 0, "total": 1},
  ];

  final List<Map<String, dynamic>> _strengthProgress = [
    {"exercise": "Genuflexiuni", "weight": 80.0, "change": 10.0},
    {"exercise": "Bench Press", "weight": 70.0, "change": 5.0},
    {"exercise": "Deadlift", "weight": 100.0, "change": 15.0},
    {"exercise": "Overhead Press", "weight": 45.0, "change": 5.0},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats overview
            _buildStatsOverview(theme),
            SizedBox(height: 3.h),
            // Period selector
            _buildPeriodSelector(theme),
            SizedBox(height: 3.h),
            // Weekly completion chart
            _buildWeeklyCompletionChart(theme),
            SizedBox(height: 3.h),
            // Strength progression
            _buildStrengthProgression(theme),
            SizedBox(height: 3.h),
            // Achievement badges
            _buildAchievementBadges(theme),
            SizedBox(height: 10.h),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsOverview(ThemeData theme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                theme,
                'Antrenamente',
                '${_workoutStats["totalWorkouts"]}',
                Icons.fitness_center,
                theme.colorScheme.primary,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _buildStatCard(
                theme,
                'Rată Finalizare',
                '${_workoutStats["completionRate"]}%',
                Icons.check_circle,
                theme.colorScheme.tertiary,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                theme,
                'Durată Medie',
                '${_workoutStats["averageDuration"]} min',
                Icons.timer,
                theme.colorScheme.secondary,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _buildStatCard(
                theme,
                'Calorii Arse',
                '${_workoutStats["caloriesBurned"]}',
                Icons.local_fire_department,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(height: 1.h),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(ThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _periods.map((period) {
          final isSelected = period == _selectedPeriod;
          return Padding(
            padding: EdgeInsets.only(right: 2.w),
            child: ChoiceChip(
              label: Text(period),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedPeriod = period;
                  });
                }
              },
              selectedColor: theme.colorScheme.primary,
              backgroundColor: theme.colorScheme.surface,
              labelStyle: theme.textTheme.titleSmall?.copyWith(
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              side: BorderSide(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWeeklyCompletionChart(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Finalizare Săptămânală',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            height: 25.h,
            child: Semantics(
              label: "Grafic bare finalizare antrenamente săptămânale",
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 1,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < _weeklyWorkouts.length) {
                            return Padding(
                              padding: EdgeInsets.only(top: 1.h),
                              child: Text(
                                _weeklyWorkouts[index]["day"] as String,
                                style: theme.textTheme.bodySmall,
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
                  barGroups: _weeklyWorkouts.asMap().entries.map((entry) {
                    final index = entry.key;
                    final workout = entry.value;
                    final completed = (workout["completed"] as num).toInt();
                    final isCompleted = completed > 0;

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: 1,
                          color: isCompleted
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline.withValues(
                                  alpha: 0.3,
                                ),
                          width: 8.w,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(theme, 'Finalizat', theme.colorScheme.primary),
              SizedBox(width: 4.w),
              _buildLegendItem(
                theme,
                'Nefinalizat',
                theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(ThemeData theme, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        SizedBox(width: 1.w),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }

  Widget _buildStrengthProgression(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progres Forță',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          ..._strengthProgress.map((exercise) {
            final name = exercise["exercise"] as String;
            final weight = (exercise["weight"] as num).toDouble();
            final change = (exercise["change"] as num).toDouble();

            return Padding(
              padding: EdgeInsets.only(bottom: 2.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '${weight.toStringAsFixed(0)} kg',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 2.w,
                              vertical: 0.5.h,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.tertiary.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.trending_up,
                                  color: theme.colorScheme.tertiary,
                                  size: 14,
                                ),
                                SizedBox(width: 1.w),
                                Text(
                                  '+${change.toStringAsFixed(0)} kg',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.tertiary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (weight / 120),
                      minHeight: 8,
                      backgroundColor: theme.colorScheme.outline.withValues(
                        alpha: 0.2,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAchievementBadges(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.1),
            theme.colorScheme.secondary.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Text(
                'Realizări',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBadge(
                theme,
                Icons.local_fire_department,
                '${_workoutStats["currentStreak"]}',
                'Zile Consecutive',
                Colors.orange,
              ),
              _buildBadge(
                theme,
                Icons.star,
                '${_workoutStats["longestStreak"]}',
                'Record Zile',
                Colors.amber,
              ),
              _buildBadge(
                theme,
                Icons.trending_up,
                '${_workoutStats["totalWorkouts"]}',
                'Total Antrenamente',
                theme.colorScheme.tertiary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(
    ThemeData theme,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 30),
        ),
        SizedBox(height: 1.h),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
