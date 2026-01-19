import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/ai_plan_models.dart';
import 'video_player_modal.dart';

class WorkoutExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final int exerciseNumber;

  const WorkoutExerciseCard({
    super.key,
    required this.exercise,
    required this.exerciseNumber,
  });

  void _showVideoModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VideoPlayerModal(
        videoUrl: exercise.videoUrl,
        exerciseName: exercise.exerciseName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showVideoModal(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(2.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      '$exerciseNumber',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      exercise.exerciseName,
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.play_circle_outline,
                    color: Theme.of(context).primaryColor,
                    size: 28,
                  ),
                ],
              ),
              SizedBox(height: 1.5.h),
              Divider(),
              SizedBox(height: 1.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      icon: Icons.fitness_center,
                      label: 'Sets',
                      value: '${exercise.sets}',
                      context: context,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoChip(
                      icon: Icons.repeat,
                      label: 'Reps',
                      value: exercise.reps,
                      context: context,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoChip(
                      icon: Icons.timer,
                      label: 'Rest',
                      value: '${exercise.restSeconds}s',
                      context: context,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    required BuildContext context,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).primaryColor),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
