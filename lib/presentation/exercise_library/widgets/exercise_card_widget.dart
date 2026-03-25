import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ExerciseCardWidget extends StatelessWidget {
  final Map<String, dynamic> exercise;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const ExerciseCardWidget({
    super.key,
    required this.exercise,
    required this.onTap,
    required this.onLongPress,
  });

  Color _getDifficultyColor(String difficulty, ThemeData theme) {
    switch (difficulty) {
      case 'Beginner':
        return theme.colorScheme.tertiary;
      case 'Intermediate':
        return const Color(0xFFFF6F00);
      case 'Advanced':
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final difficulty = exercise['difficulty'] as String? ?? '';
    final diffColor = _getDifficultyColor(difficulty, theme);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.6.h),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: theme.colorScheme.shadow.withAlpha(30),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: exercise image (fixed square)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: SizedBox(
                  width: 24.w,
                  height: 22.w,
                  child: CustomImageWidget(
                    imageUrl: exercise['image'],
                    fit: BoxFit.cover,
                    semanticLabel:
                        exercise['semanticLabel'] ?? exercise['name'],
                  ),
                ),
              ),
              // Difficulty accent strip
              Container(width: 3, height: 22.w, color: diffColor),
              // Right: info
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 1.5.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        exercise['name'],
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 0.5.h),
                      Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'adjust',
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 11,
                          ),
                          SizedBox(width: 1.w),
                          Expanded(
                            child: Text(
                              exercise['targetMuscles'],
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 1.2.h),
                      Row(
                        children: [
                          _InfoChip(
                            label: exercise['equipment'],
                            color: theme.colorScheme.primary,
                            bgColor:
                                theme.colorScheme.primary.withAlpha(18),
                            iconName: 'fitness_center',
                            theme: theme,
                          ),
                          SizedBox(width: 2.w),
                          _InfoChip(
                            label: difficulty,
                            color: diffColor,
                            bgColor: diffColor.withAlpha(22),
                            theme: theme,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Chevron
              Padding(
                padding: EdgeInsets.only(right: 3.w),
                child: CustomIconWidget(
                  iconName: 'chevron_right',
                  color: theme.colorScheme.onSurfaceVariant.withAlpha(100),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;
  final String? iconName;
  final ThemeData theme;

  const _InfoChip({
    required this.label,
    required this.color,
    required this.bgColor,
    required this.theme,
    this.iconName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.4.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconName != null) ...[
            CustomIconWidget(iconName: iconName!, color: color, size: 10),
            SizedBox(width: 1.w),
          ],
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
