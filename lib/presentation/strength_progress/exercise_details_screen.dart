import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/supabase_service.dart';
import '../../widgets/custom_icon_widget.dart';

/// Exercise Details Screen - Shows exercises with PR tracking
class ExerciseDetailsScreen extends StatefulWidget {
  final String sessionId;

  const ExerciseDetailsScreen({super.key, required this.sessionId});

  @override
  State<ExerciseDetailsScreen> createState() => _ExerciseDetailsScreenState();
}

class _ExerciseDetailsScreenState extends State<ExerciseDetailsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _exercises = [];
  Map<String, dynamic>? _sessionInfo;
  Map<String, double?> _exercisePRs = {};

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    try {
      setState(() => _isLoading = true);
      
      // Get session info
      final sessionResponse = await SupabaseService.instance.client
          .from('workout_sessions')
          .select('name, focus_area')
          .eq('id', widget.sessionId)
          .single();

      // Get exercises for this session
      final exercisesResponse = await SupabaseService.instance.client
          .from('session_exercises')
          .select('''
            id,
            sets,
            reps_min,
            reps_max,
            order_in_session,
            exercises (
              id,
              name,
              target_muscle_groups
            )
          ''')
          .eq('session_id', widget.sessionId)
          .order('order_in_session');

      if (mounted) {
        setState(() {
          _sessionInfo = sessionResponse;
          _exercises = List<Map<String, dynamic>>.from(exercisesResponse);
          _isLoading = false;
        });
        _loadExercisePRs(
          _exercises
              .map((e) => (e['exercises'] as Map)['id'] as String)
              .toList(),
        );
      }
    } catch (e) {
      debugPrint('Error loading exercises: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadExercisePRs(List<String> exerciseIds) async {
    if (exerciseIds.isEmpty) return;
    try {
      final userId = SupabaseService.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await SupabaseService.instance.client
          .from('strength_progress')
          .select('exercise_id, weight_kg')
          .eq('user_id', userId)
          .inFilter('exercise_id', exerciseIds);

      final data = List<Map<String, dynamic>>.from(response);
      final Map<String, double?> maxWeights = {};
      for (final row in data) {
        final id = row['exercise_id'] as String;
        final weight = (row['weight_kg'] as num).toDouble();
        if (!maxWeights.containsKey(id) || weight > (maxWeights[id] ?? 0)) {
          maxWeights[id] = weight;
        }
      }

      if (mounted) setState(() => _exercisePRs = maxWeights);
    } catch (e) {
      debugPrint('Error loading PRs: $e');
    }
  }

  Future<void> _addPR(String exerciseId, String exerciseName) async {
    final weightController = TextEditingController();
    final repsController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add PR - $exerciseName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Weight (kg)',
                suffixText: 'kg',
              ),
            ),
            SizedBox(height: 2.h),
            TextField(
              controller: repsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Reps',
                suffixText: 'reps',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final weight = double.tryParse(weightController.text);
              final reps = int.tryParse(repsController.text);
              
              if (weight != null && reps != null && weight > 0 && reps > 0) {
                Navigator.pop(context, {
                  'weight': weight,
                  'reps': reps,
                });
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _savePR(exerciseId, result['weight'], result['reps']);
    }
  }

  Future<void> _savePR(String exerciseId, double weight, int reps) async {
    try {
      final userId = SupabaseService.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      await SupabaseService.instance.client
          .from('strength_progress')
          .insert({
            'user_id': userId,
            'exercise_id': exerciseId,
            'session_id': widget.sessionId,
            'weight_kg': weight,
            'reps': reps,
          });

      if (!mounted) return;

      final currentMax = _exercisePRs[exerciseId];
      final isNewPR = currentMax == null || weight > currentMax;

      if (isNewPR) {
        setState(() => _exercisePRs[exerciseId] = weight);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('New PR! ${weight.toStringAsFixed(1)} kg × $reps reps'),
            backgroundColor: Colors.amber[700],
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PR saved: ${weight.toStringAsFixed(1)} kg × $reps reps'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_sessionInfo?['name'] ?? 'Exercises'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: EdgeInsets.all(4.w),
              itemCount: _exercises.length,
              itemBuilder: (context, index) {
                final exercise = _exercises[index];
                final exerciseData = exercise['exercises'] as Map<String, dynamic>;
                return _buildExerciseCard(exercise, exerciseData);
              },
            ),
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> sessionExercise, Map<String, dynamic> exercise) {
    final theme = Theme.of(context);
    final name = exercise['name'] ?? 'Exercise';
    final sets = sessionExercise['sets'] ?? 3;
    final repsMin = sessionExercise['reps_min'] ?? 8;
    final repsMax = sessionExercise['reps_max'] ?? 12;
    final exerciseId = exercise['id'] as String;
    final currentPR = _exercisePRs[exerciseId];

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (currentPR != null)
                  Container(
                    margin: EdgeInsets.only(right: 1.w),
                    padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                    decoration: BoxDecoration(
                      color: Colors.amber[700],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomIconWidget(
                          iconName: 'emoji_events',
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'PR ${currentPR.toStringAsFixed(1)} kg',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  onPressed: () => _addPR(exerciseId, name),
                  tooltip: 'Add PR',
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              '$sets sets × $repsMin-$repsMax reps',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
