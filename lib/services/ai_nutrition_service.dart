import 'package:flutter/material.dart';
import '../services/gemini_ai_service.dart';

/// AI Nutrition Service - Generate personalized meal plans
class AINutritionService {
  static final AINutritionService _instance = AINutritionService._internal();
  factory AINutritionService() => _instance;
  AINutritionService._internal();

  final _geminiService = GeminiAIService();

  /// Generate a personalized meal plan for the user
  Future<Map<String, dynamic>> generateMealPlan(String userId) async {
    try {
      debugPrint('Generating nutrition plan with AI...');
      final plan = await _geminiService.generateNutritionPlan(userId);
      return plan;
    } catch (e) {
      debugPrint('Error generating meal plan: $e');
      rethrow;
    }
  }
}
