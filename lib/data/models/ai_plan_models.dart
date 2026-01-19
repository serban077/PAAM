class AIPlanResponse {
  final TrainingPlan trainingPlan;
  final NutritionPlan nutritionPlan;
  final String notes;

  AIPlanResponse({
    required this.trainingPlan,
    required this.nutritionPlan,
    required this.notes,
  });

  factory AIPlanResponse.fromJson(Map<String, dynamic> json) {
    return AIPlanResponse(
      trainingPlan: TrainingPlan.fromJson(json['training_plan']),
      nutritionPlan: NutritionPlan.fromJson(json['nutrition_plan']),
      notes: json['notes'] ?? '',
    );
  }
}

class TrainingPlan {
  final Map<String, List<Exercise>> days;

  TrainingPlan({required this.days});

  factory TrainingPlan.fromJson(Map<String, dynamic> json) {
    Map<String, List<Exercise>> days = {};
    json.forEach((key, value) {
      days[key] = (value as List)
          .map((e) => Exercise.fromJson(e))
          .toList();
    });
    return TrainingPlan(days: days);
  }
}

class Exercise {
  final String exerciseName;
  final int sets;
  final String reps;
  final int restSeconds;
  final String videoUrl;

  Exercise({
    required this.exerciseName,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    required this.videoUrl,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      exerciseName: json['exercise_name'],
      sets: json['sets'],
      reps: json['reps'].toString(),
      restSeconds: json['rest_seconds'],
      videoUrl: json['video_url'],
    );
  }
}

class NutritionPlan {
  final int dailyCaloriesGoal;
  final List<Meal> meals;

  NutritionPlan({
    required this.dailyCaloriesGoal,
    required this.meals,
  });

  factory NutritionPlan.fromJson(Map<String, dynamic> json) {
    return NutritionPlan(
      dailyCaloriesGoal: json['daily_calories_goal'],
      meals: (json['meals'] as List)
          .map((e) => Meal.fromJson(e))
          .toList(),
    );
  }
}

class Meal {
  final String mealName;
  final List<MealOption> options;

  Meal({
    required this.mealName,
    required this.options,
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      mealName: json['meal_name'],
      options: (json['options'] as List)
          .map((e) => MealOption.fromJson(e))
          .toList(),
    );
  }
}

class MealOption {
  final int optionId;
  final String description;
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatG;

  MealOption({
    required this.optionId,
    required this.description,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  factory MealOption.fromJson(Map<String, dynamic> json) {
    return MealOption(
      optionId: json['option_id'],
      description: json['description'],
      calories: json['calories'],
      proteinG: json['protein_g'],
      carbsG: json['carbs_g'],
      fatG: json['fat_g'],
    );
  }
}

class FoodItem {
  final String id;
  final String name;
  final int caloriesPer100g;
  final int proteinPer100g;
  final int carbsPer100g;
  final int fatPer100g;

  FoodItem({
    required this.id,
    required this.name,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'].toString(),
      name: json['name'],
      caloriesPer100g: json['calories_per_100g'],
      proteinPer100g: json['protein_per_100g'] ?? 0,
      carbsPer100g: json['carbs_per_100g'] ?? 0,
      fatPer100g: json['fat_per_100g'] ?? 0,
    );
  }
}

class LoggedFood {
  final String foodName;
  final int grams;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final DateTime timestamp;

  LoggedFood({
    required this.foodName,
    required this.grams,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.timestamp,
  });
}
