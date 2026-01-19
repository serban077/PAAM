import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
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
      // 1. Get user profile and goals
      final profile = await SupabaseService.instance.client
          .from('user_profiles')
          .select('daily_calorie_goal, weight_kg, fitness_goal, gender, age')
          .eq('id', userId)
          .single();

      final dailyCalories = profile['daily_calorie_goal'] ?? 2000;
      final weight = (profile['weight_kg'] as num?)?.toDouble() ?? 70;
      final goal = profile['fitness_goal'] ?? 'mentinere';
      final gender = profile['gender'] ?? 'masculin';
      final age = profile['age'] ?? 30;

      // 2. Calculate macros
      final macros = _calculateMacros(dailyCalories, weight, goal);

      // 3. Get available foods from database
      final foods = await SupabaseService.instance.client
          .from('food_database')
          .select()
          .eq('is_verified', true)
          .limit(100);

      // 4. Generate plan with AI
      final prompt = _buildPrompt(
        dailyCalories: dailyCalories,
        proteinG: macros['protein']!,
        carbsG: macros['carbs']!,
        fatG: macros['fat']!,
        foods: List<Map<String, dynamic>>.from(foods),
        goal: goal,
        gender: gender,
        age: age,
      );

      // Use GeminiAIService's generateNutritionPlan method
      debugPrint('Generating nutrition plan with AI...');
      final plan = await _geminiService.generateNutritionPlan(userId);

      return plan;
    } catch (e) {
      debugPrint('Error generating meal plan: $e');
      rethrow;
    }
  }

  /// Calculate macronutrient targets
  Map<String, int> _calculateMacros(int dailyCalories, double weight, String goal) {
    // Protein: 2.2g/kg for muscle gain, 1.8g/kg for maintenance, 2g/kg for fat loss
    int proteinG;
    if (goal == 'crestere_masa_musculara') {
      proteinG = (weight * 2.2).round();
    } else if (goal == 'pierdere_greutate') {
      proteinG = (weight * 2.0).round();
    } else {
      proteinG = (weight * 1.8).round();
    }

    // Fat: 25-30% of calories
    final fatG = ((dailyCalories * 0.27) / 9).round();

    // Carbs: remaining calories
    final carbsG = ((dailyCalories - (proteinG * 4) - (fatG * 9)) / 4).round();

    return {
      'protein': proteinG,
      'carbs': carbsG,
      'fat': fatG,
    };
  }

  /// Build AI prompt for meal plan generation
  String _buildPrompt({
    required int dailyCalories,
    required int proteinG,
    required int carbsG,
    required int fatG,
    required List<Map<String, dynamic>> foods,
    required String goal,
    required String gender,
    required int age,
  }) {
    final foodList = foods.map((f) {
      return '- ${f['name']}: ${f['calories']} kcal/${f['serving_size']}${f['serving_unit']} '
          '(P: ${f['protein_g']}g, C: ${f['carbs_g']}g, F: ${f['fat_g']}g)';
    }).join('\n');

    return '''
Generează un plan alimentar personalizat pentru o zi cu următoarele specificații:

**Profil utilizator:**
- Vârstă: $age ani
- Gen: $gender
- Obiectiv: $goal

**Ținte nutriționale:**
- Calorii zilnice: $dailyCalories kcal
- Proteine: ${proteinG}g
- Carbohidrați: ${carbsG}g
- Grăsimi: ${fatG}g

**Alimente disponibile:**
$foodList

**Cerințe IMPORTANTE:**
1. Creează 4 tipuri de mese: mic_dejun, pranz, cina, snack
2. Pentru FIECARE tip de masă, generează 3 OPȚIUNI DIFERITE
3. Fiecare opțiune trebuie să aibă calorii similare (±50 kcal între opțiuni)
4. Folosește DOAR alimente din lista de mai sus
5. Respectă bugetul caloric total (±100 kcal)
6. Echilibrează macronutrienții (±15%)
7. Cantități realiste și variate
8. Preferă alimente românești tradiționale când e posibil

**Format răspuns (STRICT JSON):**
{
  "meals": [
    {
      "type": "mic_dejun",
      "label": "Mic dejun (pre-antrenament, dacă antrenamentul este dimineața)",
      "options": [
        {
          "option_number": 1,
          "foods": [
            {"name": "Ouă întregi", "quantity": 150},
            {"name": "Pâine integrală", "quantity": 50}
          ]
        },
        {
          "option_number": 2,
          "foods": [
            {"name": "Ovăz", "quantity": 80},
            {"name": "Lapte 1.5% grăsime", "quantity": 200}
          ]
        },
        {
          "option_number": 3,
          "foods": [
            {"name": "Iaurt grecesc 0%", "quantity": 200},
            {"name": "Banane", "quantity": 100}
          ]
        }
      ]
    },
    {
      "type": "pranz",
      "label": "Prânz",
      "options": [
        {
          "option_number": 1,
          "foods": [
            {"name": "Piept de pui", "quantity": 200},
            {"name": "Orez brun fiert", "quantity": 150}
          ]
        },
        {
          "option_number": 2,
          "foods": [
            {"name": "Somon", "quantity": 150},
            {"name": "Cartofi fierți", "quantity": 200}
          ]
        },
        {
          "option_number": 3,
          "foods": [
            {"name": "Carne de vită (slabă)", "quantity": 180},
            {"name": "Paste integrale fierte", "quantity": 150}
          ]
        }
      ]
    },
    {
      "type": "cina",
      "label": "Cină",
      "options": [
        {
          "option_number": 1,
          "foods": [
            {"name": "Somon", "quantity": 150},
            {"name": "Broccoli", "quantity": 200}
          ]
        },
        {
          "option_number": 2,
          "foods": [
            {"name": "Curcan (piept)", "quantity": 180},
            {"name": "Dovlecei", "quantity": 200}
          ]
        },
        {
          "option_number": 3,
          "foods": [
            {"name": "Ton în apă", "quantity": 150},
            {"name": "Salată verde", "quantity": 150}
          ]
        }
      ]
    },
    {
      "type": "snack",
      "label": "Gustare (post-antrenament)",
      "options": [
        {
          "option_number": 1,
          "foods": [
            {"name": "Iaurt grecesc 0%", "quantity": 150},
            {"name": "Afine", "quantity": 50}
          ]
        },
        {
          "option_number": 2,
          "foods": [
            {"name": "Brânză de vaci", "quantity": 100},
            {"name": "Mere", "quantity": 150}
          ]
        },
        {
          "option_number": 3,
          "foods": [
            {"name": "Migdale", "quantity": 30},
            {"name": "Banane", "quantity": 100}
          ]
        }
      ]
    }
  ]
}

IMPORTANT: Răspunde DOAR cu JSON-ul, fără text suplimentar.
''';
  }

  /// Parse AI response and extract meal plan
  Map<String, dynamic> _parseAIResponse(String response) {
    try {
      // Remove markdown code blocks if present
      String cleanedResponse = response.trim();
      if (cleanedResponse.startsWith('```json')) {
        cleanedResponse = cleanedResponse.substring(7);
      }
      if (cleanedResponse.startsWith('```')) {
        cleanedResponse = cleanedResponse.substring(3);
      }
      if (cleanedResponse.endsWith('```')) {
        cleanedResponse = cleanedResponse.substring(0, cleanedResponse.length - 3);
      }
      cleanedResponse = cleanedResponse.trim();

      final parsed = jsonDecode(cleanedResponse);
      return parsed as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error parsing AI response: $e');
      debugPrint('Response was: $response');
      rethrow;
    }
  }

  /// Save generated meal plan to database
  Future<void> saveMealPlan(String userId, Map<String, dynamic> plan) async {
    try {
      final meals = plan['meals'] as List<dynamic>;

      for (var meal in meals) {
        final mealType = meal['type'] as String;
        final foods = meal['foods'] as List<dynamic>;

        for (var food in foods) {
          final foodName = food['name'] as String;
          final quantity = (food['quantity'] as num).toDouble();

          // Find food ID from database
          final foodData = await SupabaseService.instance.client
              .from('food_database')
              .select('id')
              .eq('name', foodName)
              .maybeSingle();

          if (foodData != null) {
            await SupabaseService.instance.client.from('user_meals').insert({
              'user_id': userId,
              'food_id': foodData['id'],
              'meal_type': mealType,
              'serving_quantity': quantity,
              'consumed_at': DateTime.now().toIso8601String(),
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error saving meal plan: $e');
      rethrow;
    }
  }
}
