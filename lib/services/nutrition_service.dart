import 'package:supabase_flutter/supabase_flutter.dart';

class NutritionService {
  final SupabaseClient _client;

  NutritionService(this._client);

  // Search food database
  Future<List<Map<String, dynamic>>> searchFood(String query) async {
    try {
      final response = await _client.rpc(
        'search_food',
        params: {'search_term': query},
      );
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Eroare la căutarea alimentelor: $e');
    }
  }

  // Add food to user meals
  Future<void> logMeal({
    required String foodId,
    required String mealType,
    required double servingQuantity,
    String? notes,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _client.from('user_meals').insert({
        'user_id': userId,
        'food_id': foodId,
        'meal_type': mealType,
        'serving_quantity': servingQuantity,
        'notes': notes,
        'consumed_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Eroare la adăugarea alimentului: $e');
    }
  }

  // Get user meals for a specific date
  Future<List<Map<String, dynamic>>> getUserMeals(DateTime date) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _client
          .from('user_meals')
          .select('*, food_database(*)')
          .eq('user_id', userId)
          .gte('consumed_at', startOfDay.toIso8601String())
          .lt('consumed_at', endOfDay.toIso8601String())
          .order('consumed_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Eroare la încărcarea meselor: $e');
    }
  }

  // Calculate daily nutrition totals
  Future<Map<String, double>> getDailyNutritionTotals(DateTime date) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _client.rpc(
        'calculate_daily_nutrition_totals',
        params: {
          'p_user_id': userId,
          'p_date': date.toIso8601String().split('T')[0],
        },
      );

      if (response == null || response.isEmpty) {
        return {
          'total_calories': 0.0,
          'total_protein_g': 0.0,
          'total_carbs_g': 0.0,
          'total_fat_g': 0.0,
        };
      }

      final data = response[0];
      return {
        'total_calories': (data['total_calories'] ?? 0.0).toDouble(),
        'total_protein_g': (data['total_protein_g'] ?? 0.0).toDouble(),
        'total_carbs_g': (data['total_carbs_g'] ?? 0.0).toDouble(),
        'total_fat_g': (data['total_fat_g'] ?? 0.0).toDouble(),
      };
    } catch (e) {
      return {
        'total_calories': 0.0,
        'total_protein_g': 0.0,
        'total_carbs_g': 0.0,
        'total_fat_g': 0.0,
      };
    }
  }

  // Get or create daily nutrition goal
  Future<Map<String, dynamic>> getDailyGoal(DateTime date) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Try to get existing goal
      final response = await _client
          .from('daily_nutrition_goals')
          .select()
          .eq('user_id', userId)
          .eq('date', date.toIso8601String().split('T')[0])
          .maybeSingle();

      if (response != null) {
        return response;
      }

      // Get user profile for default goal
      final profile = await _client
          .from('user_profiles')
          .select('daily_calorie_goal')
          .eq('id', userId)
          .single();

      final calorieGoal = profile['daily_calorie_goal'] ?? 2000;

      // Create new goal
      final newGoal = await _client
          .from('daily_nutrition_goals')
          .insert({
            'user_id': userId,
            'date': date.toIso8601String().split('T')[0],
            'calorie_goal': calorieGoal,
            'protein_goal_g': (calorieGoal * 0.30 / 4).round(),
            'carbs_goal_g': (calorieGoal * 0.40 / 4).round(),
            'fat_goal_g': (calorieGoal * 0.30 / 9).round(),
          })
          .select()
          .single();

      return newGoal;
    } catch (e) {
      return {
        'calorie_goal': 2000,
        'protein_goal_g': 150,
        'carbs_goal_g': 200,
        'fat_goal_g': 67,
      };
    }
  }

  // Delete meal
  Future<void> deleteMeal(String mealId) async {
    try {
      await _client.from('user_meals').delete().eq('id', mealId);
    } catch (e) {
      throw Exception('Eroare la ștergerea alimentului: $e');
    }
  }
}
