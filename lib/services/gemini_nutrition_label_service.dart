import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'gemini_ai_service.dart';

class GeminiNutritionLabelService {
  static final GeminiNutritionLabelService _instance =
      GeminiNutritionLabelService._internal();

  factory GeminiNutritionLabelService() => _instance;

  GeminiNutritionLabelService._internal();

  // ── Prompt for text-based parsing (Step 2 — after ML Kit OCR) ────────────

  static const String _textPrompt = '''
You are a nutritional label parser. You receive RAW TEXT extracted via OCR from a food product's nutritional label.

Your job: identify and extract ALL nutritional values from the per-100g or per-100ml column. Use null for any value not found in the text.

CRITICAL RULES:
- All numeric values must be plain numbers with dots as decimal separator (not strings, not commas). Example: 3,2 → 3.2
- EUROPEAN LABELS use COMMA as decimal separator (e.g. "3,2 g" means 3.2). Always convert commas to dots in your output.
- Labels may have TWO columns: per 100g/100ml AND per serving/portion. ALWAYS use the per-100g or per-100ml column (the first/smaller values column). Ignore the per-serving column.
- Per 100ml and per 100g are treated identically — just extract the values as-is from the per-100 column.
- If the label ONLY shows per-serving values (no per-100 column), convert to per 100g/ml using the serving size.

ENERGY:
- European labels list energy as kJ and kcal — use the kcal value for "calories".
- If only kJ is shown, convert: kcal = kJ / 4.184.
- "Energiasisaldus" / "Energētiskā vērtība" / "Valoare energetică" / "Énergie" / "Energie" / "Energy" → calories.

MULTI-LANGUAGE VOCABULARY (labels may be in any language):
- Fat: "Rasvad" / "Tauki" / "Grăsimi" / "Fett" / "Matières grasses" / "Fat"
- Saturated: "küllastunud" / "piesātinātās" / "saturați" / "gesättigte" / "saturés" / "saturates"
- Carbs: "Süsivesikud" / "Ogļhidrāti" / "Glucide" / "Kohlenhydrate" / "Glucides" / "Carbohydrate"
- Sugar: "suhkrud" / "cukuri" / "zaharuri" / "Zucker" / "sucres" / "sugars"
- Fiber: "Kiudained" / "Šķiedrvielas" / "Fibre" / "Ballaststoffe" / "Fibres"
- Protein: "Valgud" / "Olbaltumvielas" / "Proteine" / "Eiweiß" / "Protéines" / "Protein"
- Salt: "Sool" / "Sāls" / "Sare" / "Salz" / "Sel" / "Salt"
- Calcium: "Kaltsium" / "Kalcijs" / "Calciu" / "Kalzium" / "Calcium"
- Vitamin D: "Vitamiin D" / "D vitamīns" / "Vitamina D" / "Vitamin D"

SALT / SODIUM:
- European labels show "salt" (sare/sel/Salz/sool/sāls) — extract as salt_g.
- If only sodium is listed, calculate: salt_g = sodium_mg * 2.5 / 1000.
- If only salt is listed, calculate: sodium_mg = salt_g / 2.5 * 1000.

RULES FOR MISSING VALUES:
- If total carbs and sugar are both present but starch is not listed, leave starch_g as null — do NOT compute it.
- If total fat and saturated fat are both present but mono/poly are missing, leave them null — do NOT guess.
- OCR text may contain errors: "O" instead of "0", "l" instead of "1", "g" attached to numbers, "ø" or "Ø" for per-100. Handle these gracefully.
- If a value is ambiguous or unreadable, use null rather than guessing.
- Look for vitamins and minerals in SEPARATE TABLES below the main nutrition table — they are often in a second section.
''';

  // ── Fallback prompt for image-based parsing (when ML Kit fails) ──────────

  static const String _imagePrompt = '''
You are a nutritional label reader. Extract ALL nutritional values from the food label in the image. Use null for any value not clearly visible.

Rules:
- All numeric values must be plain numbers with dots as decimal separator. European labels use commas (3,2 → output 3.2).
- If the label has TWO columns (per 100g/ml AND per serving), ALWAYS use the per-100g/100ml column.
- Per 100ml and per 100g are treated identically.
- If the label ONLY shows per-serving, convert to per 100g/ml using the serving size.
- European labels show "salt" (sare/sool/sāls/sel/Salz) — extract as salt_g. If only sodium, calculate: salt_g = sodium_mg * 2.5 / 1000.
- Use kcal for "calories". If only kJ, convert: kcal = kJ / 4.184.
- Labels may be in any language (Estonian, Latvian, Romanian, German, French, English, etc.) — recognize nutritional terms in all languages.
- Look for vitamins/minerals in separate tables below the main nutrition facts.
- If a value is not clearly visible, use null — do NOT guess.
''';

  // ── Step 1: ML Kit on-device OCR ─────────────────────────────────────────

