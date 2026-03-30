import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../widgets/custom_icon_widget.dart';
import '../../../widgets/exercise_3d_widget.dart';
import '../../../widgets/muscle_body_widget.dart';
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
                // Exercise animation — 3D demo (ExerciseDB) or free-exercise-db fallback
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Exercise3DWidget(
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
          SizedBox(height: 1.h),

          // Muscle map — collapsible so it doesn't block the workout flow
          _MuscleMapExpansion(exercise: exercise),

          SizedBox(height: 1.5.h),

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

/// Collapsible muscle-map tile shown below the exercise header card.
class _MuscleMapExpansion extends StatelessWidget {
  final Map<String, dynamic> exercise;

  const _MuscleMapExpansion({required this.exercise});

  /// Builds a comma-separated muscle string from either a List (Supabase
  /// `target_muscle_groups` array) or a plain text field (`muscle_group`).
  String _muscles() {
    final groups = exercise['target_muscle_groups'];
    if (groups is List && groups.isNotEmpty) {
      return groups.join(', ');
    }
    final group = exercise['muscle_group'] as String?;
    if (group != null && group.isNotEmpty) return group;
    // Fallback to description keywords
    return exercise['description'] as String? ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muscles = _muscles();
    if (muscles.isEmpty) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0),
          childrenPadding: EdgeInsets.zero,
          collapsedBackgroundColor:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          backgroundColor:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          leading: CustomIconWidget(
            iconName: 'accessibility_new',
            color: theme.colorScheme.primary,
            size: 20,
          ),
          title: Text(
            'Muscle Map',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          children: [
            Container(
              color: const Color(0xFF141414),
              padding:
                  EdgeInsets.symmetric(vertical: 1.5.h, horizontal: 2.w),
              child: MuscleBodyWidget(targetMuscles: muscles),
            ),
          ],
        ),
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
