import 'dart:convert';
import 'dart:developer' as dev;

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
            maxTokens: 16384,
          )
          .timeout(const Duration(seconds: 120));

      final rawText = response.text.trim();
      dev.log('SmartRecipeService raw length: ${rawText.length}');
      dev.log('SmartRecipeService raw start: ${rawText.substring(0, rawText.length.clamp(0, 300))}');

      if (rawText.isEmpty) {
        throw Exception('Gemini returned empty response — try again');
      }

      final jsonStr = _extractJson(rawText);
      dev.log('SmartRecipeService extracted JSON length: ${jsonStr.length}');

      dynamic parsed;
      try {
        parsed = jsonDecode(jsonStr);
      } on FormatException catch (e) {
        dev.log('JSON parse failed, attempting repair: $e');
        try {
          final repaired = _repairJson(jsonStr);
          dev.log('Repaired JSON length: ${repaired.length}');
          parsed = jsonDecode(repaired);
        } catch (repairError) {
          dev.log('Repair also failed: $repairError');
          dev.log('Raw JSON (last 200 chars): ${jsonStr.substring((jsonStr.length - 200).clamp(0, jsonStr.length))}');
          rethrow;
        }
      }

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

      return RecipeGenerationResult(recipes: recipes, rawResponse: rawText);
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

Return ONLY a JSON array, no markdown, no explanation. Schema:
[{"name":"...","description":"short","prep_time_minutes":10,"cook_time_minutes":20,"servings":2,"difficulty":"easy","ingredients":[{"name":"...","quantity_g":200,"display_unit":"g"}],"steps":["Step 1","Step 2"],"macros_per_serving":{"calories":450.0,"protein_g":35.0,"carbs_g":40.0,"fat_g":12.0}}]
''';
  }

  String _extractJson(String raw) {
    var s = raw.trim();

    // Remove markdown code fences
    if (s.startsWith('```')) {
      final firstNewline = s.indexOf('\n');
      if (firstNewline != -1) {
        s = s.substring(firstNewline + 1);
      }
      if (s.endsWith('```')) {
        s = s.substring(0, s.length - 3);
      }
      return s.trim();
    }

    // If response doesn't start with [ or {, find the first JSON
    // array or object boundary
    if (!s.startsWith('[') && !s.startsWith('{')) {
      final arrayStart = s.indexOf('[');
      final objectStart = s.indexOf('{');

      int start = -1;
      if (arrayStart >= 0 && objectStart >= 0) {
        start = arrayStart < objectStart ? arrayStart : objectStart;
      } else if (arrayStart >= 0) {
        start = arrayStart;
      } else if (objectStart >= 0) {
        start = objectStart;
      }

      if (start >= 0) {
        s = s.substring(start);
      }
    }

    // Remove any trailing text after the last ] or }
    final lastBracket = s.lastIndexOf(']');
    final lastBrace = s.lastIndexOf('}');
    final lastClose = lastBracket > lastBrace ? lastBracket : lastBrace;
    if (lastClose >= 0 && lastClose < s.length - 1) {
      s = s.substring(0, lastClose + 1);
    }

    return s.trim();
  }

  /// Attempts to repair truncated JSON from Gemini by closing unclosed
  /// brackets and removing incomplete trailing elements.
  String _repairJson(String json) {
    var s = json.trim();

    // Find the last successfully closed recipe object — look for the last
    // complete "}" that closes a recipe entry.
    // Strategy: try to find the last '}' that ends a complete recipe,
    // then close the array.
    final lastCompleteObj = s.lastIndexOf('}');
    if (lastCompleteObj == -1) throw const FormatException('No JSON object found');

    // Walk back and count braces to find where a complete object ends.
    // We try parsing progressively shorter substrings.
    // Find the position right after the last complete recipe object.
    int braceDepth = 0;
    int bracketDepth = 0;
    bool inString = false;
    bool escaped = false;
    int lastObjEnd = -1;

    for (int i = 0; i < s.length; i++) {
      final c = s[i];
      if (escaped) {
        escaped = false;
        continue;
      }
      if (c == '\\' && inString) {
        escaped = true;
        continue;
      }
      if (c == '"') {
        inString = !inString;
        continue;
      }
      if (inString) continue;

      if (c == '[') bracketDepth++;
      if (c == ']') bracketDepth--;
      if (c == '{') braceDepth++;
      if (c == '}') {
        braceDepth--;
        // When we return to brace depth 0 while inside a top-level array,
        // this marks the end of a complete recipe object.
        if (braceDepth == 0 && bracketDepth == 1) {
          lastObjEnd = i;
        }
      }
    }

    if (lastObjEnd > 0) {
      // Truncate after the last complete object and close the array
      s = '${s.substring(0, lastObjEnd + 1)}]';
    } else {
      // Brute-force: close all unclosed brackets/braces
      for (int i = 0; i < braceDepth; i++) {
        s += '}';
      }
      for (int i = 0; i < bracketDepth; i++) {
        s += ']';
      }
    }

    return s;
  }
}
