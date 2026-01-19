import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../data/models/ai_plan_models.dart';
import 'workout_exercise_card.dart';

class WorkoutTab extends StatelessWidget {
  final String dayName;
  final List<Exercise> exercises;

  const WorkoutTab({
    super.key,
    required this.dayName,
    required this.exercises,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(2.h),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        return WorkoutExerciseCard(
          exercise: exercises[index],
          exerciseNumber: index + 1,
        );
      },
    );
  }
}
