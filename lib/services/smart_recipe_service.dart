import 'dart:convert';

import '../data/models/smart_recipe_models.dart';
import '_dio_interceptors.dart';
import 'gemini_ai_service.dart';
import 'supabase_service.dart';

/// Generates protein-rich recipes from a list of detected ingredients using
/// Gemini AI, incorporating the user's daily macro targets.
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
      },
      'required': [
        'name', 'description', 'prep_time_minutes', 'cook_time_minutes',
        'servings', 'difficulty', 'ingredients', 'steps', 'macros_per_serving',
      ],
    },
  };

  /// Generates 3-5 diverse recipes using ONLY the provided ingredients.
  ///
  /// Fetches the user's daily calorie/macro targets from Supabase and includes
  /// them in the prompt so recipes align with the user's goals.
  Future<RecipeGenerationResult> generateRecipes(
    List<DetectedIngredient> ingredients,
  ) async {
    await assertConnected();
    try {
      // Build ingredient list string
      final ingredientLines = ingredients
          .map((i) => '- ${i.name}: ~${i.estimatedQuantityG.round()}g (${i.category})')
          .join('\n');

      // Fetch user macro targets (best-effort — works without them)
      String macroContext = '';
      try {
        macroContext = await _fetchUserMacroContext();
      } catch (_) {
        // Proceed without macro targets
      }

      final prompt = _buildPrompt(ingredientLines, macroContext);

      final client = GeminiAIService().client;
      final response = await client
          .createChat(
            messages: [
              Message(role: 'user', content: prompt),
            ],
            model: 'gemini-2.5-flash',
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

  Future<String> _fetchUserMacroContext() async {
    final userId = SupabaseService.instance.client.auth.currentUser?.id;
    if (userId == null) return '';

    final profile = await SupabaseService.instance.client
        .from('user_profiles')
        .select('daily_calorie_goal')
        .eq('id', userId)
        .maybeSingle()
        .timeout(const Duration(seconds: 10));

    if (profile == null) return '';

    final calorieGoal = profile['daily_calorie_goal'] ?? 2000;
    final proteinG = (calorieGoal * 0.30 / 4).round();
    final carbsG = (calorieGoal * 0.40 / 4).round();
    final fatG = (calorieGoal * 0.30 / 9).round();

    return '\nUser\'s daily targets: $calorieGoal kcal, ${proteinG}g protein, ${carbsG}g carbs, ${fatG}g fat.';
  }

  String _buildPrompt(String ingredientLines, String macroContext) {
    return '''
You are a chef and nutritionist. Generate exactly 3 recipes using ONLY these ingredients:

$ingredientLines
$macroContext

RULES:
1. Use ONLY listed ingredients (water, salt, pepper, oil are assumed available).
2. Each recipe uses a subset — not all ingredients required.
3. Prioritize high-protein. Keep steps short (max 5 steps per recipe).
4. "difficulty": "easy", "medium", or "hard".
''';
  }
}
