import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/supabase_service.dart';

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
      }
    } catch (e) {
      debugPrint('Error loading exercises: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addPR(String exerciseId, String exerciseName) async {
    final weightController = TextEditingController();
    final repsController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Adaugă PR - $exerciseName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Greutate (kg)',
                suffixText: 'kg',
              ),
            ),
            SizedBox(height: 2.h),
            TextField(
              controller: repsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Repetări',
                suffixText: 'reps',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anulează'),
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
            child: const Text('Salvează'),
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PR salvat: ${weight.toStringAsFixed(1)} kg × $reps reps'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_sessionInfo?['name'] ?? 'Exerciții'),
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
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  onPressed: () => _addPR(exercise['id'], name),
                  tooltip: 'Adaugă PR',
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              '$sets seturi × $repsMin-$repsMax repetări',
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
