import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../widgets/custom_icon_widget.dart';
import '../../../widgets/custom_image_widget.dart';
import '../../ai_plan/widgets/video_player_modal.dart';
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
    final videoUrl = exercise['video_url'] as String?;
    final imageUrl = exercise['image'] as String?;

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
                // Thumbnail + play overlay
                if (videoUrl != null || imageUrl != null)
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: InkWell(
                      onTap: videoUrl != null
                          ? () {
                              HapticFeedback.lightImpact();
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => VideoPlayerModal(
                                  videoUrl: videoUrl,
                                  exerciseName: name,
                                ),
                              );
                            }
                          : null,
                      child: Stack(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 22.h,
                            child: CustomImageWidget(
                              imageUrl: imageUrl ?? '',
                              fit: BoxFit.cover,
                            ),
                          ),
                          if (videoUrl != null)
                            Positioned.fill(
                              child: Container(
                                color: Colors.black26,
                                child: Center(
                                  child: CustomIconWidget(
                                    iconName: 'play_circle_fill',
                                    color: Colors.white,
                                    size: 48,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
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
