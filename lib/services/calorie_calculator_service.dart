import 'dart:math';

/// Service for calculating calorie and macronutrient goals based on user profile
class CalorieCalculatorService {
  /// Calculate BMR (Basal Metabolic Rate) using Mifflin-St Jeor equation
  /// 
  /// Formula:
  /// - Men: BMR = (10 × weight_kg) + (6.25 × height_cm) - (5 × age) + 5
  /// - Women: BMR = (10 × weight_kg) + (6.25 × height_cm) - (5 × age) - 161
  static double calculateBMR({
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender,
  }) {
    final baseCalculation = (10 * weightKg) + (6.25 * heightCm) - (5 * age);
    
    if (gender.toLowerCase() == 'masculin' || gender.toLowerCase() == 'male' || gender.toLowerCase() == 'm') {
      return baseCalculation + 5;
    } else {
      return baseCalculation - 161;
    }
  }

  /// Calculate TDEE (Total Daily Energy Expenditure) based on activity level
  /// 
  /// Activity multipliers:
  /// - 0-1 days: 1.2 (Sedentary)
  /// - 2-3 days: 1.375 (Lightly active)
  /// - 4-5 days: 1.55 (Moderately active)
  /// - 6-7 days: 1.725 (Very active)
  static double calculateTDEE({
    required double bmr,
    required int weeklyTrainingFrequency,
  }) {
    double activityMultiplier;
    
    if (weeklyTrainingFrequency <= 1) {
      activityMultiplier = 1.2; // Sedentary
    } else if (weeklyTrainingFrequency <= 3) {
      activityMultiplier = 1.375; // Lightly active
    } else if (weeklyTrainingFrequency <= 5) {
      activityMultiplier = 1.55; // Moderately active
    } else {
      activityMultiplier = 1.725; // Very active
    }
    
    return bmr * activityMultiplier;
  }

  /// Calculate daily calorie goal based on fitness goal
  /// 
  /// Adjustments:
  /// - Weight loss: TDEE - 500 (moderate deficit)
  /// - Maintenance: TDEE
  /// - Muscle gain: TDEE + 300 (moderate surplus)
  static int calculateDailyCalorieGoal({
    required double tdee,
    required String fitnessGoal,
  }) {
    final goalLower = fitnessGoal.toLowerCase();
    
    if (goalLower.contains('pierdere') || goalLower.contains('slabire') || goalLower.contains('loss')) {
      return (tdee - 500).round(); // Moderate deficit for weight loss
    } else if (goalLower.contains('crestere') || goalLower.contains('masa') || goalLower.contains('bulk') || goalLower.contains('gain')) {
      return (tdee + 300).round(); // Moderate surplus for muscle gain
    } else {
      return tdee.round(); // Maintenance
    }
  }

  /// Calculate daily calorie goal based on target weight and timeframe
  /// 
  /// Uses deadline-based calculation:
  /// - Calculates required weekly weight change
  /// - Converts to daily calorie deficit/surplus
  /// - 1 kg body weight ≈ 7700 kcal
  /// 
  /// Example: 80kg → 75kg in 12 weeks
  /// - Weekly change: (80-75)/12 = 0.42 kg/week
  /// - Weekly calories: 0.42 * 7700 = 3234 kcal
  /// - Daily deficit: 3234/7 = 462 kcal/day
  /// - Target: TDEE - 462 kcal
  static int calculateDailyCalorieGoalWithDeadline({
    required double tdee,
    required double currentWeightKg,
    required double targetWeightKg,
    required int targetTimeframeWeeks,
  }) {
    // Calculate weight difference (positive = losing, negative = gaining)
    final weightDifference = currentWeightKg - targetWeightKg;
    
    // If no meaningful difference or invalid timeframe, use TDEE
    if (weightDifference.abs() < 0.5 || targetTimeframeWeeks <= 0) {
      return tdee.round();
    }
    
    // Calculate required weekly weight change
    final weeklyWeightChange = weightDifference / targetTimeframeWeeks;
    
    // 1 kg of body weight ≈ 7700 kcal
    // Weekly calorie deficit/surplus = weeklyWeightChange * 7700
    final weeklyCalorieChange = weeklyWeightChange * 7700;
    
    // Daily calorie deficit/surplus
    final dailyCalorieChange = weeklyCalorieChange / 7;
    
    // Calculate target calories
    // If losing weight (positive difference): TDEE - deficit
    // If gaining weight (negative difference): TDEE + surplus
    final targetCalories = (tdee - dailyCalorieChange).round();
    
    // Safety checks
    if (weightDifference > 0) {
      // Losing weight - ensure minimum 1200 kcal
      return max(1200, targetCalories);
    } else {
      // Gaining weight - ensure not too aggressive (max +500 kcal/day)
      final maxSurplus = tdee + 500;
      return min(maxSurplus.toInt(), targetCalories);
    }
  }

