import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';
import '../../../widgets/exercise_3d_widget.dart';
import '../../../widgets/muscle_body_widget.dart';

/// Exercise Detail Bottom Sheet
/// Shows exercise info and embedded YouTube demo video when videoId is available
class ExerciseDetailSheet extends StatefulWidget {
  final Map<String, dynamic> exercise;

  const ExerciseDetailSheet({super.key, required this.exercise});

  @override
  State<ExerciseDetailSheet> createState() => _ExerciseDetailSheetState();
}

class _ExerciseDetailSheetState extends State<ExerciseDetailSheet> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exercise = widget.exercise;
    final name = exercise['name'] as String? ?? 'Exercise';
    final englishName = exercise['englishName'] as String? ?? name;
    final bodyPart = exercise['bodyPart'] as String? ?? '';
    final targetMuscles = exercise['targetMuscles'] as String? ?? '';
    final equipment = exercise['equipment'] as String? ?? '';
    final difficulty = exercise['difficulty'] as String? ?? '';
    final restrictions = exercise['restrictions'] as List? ?? [];

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: EdgeInsets.symmetric(vertical: 1.5.h),
                width: 12.w,
                height: 0.5.h,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 4.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 3.w,
                              vertical: 0.5.h,
                            ),
                            decoration: BoxDecoration(
                              color: _getDifficultyColor(difficulty, theme)
                                  .withAlpha(30),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _getDifficultyColor(difficulty, theme)
                                    .withAlpha(80),
                              ),
                            ),
                            child: Text(
                              difficulty,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: _getDifficultyColor(difficulty, theme),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 1.h),
                      // Info chips
                      Wrap(
                        spacing: 2.w,
                        runSpacing: 1.h,
                        children: [
                          _buildChip(bodyPart, 'sports_gymnastics', theme),
                          _buildChip(equipment, 'fitness_center', theme),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      // 3D exercise demonstration
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Exercise3DWidget(
                          exerciseName: englishName,
                          height: 28.h,
                        ),
                      ),
                      SizedBox(height: 1.5.h),
                      // Muscle body diagram
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF141414),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: EdgeInsets.symmetric(
                            vertical: 1.5.h, horizontal: 2.w),
                        child: MuscleBodyWidget(
                            targetMuscles: targetMuscles),
                      ),
                      SizedBox(height: 2.h),
                      // Target muscles
                      Text(
                        'Target Muscles',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        targetMuscles,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      // Restrictions
                      if (restrictions.isNotEmpty) ...[
                        SizedBox(height: 2.h),
                        Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'warning',
                              color: theme.colorScheme.error,
                              size: 20,
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              'Not recommended for:',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 0.5.h),
                        ...restrictions.map((r) => Padding(
                              padding: EdgeInsets.only(left: 2.w, top: 0.3.h),
                              child: Text(
                                '• $r',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            )),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChip(String label, String iconName, ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.6.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withAlpha(60),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconWidget(
            iconName: iconName,
            color: theme.colorScheme.primary,
            size: 14,
          ),
          SizedBox(width: 1.w),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty, ThemeData theme) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
      case 'începător':
        return Colors.green;
      case 'intermediate':
      case 'intermediar':
        return Colors.orange;
      case 'advanced':
      case 'avansat':
        return Colors.red;
      default:
        return theme.colorScheme.primary;
    }
  }
}
