import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import 'package:flutter/foundation.dart';

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

  // Get plan_id for a given session
  Future<String?> getPlanIdForSession(String sessionId) async {
    try {
      final response = await _client
          .from('workout_sessions')
          .select('plan_id')
          .eq('id', sessionId)
          .single()
          .timeout(const Duration(seconds: 15));
      return response['plan_id'] as String?;
    } catch (error) {
      debugPrint('getPlanIdForSession error: $error');
      return null;
    }
  }

  /// Saves a completed workout session with all per-set data.
  /// Returns {'workoutLog': Map, 'newPRs': List<Map>}.
  Future<Map<String, dynamic>> saveCompletedWorkout({
    required String sessionId,
    required int durationSeconds,
    required List<Map<String, dynamic>> setLogs,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Calculate total volume: sum of weight_kg * reps for completed sets
      double totalVolume = 0;
      for (final s in setLogs) {
        if (s['is_completed'] == true && s['weight_kg'] != null) {
          totalVolume += (s['weight_kg'] as num).toDouble() *
              (s['reps'] as num).toDouble();
        }
      }

      // Insert workout_logs row
      final workoutLog = await _client
          .from('workout_logs')
          .insert({
            'user_id': userId,
            'session_id': sessionId,
            'duration_seconds': durationSeconds,
            'total_volume_kg': totalVolume,
            'completed_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single()
          .timeout(const Duration(seconds: 15));

      final workoutLogId = workoutLog['id'] as String;

      // Batch insert set logs (only sets that have reps data)
      final validSetLogs = setLogs
          .where((s) => s['reps'] != null)
          .map((s) => {
                'workout_log_id': workoutLogId,
                'session_exercise_id': s['session_exercise_id'],
                'exercise_id': s['exercise_id'],
                'set_number': s['set_number'],
                'reps': s['reps'],
                'weight_kg': s['weight_kg'],
                'is_completed': s['is_completed'] ?? true,
              })
          .toList();

      if (validSetLogs.isNotEmpty) {
        await _client
            .from('workout_set_logs')
            .insert(validSetLogs)
            .timeout(const Duration(seconds: 15));
      }

      // Auto-detect and save PRs
      final newPRs = await _autoDetectPRs(userId, setLogs, sessionId);

      return {'workoutLog': workoutLog, 'newPRs': newPRs};
    } catch (error) {
      throw Exception('saveCompletedWorkout failed: $error');
    }
  }

  /// Compares best weight per exercise in this session against existing PRs.
  /// Inserts new strength_progress rows for exercises where a new PR was set.
  Future<List<Map<String, dynamic>>> _autoDetectPRs(
    String userId,
    List<Map<String, dynamic>> setLogs,
    String sessionId,
  ) async {
    try {
      // Group completed sets by exercise_id, find max weight
      final Map<String, Map<String, dynamic>> bestByExercise = {};
      for (final s in setLogs) {
        if (s['is_completed'] != true || s['weight_kg'] == null) continue;
        final exId = s['exercise_id'] as String;
        final weight = (s['weight_kg'] as num).toDouble();
        final reps = s['reps'] as int;
        if (!bestByExercise.containsKey(exId) ||
            weight > (bestByExercise[exId]!['weight_kg'] as double)) {
          bestByExercise[exId] = {'weight_kg': weight, 'reps': reps};
        }
      }

      if (bestByExercise.isEmpty) return [];

      // Fetch existing PR for each exercise
      final exerciseIds = bestByExercise.keys.toList();
      final existing = await _client
          .from('strength_progress')
          .select('exercise_id, weight_kg')
          .eq('user_id', userId)
          .inFilter('exercise_id', exerciseIds)
          .timeout(const Duration(seconds: 15));

      final Map<String, double> existingMax = {};
      for (final row in existing as List) {
        final id = row['exercise_id'] as String;
        final w = (row['weight_kg'] as num).toDouble();
        if (!existingMax.containsKey(id) || w > existingMax[id]!) {
          existingMax[id] = w;
        }
      }

      // Insert new PRs where session best > existing max
      final List<Map<String, dynamic>> newPRs = [];
      for (final entry in bestByExercise.entries) {
        final exId = entry.key;
        final sessionBest = entry.value['weight_kg'] as double;
        final existingBest = existingMax[exId];
        if (existingBest == null || sessionBest > existingBest) {
          await _client.from('strength_progress').insert({
            'user_id': userId,
            'exercise_id': exId,
            'session_id': sessionId,
            'weight_kg': sessionBest,
            'reps': entry.value['reps'],
          }).timeout(const Duration(seconds: 15));
          newPRs.add({
            'exercise_id': exId,
            'weight_kg': sessionBest,
            'reps': entry.value['reps'],
          });
        }
      }

      return newPRs;
    } catch (error) {
      debugPrint('_autoDetectPRs error: $error');
      return [];
    }
  }

  /// Gets all set logs for a completed workout, joined with exercise names.
  Future<List<Map<String, dynamic>>> getWorkoutSetLogs(
      String workoutLogId) async {
    try {
      final response = await _client
          .from('workout_set_logs')
          .select('*, exercises(name)')
          .eq('workout_log_id', workoutLogId)
          .order('session_exercise_id', ascending: true)
          .order('set_number', ascending: true)
          .timeout(const Duration(seconds: 15));
      return List<Map<String, dynamic>>.from(response as List);
    } catch (error) {
      throw Exception('getWorkoutSetLogs failed: $error');
    }
  }
}