  /// Calculate macronutrient targets (protein, carbs, fat)
  /// 
  /// Guidelines:
  /// - Protein: 1.8-2.2g per kg body weight (higher for weight loss)
  /// - Fat: 25% of total calories
  /// - Carbs: Remaining calories
  static Map<String, double> calculateMacros({
    required int dailyCalories,
    required double weightKg,
    required String fitnessGoal,
  }) {
    final goalLower = fitnessGoal.toLowerCase();
    
    // Protein calculation based on goal
    double proteinG;
    if (goalLower.contains('pierdere') || goalLower.contains('slabire') || goalLower.contains('loss')) {
      proteinG = weightKg * 2.2; // Higher protein for muscle preservation during weight loss
    } else if (goalLower.contains('crestere') || goalLower.contains('masa') || goalLower.contains('bulk') || goalLower.contains('gain')) {
      proteinG = weightKg * 2.0; // Moderate-high protein for muscle gain
    } else {
      proteinG = weightKg * 1.8; // Maintenance
    }

    // Fat: 25% of total calories (9 calories per gram)
    final fatG = (dailyCalories * 0.25) / 9;

    // Carbs: Remaining calories (4 calories per gram)
    final proteinCalories = proteinG * 4;
    final fatCalories = fatG * 9;
    final remainingCalories = dailyCalories - proteinCalories - fatCalories;
    final carbsG = max(0, remainingCalories / 4); // Ensure non-negative

    return {
      'protein_g': proteinG,
      'carbs_g': carbsG.toDouble(),
      'fat_g': fatG,
    };
  }

  /// Complete calculation - returns all nutrition goals
  /// 
  /// Returns a map with:
  /// - bmr: Basal Metabolic Rate
  /// - tdee: Total Daily Energy Expenditure
  /// - daily_calorie_goal: Target calories based on goal
  /// - protein_goal_g: Daily protein target
  /// - carbs_goal_g: Daily carbs target
  /// - fat_goal_g: Daily fat target
  /// 
  /// Optional deadline-based calculation:
  /// - If targetWeightKg and targetTimeframeWeeks provided, uses deadline calculation
  /// - Otherwise uses standard goal-based calculation
  static Map<String, dynamic> calculateNutritionGoals({
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender,
    required int weeklyTrainingFrequency,
    required String fitnessGoal,
    double? targetWeightKg, // Optional: target weight for deadline calculation
    int? targetTimeframeWeeks, // Optional: timeframe for deadline calculation
  }) {
    // Step 1: Calculate BMR
    final bmr = calculateBMR(
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
      gender: gender,
    );

    // Step 2: Calculate TDEE
    final tdee = calculateTDEE(
      bmr: bmr,
      weeklyTrainingFrequency: weeklyTrainingFrequency,
    );

    // Step 3: Calculate daily calorie goal
    int dailyCalories;
    
    // Use deadline-based calculation if target weight and timeframe provided
    if (targetWeightKg != null && targetTimeframeWeeks != null && targetTimeframeWeeks > 0) {
      dailyCalories = calculateDailyCalorieGoalWithDeadline(
        tdee: tdee,
        currentWeightKg: weightKg,
        targetWeightKg: targetWeightKg,
        targetTimeframeWeeks: targetTimeframeWeeks,
      );
    } else {
      // Fallback to standard goal-based calculation
      dailyCalories = calculateDailyCalorieGoal(
        tdee: tdee,
        fitnessGoal: fitnessGoal,
      );
    }

    // Step 4: Calculate macros
    final macros = calculateMacros(
      dailyCalories: dailyCalories,
      weightKg: weightKg,
      fitnessGoal: fitnessGoal,
    );

    return {
      'bmr': bmr.round(),
      'tdee': tdee.round(),
      'daily_calorie_goal': dailyCalories,
      'protein_goal_g': macros['protein_g']!.round(),
      'carbs_goal_g': macros['carbs_g']!.round(),
      'fat_goal_g': macros['fat_g']!.round(),
    };
  }
}
