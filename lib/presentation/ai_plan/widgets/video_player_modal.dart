import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../widgets/exercise_3d_widget.dart';
import '../../../widgets/muscle_body_widget.dart';

/// Bottom-sheet modal showing the 3D exercise demonstration and muscle map.
///
/// Previously used an embedded YouTube player — now replaced with
/// [Exercise3DWidget] (ExerciseDB animated GIF / free-exercise-db fallback)
/// plus [MuscleBodyWidget] for muscle targeting visualisation.
class VideoPlayerModal extends StatelessWidget {
  final String videoUrl; // kept for API compat, no longer used for YouTube
  final String exerciseName;
  final String targetMuscles;

  const VideoPlayerModal({
    super.key,
    required this.videoUrl,
    required this.exerciseName,
    this.targetMuscles = '',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 80.h,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: EdgeInsets.only(top: 1.h),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withAlpha(80),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(4.w, 1.5.h, 2.w, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    exerciseName,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(4.w, 1.h, 4.w, 4.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 3D exercise demonstration
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Exercise3DWidget(
                      exerciseName: exerciseName,
                      height: 28.h,
                    ),
                  ),
                  SizedBox(height: 2.h),

                  // Muscle map
                  if (targetMuscles.isNotEmpty) ...[
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF141414),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: EdgeInsets.symmetric(
                          vertical: 1.5.h, horizontal: 2.w),
                      child:
                          MuscleBodyWidget(targetMuscles: targetMuscles),
                    ),
                    SizedBox(height: 2.h),
                  ],

                  // How to perform
                  Text(
                    'How to Perform',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Watch the animation above for proper form and technique. '
                    'Make sure to warm up before starting and maintain proper form throughout the exercise.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
