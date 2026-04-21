import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../services/analytics_service.dart';
import '../../services/supabase_service.dart';
import '../../services/workout_service.dart';
import '../../widgets/custom_icon_widget.dart';
import '../workout_detail_screen/widgets/rest_timer_widget.dart';
import 'widgets/exercise_tracker_widget.dart';
import 'widgets/workout_summary_screen.dart';

/// Live workout session screen — set-by-set tracking with rest timer.
class ActiveWorkoutSession extends StatefulWidget {
  final String sessionId;

  const ActiveWorkoutSession({super.key, required this.sessionId});

  @override
  State<ActiveWorkoutSession> createState() => _ActiveWorkoutSessionState();
}

class _ActiveWorkoutSessionState extends State<ActiveWorkoutSession> {
  // ── data ───────────────────────────────────────────────────────────
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _session;
  List<Map<String, dynamic>> _exercises = [];

  // ── session state ──────────────────────────────────────────────────
  int _currentExerciseIndex = 0;

  /// _allSetLogs[exerciseIndex] = list of set maps:
  /// { set_number, reps, weight_kg, is_completed }
  List<List<Map<String, dynamic>>> _allSetLogs = [];

  // ── rest timer ─────────────────────────────────────────────────────
  bool _isResting = false;
  int _restSeconds = 60;

  // ── elapsed timer ──────────────────────────────────────────────────
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _elapsedTick;
  String _elapsedDisplay = '00:00';

  // ── save state ─────────────────────────────────────────────────────
  bool _isSaving = false;

  final _workoutService = WorkoutService();

