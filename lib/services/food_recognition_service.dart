import 'dart:convert';
import 'dart:typed_data';

import '../data/models/smart_recipe_models.dart';
import 'gemini_ai_service.dart';

/// Recognizes food ingredients from a photo using Gemini Vision.
///
/// Sends a base64-encoded image to Gemini 2.5 Flash and returns a structured
/// [FoodRecognitionResult] with detected ingredients, estimated quantities,
/// and categories.
class FoodRecognitionService {
  static final FoodRecognitionService _instance =
      FoodRecognitionService._internal();

  factory FoodRecognitionService() => _instance;

  FoodRecognitionService._internal();

  static const String _prompt = '''
You are a food ingredient recognition system. Analyze this photo and identify ALL individual food items visible. This may be a fridge, pantry, countertop, or single dish photo.

Return a JSON array. For each item:
- "name": the actual food/ingredient in English (lowercase). For packaged products, identify what the product IS (e.g. "arrabbiata pasta sauce" not just "jar", "truffle mayo" not just "sauce", "ketchup", "eggs", "milk", "cheese slices"). Read labels/brands to be specific.
- "estimated_quantity_g": estimated total weight in grams. For packaged items, estimate from container size (standard jar ~400g, egg carton of 10 ~600g, milk bottle 1L ~1000g, ketchup bottle ~450g, mayo jar ~230g, beer can ~330ml).
- "category": one of "protein", "carb", "fat", "vegetable", "fruit", "dairy", "condiment"

RULES:
- Only include food/drink items. Ignore non-food objects (bowls, plates, shelves, appliances).
- READ visible brand names and product labels to identify items accurately.
- For packaged items behind other items, include them if you can identify them.
- If the same food appears multiple times (e.g. 2 cartons of eggs), combine the quantity.
- If no food items are visible, return an empty array: []
- Return ONLY valid JSON (an array), no markdown fences, no explanation.
''';

  /// Analyzes an image and returns detected food ingredients.
  ///
  /// [imageBytes] — the raw image bytes (JPEG/PNG).
  /// Returns [FoodRecognitionResult] with detected ingredients.
  /// Throws on API failure or timeout.
  Future<FoodRecognitionResult> recognizeIngredients(
    Uint8List imageBytes,
  ) async {
    try {
      final base64Image = base64Encode(imageBytes);
      final client = GeminiAIService().client;

      final response = await client
          .createChat(
            messages: [
              Message(
                role: 'user',
                content: [
                  {
                    'inlineData': {
                      'mimeType': 'image/jpeg',
                      'data': base64Image,
                    },
                  },
                  {'text': _prompt},
                ],
              ),
            ],
            model: 'gemini-2.5-flash',
            temperature: 0.1,
            maxTokens: 8192,
          )
          .timeout(const Duration(seconds: 45));

      final rawText = response.text.trim();

      // Strip markdown code fences if present
      final jsonStr = _extractJson(rawText);
      final parsed = jsonDecode(jsonStr);

      if (parsed is List) {
        final ingredients = parsed
            .map((e) =>
                DetectedIngredient.fromMap(e as Map<String, dynamic>))
            .toList();
        return FoodRecognitionResult(
          ingredients: ingredients,
          rawResponse: rawText,
        );
      }

      // If the model wrapped the array in an object
      if (parsed is Map<String, dynamic> && parsed['ingredients'] is List) {
        return FoodRecognitionResult.fromMap(parsed);
      }

      return const FoodRecognitionResult(ingredients: []);
    } catch (e) {
      throw Exception('Food recognition failed: $e');
    }
  }

  /// Strips markdown code fences and extracts the JSON content.
  String _extractJson(String raw) {
    var s = raw.trim();
    // Remove ```json ... ``` wrapping
    if (s.startsWith('```')) {
      final firstNewline = s.indexOf('\n');
      if (firstNewline != -1) {
        s = s.substring(firstNewline + 1);
      }
      if (s.endsWith('```')) {
        s = s.substring(0, s.length - 3);
      }
    }
    return s.trim();
  }
}
