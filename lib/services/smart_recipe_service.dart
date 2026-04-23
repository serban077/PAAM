import 'dart:convert';

import '../data/models/smart_recipe_models.dart';
import '_ai_prompts.dart';
import '_dio_interceptors.dart';
import 'gemini_ai_service.dart';
import 'supabase_service.dart';

/// Generates protein-rich recipes from a list of detected ingredients using
/// Gemini AI, with nutrition policy (blocklist, macro guards, preferred
/// sources) centralized in [lib/services/_ai_prompts.dart].
class SmartRecipeService {
  static final SmartRecipeService _instance = SmartRecipeService._internal();

  factory SmartRecipeService() => _instance;

  SmartRecipeService._internal();

  static const _recipeSchema = {
    'type': 'ARRAY',
    'items': {
      'type': 'OBJECT',
      'properties': {
        'name': {'type': 'STRING'},
        'description': {'type': 'STRING'},
        'prep_time_minutes': {'type': 'INTEGER'},
        'cook_time_minutes': {'type': 'INTEGER'},
        'servings': {'type': 'INTEGER'},
        'difficulty': {'type': 'STRING'},
        'ingredients': {
          'type': 'ARRAY',
          'items': {
            'type': 'OBJECT',
            'properties': {
              'name': {'type': 'STRING'},
              'quantity_g': {'type': 'NUMBER'},
              'display_unit': {'type': 'STRING'},
            },
            'required': ['name', 'quantity_g', 'display_unit'],
          },
        },
        'steps': {'type': 'ARRAY', 'items': {'type': 'STRING'}},
        'macros_per_serving': {
          'type': 'OBJECT',
          'properties': {
            'calories': {'type': 'NUMBER'},
            'protein_g': {'type': 'NUMBER'},
            'carbs_g': {'type': 'NUMBER'},
            'fat_g': {'type': 'NUMBER'},
          },
          'required': ['calories', 'protein_g', 'carbs_g', 'fat_g'],
        },
        'warning': {'type': 'STRING', 'nullable': true},
        'macro_compliance': {'type': 'BOOLEAN'},
        'blocklisted_ingredients_skipped': {
          'type': 'ARRAY',
          'items': {'type': 'STRING'},
        },
        'protein_density': {'type': 'NUMBER'},
      },
      'required': [
        'name', 'description', 'prep_time_minutes', 'cook_time_minutes',
        'servings', 'difficulty', 'ingredients', 'steps', 'macros_per_serving',
        'macro_compliance', 'blocklisted_ingredients_skipped',
        'protein_density',
      ],
    },
  };

  /// Generates up to 3 diverse recipes using ONLY the provided ingredients.
  ///
  /// Fetches the user's daily calorie/macro targets, fitness_goal, and
  /// dietary_preference from Supabase and injects them into the prompt so
  /// recipes align with the user's goals and the nutrition policy in
  /// [_ai_prompts.dart].
  Future<RecipeGenerationResult> generateRecipes(
    List<DetectedIngredient> ingredients,
  ) async {
    await assertConnected();
    try {
      final ingredientLines = ingredients
          .map((i) =>
              '- ${i.name}: ~${i.estimatedQuantityG.round()}g (${i.category})')
          .join('\n');

      // Best-effort user context — prompt still works with defaults.
      final ctx = await _fetchUserContext();

      final prompt = buildRecipePrompt(
        ingredientLines: ingredientLines,
        macroContext: ctx.macroContext,
        fitnessGoal: ctx.fitnessGoal,
        dietaryPreference: ctx.dietaryPreference,
      );

      final client = GeminiAIService().client;
      final response = await client
          .createChat(
            messages: [
              Message(role: 'user', content: prompt),
            ],
            model: 'gemini-3-flash',
            temperature: 0.7,
            maxTokens: 8192,
            responseMimeType: 'application/json',
            responseSchema: _recipeSchema,
          )
          .timeout(const Duration(seconds: 120));

      if (response.text.isEmpty) {
        throw Exception('Gemini returned empty response — try again');
      }

      final parsed = jsonDecode(response.text);

      List<GeneratedRecipe> recipes = [];
      if (parsed is List) {
        recipes = parsed
            .map((e) => GeneratedRecipe.fromMap(e as Map<String, dynamic>))
            .toList();
      } else if (parsed is Map<String, dynamic> && parsed['recipes'] is List) {
        recipes = (parsed['recipes'] as List)
            .map((e) => GeneratedRecipe.fromMap(e as Map<String, dynamic>))
            .toList();
      }

      return RecipeGenerationResult(recipes: recipes, rawResponse: response.text);
    } on NetworkOfflineException {
      rethrow;
    } catch (e) {
      throw Exception('Recipe generation failed: $e');
    }
  }

  Future<_UserRecipeContext> _fetchUserContext() async {
    const fallback = _UserRecipeContext(
      macroContext: '',
      fitnessGoal: 'general_fitness',
      dietaryPreference: 'normal',
    );

    final userId = SupabaseService.instance.client.auth.currentUser?.id;
    if (userId == null) return fallback;

    try {
      final profile = await SupabaseService.instance.client
          .from('user_profiles')
          .select('daily_calorie_goal, fitness_goal, dietary_preference')
          .eq('id', userId)
          .maybeSingle()
          .timeout(const Duration(seconds: 10));

      if (profile == null) return fallback;

      final calorieGoal = profile['daily_calorie_goal'] ?? 2000;
      final proteinG = (calorieGoal * 0.30 / 4).round();
      final carbsG = (calorieGoal * 0.40 / 4).round();
      final fatG = (calorieGoal * 0.30 / 9).round();

      return _UserRecipeContext(
        macroContext:
            "User's daily targets: $calorieGoal kcal, ${proteinG}g protein, ${carbsG}g carbs, ${fatG}g fat.",
        fitnessGoal: profile['fitness_goal']?.toString() ?? 'general_fitness',
        dietaryPreference:
            profile['dietary_preference']?.toString() ?? 'normal',
      );
    } catch (_) {
      return fallback;
    }
  }
}

class _UserRecipeContext {
  final String macroContext;
  final String fitnessGoal;
  final String dietaryPreference;

  const _UserRecipeContext({
    required this.macroContext,
    required this.fitnessGoal,
    required this.dietaryPreference,
  });
}
