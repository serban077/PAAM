import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class MealSectionWidget extends StatelessWidget {
  final String title;
  final String mealType;
  final List<Map<String, dynamic>> meals;
  final VoidCallback onAddFood;
  final Function(String) onDeleteMeal;

  const MealSectionWidget({
    super.key,
    required this.title,
    required this.mealType,
    required this.meals,
    required this.onAddFood,
    required this.onDeleteMeal,
  });

  int _calculateTotalCalories() {
    return meals.fold(0, (sum, meal) {
      final food = meal['food_database'] as Map<String, dynamic>?;
      if (food == null) return sum;

      final calories = food['calories'] ?? 0;
      final servingQuantity = meal['serving_quantity'] ?? 1.0;
      final servingSize = food['serving_size'] ?? 100.0;

      return sum + ((calories * servingQuantity * servingSize / 100).round()) as int;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalCalories = _calculateTotalCalories();

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (meals.isNotEmpty)
                      Text(
                        '$totalCalories kcal',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.add_circle, size: 24.sp),
                  color: Theme.of(context).primaryColor,
                  onPressed: onAddFood,
                ),
              ],
            ),
            if (meals.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 2.h),
                child: Center(
                  child: Text(
                    'Niciun aliment adăugat',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
              )
            else
              ...meals.map((meal) {
                final food = meal['food_database'] as Map<String, dynamic>?;
                if (food == null) return const SizedBox.shrink();

                final servingQuantity = meal['serving_quantity'] ?? 1.0;
                final servingSize = food['serving_size'] ?? 100.0;
                final multiplier = (servingQuantity * servingSize) / 100.0;

                final calories = (food['calories'] * multiplier).round();
                final protein = (food['protein_g'] * multiplier)
                    .toStringAsFixed(1);
                final carbs = (food['carbs_g'] * multiplier).toStringAsFixed(1);
                final fat = (food['fat_g'] * multiplier).toStringAsFixed(1);

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    food['name'] ?? 'Aliment necunoscut',
                    style: TextStyle(fontSize: 14.sp),
                  ),
                  subtitle: Text(
                    '$calories kcal | P: ${protein}g C: ${carbs}g F: ${fat}g\n${servingQuantity.toStringAsFixed(1)} x ${servingSize.toStringAsFixed(0)}${food['serving_unit']}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, size: 18.sp),
                    color: Colors.red,
                    onPressed: () => onDeleteMeal(meal['id']),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}