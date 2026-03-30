import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../widgets/exercise_3d_widget.dart';
import '../../ai_plan/widgets/video_player_modal.dart';

class ExerciseCardWidget extends StatelessWidget {
  final Map<String, dynamic> exercise;
  final int sets;
  final String reps;
  final int restSeconds;
  final int orderIndex;

  const ExerciseCardWidget({
    super.key,
    required this.exercise,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    required this.orderIndex,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Support both nested (session_exercises join) and flat exercise maps
    final exData = exercise['exercises'] as Map<String, dynamic>? ?? exercise;
    final name = exData['name'] as String? ?? 'Exercise';
    final videoUrl = exData['video_url'] as String? ?? '';
    // Build muscle string from array or text field
    final muscleGroups = exData['target_muscle_groups'];
    final muscles = muscleGroups is List
        ? muscleGroups.join(', ')
        : (exData['muscle_group'] as String? ?? '');

    return Card(
      margin: EdgeInsets.symmetric(vertical: 1.h, horizontal: 2.w),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => VideoPlayerModal(
              videoUrl: videoUrl,
              exerciseName: name,
              targetMuscles: muscles,
            ),
          );
        },
        child: Row(
          children: [
            // Exercise animation thumbnail
            SizedBox(
              width: 25.w,
              height: 25.w,
              child: Exercise3DWidget(
                exerciseName: name,
                height: 25.w,
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      '$sets sets x $reps reps',
                      style: theme.textTheme.bodyMedium,
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      'Rest: $restSeconds seconds',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
