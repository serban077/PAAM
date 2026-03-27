import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../utils/exercise_gif_utils.dart';
import '../../../widgets/custom_icon_widget.dart';
import 'set_row_widget.dart';

/// Displays the current exercise with interactive set-logging rows.
/// Stateless — all state lives in the parent (ActiveWorkoutSession).
class ExerciseTrackerWidget extends StatelessWidget {
  final Map<String, dynamic> sessionExercise; // session_exercises row joined with exercises
  final List<Map<String, dynamic>> setLogs;   // current state for each set

  /// Called when a set is marked complete. Provides set index (0-based), reps, weight.
  final void Function(int setIndex, int reps, double? weightKg) onSetCompleted;

  /// Called when user wants to skip this exercise entirely.
  final VoidCallback onSkip;

  const ExerciseTrackerWidget({
    super.key,
    required this.sessionExercise,
    required this.setLogs,
    required this.onSetCompleted,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exercise = sessionExercise['exercises'] as Map<String, dynamic>;
    final name = exercise['name'] as String? ?? 'Exercise';
    final sets = sessionExercise['sets'] as int? ?? 3;
    final repsMin = sessionExercise['reps_min'] as int? ?? 8;
    final repsMax = sessionExercise['reps_max'] as int? ?? 12;
    final restSeconds = sessionExercise['rest_seconds'] as int? ?? 60;
    final completedCount =
        setLogs.where((s) => s['is_completed'] == true).length;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise header card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                  color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Exercise animation — alternates between start and end position
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: _ExerciseAnimationWidget(
                      exerciseName: name, height: 22.h),
                ),

                Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 1.5.h),

                      // Info chips row
                      Wrap(
                        spacing: 2.w,
                        children: [
                          _InfoChip(
                            icon: 'fitness_center',
                            label: '$sets sets',
                            color: theme.colorScheme.primary,
                          ),
                          _InfoChip(
                            icon: 'repeat',
                            label: '$repsMin–$repsMax reps',
                            color: theme.colorScheme.secondary,
                          ),
                          _InfoChip(
                            icon: 'timer',
                            label: '${restSeconds}s rest',
                            color: theme.colorScheme.tertiary,
                          ),
                        ],
                      ),
                      SizedBox(height: 1.h),

                      // Progress text
                      Text(
                        '$completedCount / $sets sets completed',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),

          // Set rows
          Text(
            'Log Your Sets',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 1.h),

          ...List.generate(sets, (i) {
            final log = i < setLogs.length ? setLogs[i] : <String, dynamic>{};
            final isCompleted = log['is_completed'] == true;

            // Use previous set's weight as hint
            double? prevWeight;
            if (i > 0 && i - 1 < setLogs.length) {
              final prev = setLogs[i - 1];
              if (prev['weight_kg'] != null) {
                prevWeight = (prev['weight_kg'] as num).toDouble();
              }
            }

            return SetRowWidget(
              key: ValueKey('set_${sessionExercise['id']}_$i'),
              setNumber: i + 1,
              repsMin: repsMin,
              repsMax: repsMax,
              isCompleted: isCompleted,
              previousWeight: prevWeight,
              onCompleted: (reps, weightKg) =>
                  onSetCompleted(i, reps, weightKg),
            );
          }),
          SizedBox(height: 1.5.h),

          // Skip exercise
          Center(
            child: TextButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                onSkip();
              },
              icon: CustomIconWidget(
                iconName: 'skip_next',
                color: theme.colorScheme.onSurfaceVariant,
                size: 18,
              ),
              label: Text(
                'Skip Exercise',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Animates between the start-position and end-position frames for an exercise.
/// Uses the free-exercise-db GitHub CDN (real-person technique photos).
/// Falls back to a placeholder icon when no images are mapped.
class _ExerciseAnimationWidget extends StatefulWidget {
  final String exerciseName;
  final double height;

  const _ExerciseAnimationWidget({
    required this.exerciseName,
    required this.height,
  });

  @override
  State<_ExerciseAnimationWidget> createState() =>
      _ExerciseAnimationWidgetState();
}

class _ExerciseAnimationWidgetState
    extends State<_ExerciseAnimationWidget> {
  bool _showFrame1 = false;
  Timer? _timer;

  String? get _f0 => ExerciseGifUtils.getFrame0Url(widget.exerciseName);
  String? get _f1 => ExerciseGifUtils.getFrame1Url(widget.exerciseName);

  @override
  void initState() {
    super.initState();
    if (_f0 != null && _f1 != null) {
      // Flip between frames every 1.1 s (slow enough to see the form)
      _timer = Timer.periodic(const Duration(milliseconds: 1100), (_) {
        if (mounted) setState(() => _showFrame1 = !_showFrame1);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f0 = _f0;
    final f1 = _f1;
    final bg = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1A1A1A)
        : const Color(0xFF2A2A2A);

    if (f0 == null) return _placeholder(bg);

    final url = (_showFrame1 && f1 != null) ? f1 : f0;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: CachedNetworkImage(
        key: ValueKey(url),
        imageUrl: url,
        width: double.infinity,
        height: widget.height,
        fit: BoxFit.cover,
        fadeInDuration: const Duration(milliseconds: 200),
        placeholder: (_, __) => Container(
          width: double.infinity,
          height: widget.height,
          color: bg,
          child: const Center(
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white38),
          ),
        ),
        errorWidget: (_, __, ___) => _placeholder(bg),
      ),
    );
  }

  Widget _placeholder(Color bg) {
    return Container(
      width: double.infinity,
      height: widget.height,
      color: bg,
      child: const Center(
        child: Icon(Icons.fitness_center, color: Colors.white24, size: 48),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconWidget(iconName: icon, color: color, size: 14),
          SizedBox(width: 1.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
