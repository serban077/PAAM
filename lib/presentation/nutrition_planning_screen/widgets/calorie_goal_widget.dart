import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:percent_indicator/percent_indicator.dart';

/// Widget displaying daily caloric goal with circular progress indicator
class CalorieGoalWidget extends StatelessWidget {
  final double dailyGoal;
  final double consumed;

  const CalorieGoalWidget({
    super.key,
    required this.dailyGoal,
    required this.consumed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = dailyGoal - consumed;
    final percentage = (consumed / dailyGoal).clamp(0.0, 1.0);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Obiectiv Zilnic',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 2.h),
          CircularPercentIndicator(
            radius: 25.w,
            lineWidth: 3.w,
            percent: percentage,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  consumed.toStringAsFixed(0),
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  'din ${dailyGoal.toStringAsFixed(0)} kcal',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            progressColor: percentage > 1.0
                ? theme.colorScheme.error
                : theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.primaryContainer.withValues(
              alpha: 0.3,
            ),
            circularStrokeCap: CircularStrokeCap.round,
            animation: true,
            animationDuration: 1000,
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn(
                'Consumate',
                consumed.toStringAsFixed(0),
                theme.colorScheme.primary,
                theme,
              ),
              Container(
                width: 1,
                height: 5.h,
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
              _buildStatColumn(
                remaining >= 0 ? 'Rămase' : 'Peste',
                remaining.abs().toStringAsFixed(0),
                remaining >= 0
                    ? theme.colorScheme.secondary
                    : theme.colorScheme.error,
                theme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(
    String label,
    String value,
    Color color,
    ThemeData theme,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
