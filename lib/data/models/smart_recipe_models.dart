// Data models for M18 — Smart Photo-to-Recipe Generator.
// Used by FoodRecognitionService and SmartRecipeService.

class DetectedIngredient {
  final String name;
  final double estimatedQuantityG;
  final String category; // protein, carb, fat, vegetable, fruit, dairy, condiment

  const DetectedIngredient({
    required this.name,
    required this.estimatedQuantityG,
    required this.category,
  });

  factory DetectedIngredient.fromMap(Map<String, dynamic> map) {
    return DetectedIngredient(
      name: map['name'] as String? ?? '',
      estimatedQuantityG:
          (map['estimated_quantity_g'] as num?)?.toDouble() ?? 0.0,
      category: map['category'] as String? ?? 'other',
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'estimated_quantity_g': estimatedQuantityG,
        'category': category,
      };

  DetectedIngredient copyWith({
    String? name,
    double? estimatedQuantityG,
    String? category,
  }) {
    return DetectedIngredient(
      name: name ?? this.name,
      estimatedQuantityG: estimatedQuantityG ?? this.estimatedQuantityG,
      category: category ?? this.category,
    );
  }
}

class FoodRecognitionResult {
  final List<DetectedIngredient> ingredients;
  final String? rawResponse;

  const FoodRecognitionResult({
    required this.ingredients,
    this.rawResponse,
  });

  factory FoodRecognitionResult.fromMap(Map<String, dynamic> map) {
    final items = map['ingredients'] as List<dynamic>? ?? [];
    return FoodRecognitionResult(
      ingredients: items
          .map((e) => DetectedIngredient.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class RecipeIngredientLine {
  final String ingredientName;
  final double quantityG;
  final String? displayUnit;

  const RecipeIngredientLine({
    required this.ingredientName,
    required this.quantityG,
    this.displayUnit,
  });

  factory RecipeIngredientLine.fromMap(Map<String, dynamic> map) {
    return RecipeIngredientLine(
      ingredientName: map['name'] as String? ?? '',
      quantityG: (map['quantity_g'] as num?)?.toDouble() ?? 0.0,
      displayUnit: map['display_unit'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': ingredientName,
        'quantity_g': quantityG,
        'display_unit': displayUnit,
      };
}

class GeneratedRecipe {
  final String name;
  final String description;
  final int prepTimeMinutes;
  final int cookTimeMinutes;
  final int servings;
  final String difficulty;
  final List<RecipeIngredientLine> ingredients;
  final List<String> steps;
  final Map<String, double> macrosPerServing;
  // M32 — compliance metadata from the recipe AI.
  final String? warning;
  final bool macroCompliance;
  final List<String> blocklistedIngredientsSkipped;
  final double proteinDensity; // g protein per 100 kcal

  const GeneratedRecipe({
    required this.name,
    required this.description,
    required this.prepTimeMinutes,
    required this.cookTimeMinutes,
    required this.servings,
    required this.difficulty,
    required this.ingredients,
    required this.steps,
    required this.macrosPerServing,
    this.warning,
    this.macroCompliance = false,
    this.blocklistedIngredientsSkipped = const [],
    this.proteinDensity = 0.0,
  });

  double get calories => macrosPerServing['calories'] ?? 0;
  double get proteinG => macrosPerServing['protein_g'] ?? 0;
  double get carbsG => macrosPerServing['carbs_g'] ?? 0;
  double get fatG => macrosPerServing['fat_g'] ?? 0;
  int get totalTimeMinutes => prepTimeMinutes + cookTimeMinutes;

  factory GeneratedRecipe.fromMap(Map<String, dynamic> map) {
    final rawIngredients = map['ingredients'] as List<dynamic>? ?? [];
    final rawSteps = map['steps'] as List<dynamic>? ?? [];
    final rawMacros =
        map['macros_per_serving'] as Map<String, dynamic>? ?? {};
    final rawSkipped =
        map['blocklisted_ingredients_skipped'] as List<dynamic>? ?? [];

    return GeneratedRecipe(
      name: map['name'] as String? ?? 'Unnamed Recipe',
      description: map['description'] as String? ?? '',
      prepTimeMinutes: (map['prep_time_minutes'] as num?)?.toInt() ?? 0,
      cookTimeMinutes: (map['cook_time_minutes'] as num?)?.toInt() ?? 0,
      servings: (map['servings'] as num?)?.toInt() ?? 1,
      difficulty: map['difficulty'] as String? ?? 'medium',
      ingredients: rawIngredients
          .map((e) => RecipeIngredientLine.fromMap(e as Map<String, dynamic>))
          .toList(),
      steps: rawSteps.map((e) => e.toString()).toList(),
      macrosPerServing: rawMacros.map(
        (k, v) => MapEntry(k, (v as num?)?.toDouble() ?? 0.0),
      ),
      warning: map['warning'] as String?,
      macroCompliance: map['macro_compliance'] as bool? ?? false,
      blocklistedIngredientsSkipped:
          rawSkipped.map((e) => e.toString()).toList(),
      proteinDensity: (map['protein_density'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'prep_time_minutes': prepTimeMinutes,
        'cook_time_minutes': cookTimeMinutes,
        'servings': servings,
        'difficulty': difficulty,
        'ingredients': ingredients.map((e) => e.toMap()).toList(),
        'steps': steps,
        'macros_per_serving': macrosPerServing,
        'warning': warning,
        'macro_compliance': macroCompliance,
        'blocklisted_ingredients_skipped': blocklistedIngredientsSkipped,
        'protein_density': proteinDensity,
      };
}

class RecipeGenerationResult {
  final List<GeneratedRecipe> recipes;
  final String? rawResponse;

  const RecipeGenerationResult({
    required this.recipes,
    this.rawResponse,
  });
}
