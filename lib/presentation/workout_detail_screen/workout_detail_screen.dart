import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/supabase_service.dart';
import './widgets/exercise_card_widget.dart';

class WorkoutDetailScreen extends StatefulWidget {
  const WorkoutDetailScreen({super.key});

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _workoutSession;
  List<Map<String, dynamic>> _exercises = [];
  String? _errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args == null) {
      _showError('Date invalide');
      return;
    }

    // Case 1: Navigating from a workout session list
    if (args['sessionId'] != null) {
      _loadWorkoutSession(args['sessionId'] as String);
    }
    // Case 2: Navigating from the exercise library with a single exercise
    else if (args['id'] != null && args['name'] != null) {
      _loadSingleExercise(args);
    }
    // Invalid arguments
    else {
      _showError('Sesiune de antrenament sau exercițiu invalid');
    }
  }

  void _showError(String message) {
    setState(() {
      _isLoading = false;
      _errorMessage = message;
    });
  }

  Future<void> _loadSingleExercise(Map<String, dynamic> exerciseData) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Adapt the single exercise data to fit the screen's data structure.
    // Create a mock session and a single-item exercise list.
    _workoutSession = {
      'session_name': exerciseData['name'],
      'focus_area': exerciseData['targetMuscles'],
      'estimated_duration_minutes': 5, // Placeholder
    };

    // The exercise data from library doesn't have sets/reps info, so we create a placeholder.
    _exercises = [
      {
        'exercises': exerciseData,
        'sets': 3,
        'reps_min': 8,
        'reps_max': 12,
        'rest_seconds': 60,
        'order_in_session': 1,
      }
    ];

    setState(() => _isLoading = false);
  }

  Future<void> _loadWorkoutSession(String sessionId) async {
    try {
      setState(() => _isLoading = true);

      // Load workout session with exercises
      final sessionResponse = await SupabaseService.instance.client
          .from('workout_sessions')
          .select('*, workout_categories(*)')
          .eq('id', sessionId)
          .single();

      // Load exercises for this session
      final exercisesResponse = await SupabaseService.instance.client
          .from('session_exercises')
          .select('*, exercises(*)')
          .eq('session_id', sessionId)
          .order('order_in_session', ascending: true);

      setState(() {
        _workoutSession = sessionResponse;
        _exercises = List<Map<String, dynamic>>.from(exercisesResponse);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Eroare la încărcarea antrenamentului: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _finishWorkout() async {
    if (_workoutSession == null) return;

    try {
      setState(() => _isLoading = true);
      final userId = SupabaseService.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // 1. Log the workout
      await SupabaseService.instance.client.from('workout_logs').insert({
        'user_id': userId,
        'session_id': _workoutSession!['id'],
        'duration_seconds': (_workoutSession!['estimated_duration_minutes'] ?? 60) * 60,
        'completed_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;

      // 2. Show success and pop
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Antrenament finalizat cu succes!'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context, true); // Return true to signal refresh

    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare la salvare: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Eroare')),
        body: Center(child: Text(_errorMessage!)),
      );
    }

    if (_workoutSession == null) {
      return const Scaffold(
        body: Center(child: Text('Sesiune de antrenament negăsită')),
      );
    }

    final sessionName = _workoutSession!['session_name'] ?? 'Antrenament';
    final focusArea = _workoutSession!['focus_area'] ?? '';
    final duration = _workoutSession!['estimated_duration_minutes'] ?? 60;

    return Scaffold(
      appBar: AppBar(title: Text(sessionName), centerTitle: true),
      body: Column(
        children: [
          // Workout session header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade700, Colors.blue.shade500],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sessionName,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 1.h),
                if (focusArea.isNotEmpty)
                  Text(
                    'Focus: $focusArea',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.white.withAlpha(230),
                    ),
                  ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.white, size: 16.sp),
                    SizedBox(width: 1.w),
                    Text(
                      '$duration min',
                      style: TextStyle(color: Colors.white, fontSize: 14.sp),
                    ),
                    SizedBox(width: 4.w),
                    Icon(
                      Icons.fitness_center,
                      color: Colors.white,
                      size: 16.sp,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      '${_exercises.length} exerciții',
                      style: TextStyle(color: Colors.white, fontSize: 14.sp),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Exercises list
          Expanded(
            child: _exercises.isEmpty
                ? const Center(child: Text('Niciun exercițiu disponibil'))
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(3.w, 3.w, 3.w, 10.h), // Add bottom padding for button
                    itemCount: _exercises.length,
                    itemBuilder: (context, index) {
                      final sessionExercise = _exercises[index];
                      final exercise =
                          sessionExercise['exercises'] as Map<String, dynamic>;
                      return ExerciseCardWidget(
                        exercise: exercise,
                        sets: sessionExercise['sets'] ?? 3,
                        reps:
                            '${sessionExercise['reps_min'] ?? 8}-${sessionExercise['reps_max'] ?? 12}',
                        restSeconds: sessionExercise['rest_seconds'] ?? 60,
                        orderIndex: sessionExercise['order_in_session'] ?? 0,
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _finishWorkout,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 2.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
            child: Text(
              'Finalizează Antrenamentul',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
