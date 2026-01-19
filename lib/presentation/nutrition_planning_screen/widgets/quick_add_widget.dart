import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Widget for quick-add common Romanian foods
class QuickAddWidget extends StatelessWidget {
  final Function(Map<String, dynamic>) onFoodSelected;

  const QuickAddWidget({super.key, required this.onFoodSelected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<Map<String, dynamic>> quickFoods = [
      {
        "name": "Apă (250ml)",
        "icon": "water_drop",
        "calories": 0.0,
        "protein": 0.0,
        "carbs": 0.0,
        "fats": 0.0,
      },
      {
        "name": "Cafea neagră",
        "icon": "coffee",
        "calories": 2.0,
        "protein": 0.0,
        "carbs": 0.0,
        "fats": 0.0,
      },
      {
        "name": "Banană",
        "icon": "emoji_food_beverage",
        "calories": 105.0,
        "protein": 1.0,
        "carbs": 27.0,
        "fats": 0.0,
      },
      {
        "name": "Ou fiert",
        "icon": "egg",
        "calories": 70.0,
        "protein": 6.0,
        "carbs": 1.0,
        "fats": 5.0,
      },
      {
        "name": "Pâine (1 felie)",
        "icon": "bakery_dining",
        "calories": 70.0,
        "protein": 3.0,
        "carbs": 12.0,
        "fats": 1.0,
      },
      {
        "name": "Lapte (200ml)",
        "icon": "local_drink",
        "calories": 120.0,
        "protein": 6.0,
        "carbs": 12.0,
        "fats": 5.0,
      },
    ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.w),
            child: Text(
              'Adăugare Rapidă',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(height: 1.h),
          SizedBox(
            height: 12.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: quickFoods.length,
              separatorBuilder: (context, index) => SizedBox(width: 2.w),
              itemBuilder: (context, index) {
                final food = quickFoods[index];
                return InkWell(
                  onTap: () => onFoodSelected(food),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 28.w,
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(2.w),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: CustomIconWidget(
                            iconName: food["icon"],
                            size: 24,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          food["name"],
                          style: theme.textTheme.bodySmall,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (food["calories"] > 0) ...[
                          SizedBox(height: 0.5.h),
                          Text(
                            '${food["calories"].toStringAsFixed(0)} kcal',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