  Future<String?> _extractTextFromImage(String imagePath) async {
    final textRecognizer = TextRecognizer();
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText =
          await textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } finally {
      textRecognizer.close();
    }
  }

  // ── Structured output schema for all 22 nutrition fields ────────────────

  static const _nutritionSchema = {
    'type': 'OBJECT',
    'properties': {
      'calories':                  {'type': 'NUMBER'},
      'protein_g':                 {'type': 'NUMBER'},
      'carbs_g':                   {'type': 'NUMBER'},
      'fat_g':                     {'type': 'NUMBER'},
      'sugar_g':                   {'type': 'NUMBER', 'nullable': true},
      'starch_g':                  {'type': 'NUMBER', 'nullable': true},
      'polyols_g':                 {'type': 'NUMBER', 'nullable': true},
      'saturated_fat_g':           {'type': 'NUMBER', 'nullable': true},
      'monounsaturated_fat_g':     {'type': 'NUMBER', 'nullable': true},
      'polyunsaturated_fat_g':     {'type': 'NUMBER', 'nullable': true},
      'trans_fat_g':               {'type': 'NUMBER', 'nullable': true},
      'fiber_g':                   {'type': 'NUMBER', 'nullable': true},
      'salt_g':                    {'type': 'NUMBER', 'nullable': true},
      'sodium_mg':                 {'type': 'NUMBER', 'nullable': true},
      'cholesterol_mg':            {'type': 'NUMBER', 'nullable': true},
      'potassium_mg':              {'type': 'NUMBER', 'nullable': true},
      'calcium_mg':                {'type': 'NUMBER', 'nullable': true},
      'iron_mg':                   {'type': 'NUMBER', 'nullable': true},
      'vitamin_a_ug':              {'type': 'NUMBER', 'nullable': true},
      'vitamin_c_mg':              {'type': 'NUMBER', 'nullable': true},
      'vitamin_d_ug':              {'type': 'NUMBER', 'nullable': true},
      'serving_size_g':            {'type': 'NUMBER', 'nullable': true},
    },
    'required': ['calories', 'protein_g', 'carbs_g', 'fat_g'],
  };

  // ── Step 2a: Parse OCR text with Gemini ──────────────────────────────────

  Future<Map<String, dynamic>?> _parseNutritionText(String rawText) async {
    try {
      final client = GeminiAIService().client;

      final response = await client.createChat(
        messages: [
          Message(
            role: 'user',
            content:
                '$_textPrompt\n\n--- RAW OCR TEXT START ---\n$rawText\n--- RAW OCR TEXT END ---',
          ),
        ],
        model: 'gemini-3.1-flash-lite-preview',
        temperature: 0.0,
        maxTokens: 4096,
        responseMimeType: 'application/json',
        responseSchema: _nutritionSchema,
      ).timeout(const Duration(seconds: 45));

      return _parseJsonResponse(response.text);
    } catch (e) {
      debugPrint('[OCR] Text parsing failed: $e');
      return null;
    }
  }

  // ── Step 2b: Fallback — send image directly to Gemini Vision ─────────────

  Future<Map<String, dynamic>?> _parseNutritionImage(
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
              {'text': _imagePrompt},
            ],
          ),
        ],
        model: 'gemini-3-flash-preview',
        temperature: 0.0,
        maxTokens: 4096,
        responseMimeType: 'application/json',
        responseSchema: _nutritionSchema,
      ).timeout(const Duration(seconds: 45));

      return _parseJsonResponse(response.text);
    } catch (e) {
      debugPrint('[OCR] Image parsing failed: $e');
      return null;
    }
  }

  // ── JSON parsing + validation ────────────────────────────────────────────

  Map<String, dynamic>? _parseJsonResponse(String rawText) {
    try {
      final data = jsonDecode(rawText) as Map<String, dynamic>;

      // Validate required fields are non-null
      final requiredKeys = ['calories', 'protein_g', 'carbs_g', 'fat_g'];
      for (final key in requiredKeys) {
        if (data[key] == null) {
          debugPrint('[OCR] Missing required field: $key');
          return null;
        }
      }

      debugPrint('[OCR] Parsed: cal=${data['calories']} p=${data['protein_g']} c=${data['carbs_g']} f=${data['fat_g']}');
      return data;
    } catch (e) {
      debugPrint('[OCR] JSON decode failed: $e');
      return null;
    }
  }

  // ── Public API ───────────────────────────────────────────────────────────

  /// Extracts nutritional values from a food label using a 2-step pipeline:
  ///   1. ML Kit on-device OCR → raw text
  ///   2. Gemini 2.5 Flash → structured JSON
  /// Falls back to Gemini Vision (image-based) if ML Kit fails.
  ///
  /// Returns a Map with nutrition data, or null if extraction fails or
  /// required fields (calories, protein_g, carbs_g, fat_g) are missing.
  Future<Map<String, dynamic>?> extractNutritionLabel(
    Uint8List imageBytes, {
    String? imagePath,
  }) async {
    try {
      // Step 1: Try ML Kit OCR if we have a file path
      if (imagePath != null) {
        try {
          final rawText = await _extractTextFromImage(imagePath);
          debugPrint('[OCR] ML Kit text length: ${rawText?.trim().length ?? 0}');
          if (rawText != null && rawText.trim().length > 20) {
            // Step 2a: ML Kit succeeded — parse text with Gemini
            final result = await _parseNutritionText(rawText);
            if (result != null) {
              debugPrint('[OCR] Text pipeline succeeded');
              return result;
            }
            debugPrint('[OCR] Text pipeline returned null — falling back to vision');
          }
        } catch (e) {
          debugPrint('[OCR] ML Kit failed: $e — falling back to vision');
        }
      }

      // Step 2b: Fallback — send image directly to Gemini Vision
      debugPrint('[OCR] Trying Gemini Vision fallback…');
      final result = await _parseNutritionImage(imageBytes);
      debugPrint('[OCR] Vision fallback result: ${result != null ? 'success' : 'null'}');
      return result;
    } catch (e) {
      debugPrint('[OCR] Pipeline failed entirely: $e');
      return null;
    }
  }
}
