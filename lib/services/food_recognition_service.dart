import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../data/models/smart_recipe_models.dart';
import '_ai_prompts.dart';
import '_dio_interceptors.dart';
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

  static const _ingredientSchema = {
    'type': 'ARRAY',
    'items': {
      'type': 'OBJECT',
      'properties': {
        'name': {'type': 'STRING'},
        'estimated_quantity_g': {'type': 'NUMBER'},
        'category': {'type': 'STRING'},
      },
      'required': ['name', 'estimated_quantity_g', 'category'],
    },
  };

  // Prompt assembled from lib/services/_ai_prompts.dart — do not inline policy.
  static const String _prompt = kFoodRecognitionPrompt;

  /// Analyzes an image and returns detected food ingredients.
  ///
  /// [imageBytes] — the raw image bytes (JPEG/PNG).
  /// [cancelToken] — optional Dio cancel token; cancel it to abort the Vision
  ///   call when the user navigates away before the response arrives.
  /// Throws [NetworkOfflineException] when the device has no connectivity.
  /// Throws on API failure or timeout.
  Future<FoodRecognitionResult> recognizeIngredients(
    Uint8List imageBytes, {
    CancelToken? cancelToken,
  }) async {
    await assertConnected();
    final txn = Sentry.startTransaction('food-recognition', 'task');
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
            maxTokens: 2048,
            cancelToken: cancelToken,
            responseMimeType: 'application/json',
            responseSchema: _ingredientSchema,
          )
          .timeout(const Duration(seconds: 45));

      final parsed = jsonDecode(response.text);

      if (parsed is List) {
        final ingredients = parsed
            .map((e) =>
                DetectedIngredient.fromMap(e as Map<String, dynamic>))
            .toList();
        txn.status = const SpanStatus.ok();
        return FoodRecognitionResult(
          ingredients: ingredients,
          rawResponse: response.text,
        );
      }

      txn.status = const SpanStatus.ok();
      return const FoodRecognitionResult(ingredients: []);
    } on NetworkOfflineException {
      txn.status = const SpanStatus.cancelled();
      rethrow;
    } catch (e, stack) {
      txn.status = const SpanStatus.internalError();
      unawaited(Sentry.captureException(e, stackTrace: stack,
          hint: Hint.withMap({'service': 'FoodRecognitionService', 'method': 'recognizeIngredients'})));
      throw Exception('Food recognition failed: $e');
    } finally {
      await txn.finish();
    }
  }
}
