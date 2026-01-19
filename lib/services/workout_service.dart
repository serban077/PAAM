import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class WorkoutService {
  final SupabaseClient _client = SupabaseService.instance.client;

  // Get all workout plans
  Future<List<dynamic>> getAllWorkoutPlans() async {
    try {
      final response = await _client
          .from('workout_plans')
          .select('*')
          .order('fitness_goal', ascending: true)
          .order('weekly_frequency', ascending: true);

      return response;
    } catch (error) {
      throw Exception('Failed to fetch workout plans: $error');
    }
  }

  // Get workout plan details with sessions
  Future<Map<String, dynamic>> getWorkoutPlanDetails(String planId) async {
    try {
      // Get plan details
      final plan = await _client
          .from('workout_plans')
          .select('*')
          .eq('id', planId)
          .single();

      // Get sessions for this plan with category info
      final sessions = await _client
          .from('workout_sessions')
          .select('*, workout_categories(*)')
          .eq('plan_id', planId)
          .order('day_of_week', ascending: true);

      return {'plan': plan, 'sessions': sessions};
    } catch (error) {
      throw Exception('Failed to fetch workout plan details: $error');
    }
  }

  // Get exercises for a session
  Future<List<dynamic>> getSessionExercises(String sessionId) async {
    try {
      final response = await _client
          .from('session_exercises')
          .select('*, exercises(*)')
          .eq('session_id', sessionId)
          .order('order_in_session', ascending: true);

      return response;
    } catch (error) {
      throw Exception('Failed to fetch exercises: $error');
    }
  }

  // Get workout plans by category
  Future<List<dynamic>> getWorkoutPlansByCategory(String categoryId) async {
    try {
      // Get sessions with this category
      final sessions = await _client
          .from('workout_sessions')
          .select('plan_id')
          .eq('category_id', categoryId);

      if (sessions.isEmpty) return [];

      // Get unique plan IDs
      final planIds = sessions.map((s) => s['plan_id']).toSet().toList();

      // Get plans
      final plans = await _client
          .from('workout_plans')
          .select('*')
          .inFilter('id', planIds);

      return plans;
    } catch (error) {
      throw Exception('Failed to fetch plans by category: $error');
    }
  }

  // Start a workout plan for user
  Future<Map<String, dynamic>> startWorkoutPlan(String planId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Check if plan exists
      final planExists = await _client
          .from('workout_plans')
          .select('id')
          .eq('id', planId)
          .maybeSingle();

      if (planExists == null) {
        throw Exception('Workout plan not found');
      }

      // Deactivate any active workout plans for this user
      await _client
          .from('workout_plans')
          .update({'is_active': false})
          .eq('user_id', userId)
          .eq('is_active', true);

      // Create user's own copy of the plan
      final newPlan = await _client
          .from('workout_plans')
          .insert({
            'user_id': userId,
            'plan_name': planExists['plan_name'] ?? 'Planul Meu',
            'fitness_goal': planExists['fitness_goal'],
            'weekly_frequency': planExists['weekly_frequency'],
            'duration_weeks': planExists['duration_weeks'],
            'is_active': true,
          })
          .select()
          .single();

      return newPlan;
    } catch (error) {
      throw Exception('Failed to start workout plan: $error');
    }
  }

  // Get user's active workout
  Future<Map<String, dynamic>?> getUserActiveWorkout() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return null;
      }

      final response = await _client
          .from('workout_plans')
          .select('*')
          .eq('user_id', userId)
          .eq('is_active', true)
          .maybeSingle();

      return response;
    } catch (error) {
      throw Exception('Failed to fetch active workout: $error');
    }
  }

  // Get all workout categories
  Future<List<dynamic>> getAllCategories() async {
    try {
      final response = await _client
          .from('workout_categories')
          .select('*')
          .order('name', ascending: true);

      return response;
    } catch (error) {
      throw Exception('Failed to fetch categories: $error');
    }
  }
}
