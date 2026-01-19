import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
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
    final videoUrl = exercise['exercises'] != null ? exercise['exercises']['video_url'] : exercise['video_url'];

    return Card(
      margin: EdgeInsets.symmetric(vertical: 1.h, horizontal: 2.w),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (videoUrl != null) {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => VideoPlayerModal(
                videoUrl: videoUrl,
                exerciseName: exercise['name'] ?? 'Exercițiu',
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Video indisponibil pentru acest exercițiu')),
            );
          }
        },
        child: Row(
          children: [
            SizedBox(
              width: 25.w,
              height: 25.w,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomImageWidget(
                    imageUrl: exercise['image'],
                    fit: BoxFit.cover,
                  ),
                  if (videoUrl != null)
                    Container(
                      color: Colors.black26,
                      child: const Center(
                        child: Icon(Icons.play_circle_fill, color: Colors.white, size: 30),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise['name'],
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      '$sets seturi x $reps repetări',
                      style: theme.textTheme.bodyMedium,
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      'Pauză: $restSeconds secunde',
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
