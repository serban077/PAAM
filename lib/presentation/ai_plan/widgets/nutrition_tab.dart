import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../data/models/ai_plan_models.dart';
import 'calorie_summary_card.dart';
import 'meal_card.dart';
import 'food_search_dialog.dart';

class NutritionTab extends StatelessWidget {
  final NutritionPlan nutritionPlan;
  final List<LoggedFood> loggedFoods;
  final int totalCaloriesEaten;
  final Function(MealOption) onLogMealOption;
  final Function(LoggedFood) onLogFood;

  const NutritionTab({
    super.key,
    required this.nutritionPlan,
    required this.loggedFoods,
    required this.totalCaloriesEaten,
    required this.onLogMealOption,
    required this.onLogFood,
  });

  void _showFoodSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => FoodSearchDialog(
        onLogFood: onLogFood,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Calorie summary at the top
        CalorieSummaryCard(
          dailyGoal: nutritionPlan.dailyCaloriesGoal,
          caloriesEaten: totalCaloriesEaten,
        ),
        
        // Manual food logging button
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.h, vertical: 1.h),
          child: ElevatedButton.icon(
            onPressed: () => _showFoodSearchDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Log Food Manually'),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        
        // Meals list
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 2.h),
            itemCount: nutritionPlan.meals.length,
            itemBuilder: (context, index) {
              return MealCard(
                meal: nutritionPlan.meals[index],
                onLogMealOption: onLogMealOption,
              );
            },
          ),
        ),
      ],
    );
  }
}
