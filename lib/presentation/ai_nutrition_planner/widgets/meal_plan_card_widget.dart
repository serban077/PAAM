import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class MealPlanCardWidget extends StatelessWidget {
  final Map<String, dynamic> meal;

  const MealPlanCardWidget({super.key, required this.meal});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foods = meal['foods'] as List? ?? [];

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _getMealIcon(meal['mealType'] ?? ''),
                      color: theme.colorScheme.primary,
                      size: 6.w,
                    ),
                    SizedBox(width: 2.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meal['mealType'] ?? '',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (meal['time'] != null)
                          Text(
                            meal['time'],
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withAlpha(153),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(26),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    '${meal['totalCalories']} kcal',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Divider(),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: foods.length,
              itemBuilder: (context, index) {
                final food = foods[index] as Map<String, dynamic>;
                return _buildFoodItem(theme, food);
              },
            ),
            if (meal['tips'] != null) ...[
              SizedBox(height: 1.h),
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 4.w,
                      color: theme.colorScheme.secondary,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        meal['tips'],
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFoodItem(ThemeData theme, Map<String, dynamic> food) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            food['name'] ?? '',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 0.5.h),
          Row(
            children: [
              _buildNutrientChip(
                theme,
                '${food['calories']} kcal',
                theme.colorScheme.primary,
              ),
              SizedBox(width: 2.w),
              _buildNutrientChip(
                theme,
                'P: ${food['protein']}',
                theme.colorScheme.error,
              ),
              SizedBox(width: 2.w),
              _buildNutrientChip(
                theme,
                'C: ${food['carbs']}',
                theme.colorScheme.primary,
              ),
              SizedBox(width: 2.w),
              _buildNutrientChip(
                theme,
                'G: ${food['fats']}',
                theme.colorScheme.secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientChip(ThemeData theme, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  IconData _getMealIcon(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'mic dejun':
        return Icons.free_breakfast;
      case 'gustare dimineata':
      case 'gustare dupa amiaza':
      case 'gustare seara':
        return Icons.restaurant;
      case 'pranz':
        return Icons.lunch_dining;
      case 'cina':
        return Icons.dinner_dining;
      default:
        return Icons.restaurant_menu;
    }
  }
}
