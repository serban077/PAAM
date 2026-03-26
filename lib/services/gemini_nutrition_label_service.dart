import 'dart:convert';
import 'dart:typed_data';
import 'gemini_ai_service.dart';

class GeminiNutritionLabelService {
  static final GeminiNutritionLabelService _instance =
      GeminiNutritionLabelService._internal();

  factory GeminiNutritionLabelService() => _instance;

  GeminiNutritionLabelService._internal();

  static const String _prompt = '''
You are a nutritional label reader. Extract all macronutrient values from the food label in the image.

Return ONLY a valid JSON object with these exact keys (all values per 100g, use null if not found on label):
{
  "calories": <number or null>,
  "protein_g": <number or null>,
  "carbs_g": <number or null>,
  "sugar_g": <number or null>,
  "fat_g": <number or null>,
  "saturated_fat_g": <number or null>,
  "unsaturated_fat_g": <number or null>,
  "fiber_g": <number or null>,
  "sodium_mg": <number or null>,
  "serving_size_g": <number or null>
}

Rules:
- Output ONLY the JSON object, no markdown, no explanation, no code fences.
- All numeric values must be plain numbers (not strings).
- If the label shows values per serving (not per 100g), convert to per 100g using the serving size.
- If a value is not present on the label, use null.
''';

  /// Extracts nutritional values from a food label image using Gemini Vision.
  /// Returns a Map with nutrition data, or null if extraction fails or
  /// required fields (calories, protein_g, carbs_g, fat_g) are missing.
  Future<Map<String, dynamic>?> extractNutritionLabel(
      Uint8List imageBytes) async {
    try {
      final base64Image = base64Encode(imageBytes);

      final client = GeminiAIService().client;

      final response = await client.createChat(
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
        model: 'gemini-1.5-flash',
        temperature: 0.0,
        maxTokens: 512,
      ).timeout(const Duration(seconds: 30));

      final rawText = response.text.trim();

      // Strip markdown code fences if present
      String jsonText = rawText;
      if (jsonText.startsWith('```')) {
        final start = jsonText.indexOf('{');
        final end = jsonText.lastIndexOf('}');
        if (start != -1 && end != -1) {
          jsonText = jsonText.substring(start, end + 1);
        }
      }

      final Map<String, dynamic> data =
          jsonDecode(jsonText) as Map<String, dynamic>;

      // Validate required fields
      final requiredKeys = ['calories', 'protein_g', 'carbs_g', 'fat_g'];
      for (final key in requiredKeys) {
        if (data[key] == null) return null;
      }

      return data;
    } catch (_) {
      return null;
    }
  }
}
