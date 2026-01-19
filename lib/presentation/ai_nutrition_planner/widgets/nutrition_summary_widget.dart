import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class NutritionSummaryWidget extends StatelessWidget {
  final int dailyCalories;
  final Map<String, dynamic> macros;

  const NutritionSummaryWidget({
    super.key,
    required this.dailyCalories,
    required this.macros,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Obiectiv Caloric Zilnic',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(26),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    '$dailyCalories kcal',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Divider(),
            SizedBox(height: 1.h),
            Text(
              'Distribuție Macronutrienți',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.h),
            _buildMacroRow(
              theme,
              'Proteine',
              macros['protein'] ?? '',
              theme.colorScheme.error,
            ),
            _buildMacroRow(
              theme,
              'Carbohidrați',
              macros['carbs'] ?? '',
              theme.colorScheme.primary,
            ),
            _buildMacroRow(
              theme,
              'Grăsimi',
              macros['fats'] ?? '',
              theme.colorScheme.secondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroRow(
    ThemeData theme,
    String label,
    String value,
    Color color,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 3.w,
                height: 3.w,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              SizedBox(width: 2.w),
              Text(label, style: theme.textTheme.bodyMedium),
            ],
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
