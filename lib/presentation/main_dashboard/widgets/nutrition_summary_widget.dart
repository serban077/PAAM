import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class NutritionSummaryWidget extends StatelessWidget {
  final int consumedCalories;
  final int targetCalories;
  final int proteinG;
  final int carbsG;
  final int fatsG;

  const NutritionSummaryWidget({
    super.key,
    required this.consumedCalories,
    required this.targetCalories,
    required this.proteinG,
    required this.carbsG,
    required this.fatsG,
  });

  /// Derive macro targets from calorie goal (30% protein, 45% carbs, 25% fat)
  int get _targetProteinG => ((targetCalories * 0.30) / 4).round();
  int get _targetCarbsG => ((targetCalories * 0.45) / 4).round();
  int get _targetFatsG => ((targetCalories * 0.25) / 9).round();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final double calorieProgress =
        targetCalories > 0 ? consumedCalories / targetCalories : 0;

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
        children: [
          // Calorie progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Calories Today', style: theme.textTheme.titleMedium),
              Text(
                '$consumedCalories / $targetCalories kcal',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: calorieProgress.clamp(0.0, 1.0),
              minHeight: 1.h,
              backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                calorieProgress < 0.9
                    ? theme.colorScheme.primary
                    : calorieProgress < 1.0
                    ? AppTheme.successLight
                    : AppTheme.warningLight,
              ),
            ),
          ),
          SizedBox(height: 3.h),

          // Macro breakdown
          Text(
            'Macronutrients',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 1.5.h),

          _buildMacroRow(
            context,
            'Protein',
            proteinG,
            _targetProteinG,
            'g',
            theme.colorScheme.tertiary,
          ),
          SizedBox(height: 1.5.h),

          _buildMacroRow(
            context,
            'Carbohydrates',
            carbsG,
            _targetCarbsG,
            'g',
            theme.colorScheme.secondary,
          ),
          SizedBox(height: 1.5.h),

          _buildMacroRow(
            context,
            'Fats',
            fatsG,
            _targetFatsG,
            'g',
            AppTheme.warningLight,
          ),
        ],
      ),
    );
  }

  Widget _buildMacroRow(
    BuildContext context,
    String label,
    int consumed,
    int target,
    String unit,
    Color color,
  ) {
    final theme = Theme.of(context);
    final double progress = target > 0 ? consumed / target : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.bodyMedium),
            Text(
              '$consumed / $target $unit',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        SizedBox(height: 0.5.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress > 1.0 ? 1.0 : progress,
            minHeight: 0.8.h,
            backgroundColor: color.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