  // ── lifecycle ──────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  @override
  void dispose() {
    _elapsedTick?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  // ── data loading ───────────────────────────────────────────────────

  Future<void> _loadSession() async {
    try {
      final sessionRes = await SupabaseService.instance.client
          .from('workout_sessions')
          .select('id, session_name, focus_area, estimated_duration_minutes')
          .eq('id', widget.sessionId)
          .single()
          .timeout(const Duration(seconds: 15));

      final exercisesRes = await SupabaseService.instance.client
          .from('session_exercises')
          .select('id, sets, reps_min, reps_max, rest_seconds, order_in_session, exercises(*)')
          .eq('session_id', widget.sessionId)
          .order('order_in_session', ascending: true)
          .timeout(const Duration(seconds: 15));

      final exercises =
          List<Map<String, dynamic>>.from(exercisesRes as List);

      // Initialise empty set log lists per exercise
      final allSetLogs = exercises.map((ex) {
        final sets = ex['sets'] as int? ?? 3;
        return List<Map<String, dynamic>>.generate(
          sets,
          (i) => {
            'set_number': i + 1,
            'reps': null,
            'weight_kg': null,
            'is_completed': false,
          },
        );
      }).toList();

      setState(() {
        _session = sessionRes;
        _exercises = exercises;
        _allSetLogs = allSetLogs;
        _isLoading = false;
      });

      // Start elapsed timer
      _stopwatch.start();
      _elapsedTick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {
            _elapsedDisplay = _formatElapsed(_stopwatch.elapsed);
          });
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load workout: $e';
        _isLoading = false;
      });
    }
  }

  // ── set completion ─────────────────────────────────────────────────

  void _onSetCompleted(int setIndex, int reps, double? weightKg) {
    setState(() {
      _allSetLogs[_currentExerciseIndex][setIndex] = {
        'set_number': setIndex + 1,
        'reps': reps,
        'weight_kg': weightKg,
        'is_completed': true,
      };
    });

    // Show rest timer
    final restSecs =
        _exercises[_currentExerciseIndex]['rest_seconds'] as int? ?? 60;
    setState(() {
      _restSeconds = restSecs;
      _isResting = true;
    });
    HapticFeedback.mediumImpact();
  }

  void _onRestComplete() {
    setState(() => _isResting = false);
    HapticFeedback.lightImpact();

    // Check if all sets for current exercise are done
    final logs = _allSetLogs[_currentExerciseIndex];
    final allDone = logs.every((s) => s['is_completed'] == true);
    if (allDone && _currentExerciseIndex < _exercises.length - 1) {
      _advanceExercise();
    }
  }

  void _onSkipExercise() {
    setState(() => _isResting = false);
    if (_currentExerciseIndex < _exercises.length - 1) {
      _advanceExercise();
    }
  }

  void _advanceExercise() {
    setState(() => _currentExerciseIndex++);
    HapticFeedback.lightImpact();
  }

  void _goBack() {
    if (_currentExerciseIndex > 0) {
      setState(() => _currentExerciseIndex--);
    }
  }

  // ── finish workout ─────────────────────────────────────────────────

  Future<void> _finishWorkout() async {
    _stopwatch.stop();
    _elapsedTick?.cancel();

    setState(() => _isSaving = true);

    // Capture context-dependent objects before async gap
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      // Flatten all set logs
      final flatLogs = <Map<String, dynamic>>[];
      for (int i = 0; i < _exercises.length; i++) {
        final ex = _exercises[i];
        for (final setLog in _allSetLogs[i]) {
          if (setLog['reps'] != null) {
            flatLogs.add({
              'session_exercise_id': ex['id'],
              'exercise_id': (ex['exercises'] as Map)['id'],
              'set_number': setLog['set_number'],
              'reps': setLog['reps'],
              'weight_kg': setLog['weight_kg'],
              'is_completed': setLog['is_completed'],
            });
          }
        }
      }

      final result = await _workoutService.saveCompletedWorkout(
        sessionId: widget.sessionId,
        durationSeconds: _stopwatch.elapsed.inSeconds,
        setLogs: flatLogs,
      );

      unawaited(AnalyticsService.instance.trackFirstOnce(
          'first_workout_logged', 'analytics_first_workout_logged'));
      unawaited(_maybeRequestReview());

      if (!mounted) return;

      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (_) => WorkoutSummaryScreen(
            sessionName:
                _session?['session_name'] as String? ?? 'Workout',
            workoutLog: result['workoutLog'] as Map<String, dynamic>,
            setLogs: flatLogs,
            newPRs: List<Map<String, dynamic>>.from(
                result['newPRs'] as List),
            exercises: _exercises,
            durationSeconds: _stopwatch.elapsed.inSeconds,
          ),
        ),
      );
    } catch (e) {
      setState(() => _isSaving = false);
      _stopwatch.start(); // resume timer if save failed
      _elapsedTick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() => _elapsedDisplay = _formatElapsed(_stopwatch.elapsed));
        }
      });
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to save workout: $e')),
      );
    }
  }

  // ── in-app review ─────────────────────────────────────────────────

  Future<void> _maybeRequestReview() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('review_asked') == true) return;

      final user = SupabaseService.instance.client.auth.currentUser;
      if (user == null) return;
      final signupDate = DateTime.tryParse(user.createdAt) ?? DateTime.now();
      if (DateTime.now().difference(signupDate).inDays < 7) return;

      final count = await _getCompletedWorkoutCount();
      if (count < 3) return;

      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        await review.requestReview();
        await prefs.setBool('review_asked', true);
      }
    } catch (_) {}
  }

  Future<int> _getCompletedWorkoutCount() async {
    try {
      final userId = SupabaseService.instance.client.auth.currentUser?.id;
      if (userId == null) return 0;
      final res = await SupabaseService.instance.client
          .from('workout_logs')
          .select('id')
          .eq('user_id', userId)
          .count();
      return res.count;
    } catch (_) {
      return 0;
    }
  }

  // ── quit confirmation ──────────────────────────────────────────────

  Future<bool> _confirmQuit() async {
    _stopwatch.stop();
    final quit = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Quit Workout?'),
        content: const Text('Progress will be lost. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Going'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Quit',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (quit != true) {
      _stopwatch.start(); // resume
    }
    return quit == true;
  }

  // ── helpers ────────────────────────────────────────────────────────

  String _formatElapsed(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  bool get _isLastExercise =>
      _currentExerciseIndex == _exercises.length - 1;

  bool get _currentExerciseHasAnySet =>
      _currentExerciseIndex < _allSetLogs.length &&
      _allSetLogs[_currentExerciseIndex]
          .any((s) => s['is_completed'] == true);

  // ── build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workout')),
        body: Center(child: Text(_errorMessage!)),
      );
    }

    final theme = Theme.of(context);
    final sessionName =
        _session?['session_name'] as String? ?? 'Workout';
    final total = _exercises.length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        final ok = await _confirmQuit();
        if (ok && mounted) nav.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(sessionName),
          centerTitle: true,
          actions: [
            Padding(
              padding: EdgeInsets.only(right: 4.w),
              child: Center(
                child: Text(
                  _elapsedDisplay,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                // Progress bar
                _buildProgressBar(theme, total),

                // Exercise tracker
                Expanded(
                  child: _exercises.isEmpty
                      ? const Center(child: Text('No exercises'))
                      : ExerciseTrackerWidget(
                          sessionExercise:
                              _exercises[_currentExerciseIndex],
                          setLogs:
                              _allSetLogs[_currentExerciseIndex],
                          onSetCompleted: _onSetCompleted,
                          onSkip: _onSkipExercise,
                        ),
                ),

                // Bottom action bar
                _buildBottomBar(theme),
              ],
            ),

            // Rest timer overlay
            if (_isResting)
              Positioned.fill(
                child: Container(
                  color: Colors.black54,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6.w),
                      child: RestTimerWidget(
                        restSeconds: _restSeconds,
                        onTimerComplete: _onRestComplete,
                        onSkip: _onRestComplete,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(ThemeData theme, int total) {
    final progress =
        total > 0 ? (_currentExerciseIndex + 1) / total : 0.0;
    return Container(
      color: theme.colorScheme.surface,
      padding: EdgeInsets.fromLTRB(4.w, 1.h, 4.w, 1.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Exercise ${_currentExerciseIndex + 1} of $total',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: List.generate(
                  total,
                  (i) => Container(
                    margin: EdgeInsets.only(left: 1.w),
                    width: i == _currentExerciseIndex ? 16 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: i <= _currentExerciseIndex
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 0.8.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor:
                  theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    return Container(
      padding: EdgeInsets.fromLTRB(4.w, 1.5.h, 4.w, 2.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_currentExerciseIndex > 0)
              Padding(
                padding: EdgeInsets.only(right: 3.w),
                child: OutlinedButton.icon(
                  onPressed: _goBack,
                  icon: CustomIconWidget(
                    iconName: 'arrow_back',
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  label: const Text('Back'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                        horizontal: 4.w, vertical: 1.5.h),
                  ),
                ),
              ),
            Expanded(
              child: _isSaving
                  ? const Center(child: CircularProgressIndicator())
                  : _isLastExercise
                      ? ElevatedButton.icon(
                          onPressed: _finishWorkout,
                          icon: CustomIconWidget(
                            iconName: 'check',
                            color: theme.colorScheme.onPrimary,
                            size: 22,
                          ),
                          label: const Text('Finish Workout'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            padding:
                                EdgeInsets.symmetric(vertical: 1.8.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: _currentExerciseHasAnySet
                              ? _advanceExercise
                              : null,
                          icon: CustomIconWidget(
                            iconName: 'arrow_forward',
                            color: theme.colorScheme.onPrimary,
                            size: 22,
                          ),
                          label: const Text('Next Exercise'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            padding:
                                EdgeInsets.symmetric(vertical: 1.8.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
