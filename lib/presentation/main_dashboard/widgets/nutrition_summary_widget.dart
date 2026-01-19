import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class NutritionSummaryWidget extends StatelessWidget {
  const NutritionSummaryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Mock nutrition data
    final Map<String, dynamic> nutritionData = {
      "targetCalories": 2100,
      "consumedCalories": 1650,
      "protein": {"consumed": 120, "target": 150, "unit": "g"},
      "carbs": {"consumed": 180, "target": 230, "unit": "g"},
      "fats": {"consumed": 55, "target": 70, "unit": "g"},
    };

    final double calorieProgress =
        (nutritionData["consumedCalories"] as int) /
        (nutritionData["targetCalories"] as int);

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
              Text('Calorii Astăzi', style: theme.textTheme.titleMedium),
              Text(
                '${nutritionData["consumedCalories"]} / ${nutritionData["targetCalories"]} kcal',
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
              value: calorieProgress,
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
            'Macronutrienți',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 1.5.h),

          _buildMacroRow(
            context,
            'Proteine',
            nutritionData["protein"]["consumed"] as int,
            nutritionData["protein"]["target"] as int,
            nutritionData["protein"]["unit"] as String,
            theme.colorScheme.tertiary,
          ),
          SizedBox(height: 1.5.h),

          _buildMacroRow(
            context,
            'Carbohidrați',
            nutritionData["carbs"]["consumed"] as int,
            nutritionData["carbs"]["target"] as int,
            nutritionData["carbs"]["unit"] as String,
            theme.colorScheme.secondary,
          ),
          SizedBox(height: 1.5.h),

          _buildMacroRow(
            context,
            'Grăsimi',
            nutritionData["fats"]["consumed"] as int,
            nutritionData["fats"]["target"] as int,
            nutritionData["fats"]["unit"] as String,
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
    final double progress = consumed / target;

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
