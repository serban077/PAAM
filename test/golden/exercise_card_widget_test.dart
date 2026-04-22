import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartfitai/presentation/exercise_library/widgets/exercise_card_widget.dart';
import 'package:smartfitai/theme/app_theme.dart';

import '../helpers/test_app_wrapper.dart';

// Minimal stub exercise data for golden tests.
// Uses empty image URL so ExerciseCardWidget renders the body-part placeholder.
Map<String, dynamic> _exercise(String difficulty, String bodyPart) => {
  'id': 'test-$difficulty',
  'name': '$bodyPart $difficulty Press',
  'bodyPart': bodyPart,
  'targetMuscles': '$bodyPart, Core',
  'equipment': 'Barbell',
  'difficulty': difficulty,
  'image': '', // empty → triggers placeholder path
  'sets': 4,
  'reps': '8-12',
};

void main() {
  group('ExerciseCardWidget goldens', () {
    testWidgets('light — Beginner (green strip)', (tester) async {
      await pumpGoldenWidget(
        tester,
        SizedBox(
          height: 120,
          child: ExerciseCardWidget(
            exercise: _exercise('Beginner', 'Chest'),
            onTap: () {},
            onLongPress: () {},
          ),
        ),
      );
      await expectLater(
        find.byType(ExerciseCardWidget),
        matchesGoldenFile('goldens/exercise_card_light_beginner.png'),
      );
    });

    testWidgets('light — Intermediate (orange strip)', (tester) async {
      await pumpGoldenWidget(
        tester,
        SizedBox(
          height: 120,
          child: ExerciseCardWidget(
            exercise: _exercise('Intermediate', 'Back'),
            onTap: () {},
            onLongPress: () {},
          ),
        ),
      );
      await expectLater(
        find.byType(ExerciseCardWidget),
        matchesGoldenFile('goldens/exercise_card_light_intermediate.png'),
      );
    });

    testWidgets('light — Advanced (red strip)', (tester) async {
      await pumpGoldenWidget(
        tester,
        SizedBox(
          height: 120,
          child: ExerciseCardWidget(
            exercise: _exercise('Advanced', 'Legs'),
            onTap: () {},
            onLongPress: () {},
          ),
        ),
      );
      await expectLater(
        find.byType(ExerciseCardWidget),
        matchesGoldenFile('goldens/exercise_card_light_advanced.png'),
      );
    });

    testWidgets('dark — Beginner (green strip)', (tester) async {
      await pumpGoldenWidget(
        tester,
        SizedBox(
          height: 120,
          child: ExerciseCardWidget(
            exercise: _exercise('Beginner', 'Chest'),
            onTap: () {},
            onLongPress: () {},
          ),
        ),
        theme: AppTheme.darkTheme,
      );
      await expectLater(
        find.byType(ExerciseCardWidget),
        matchesGoldenFile('goldens/exercise_card_dark_beginner.png'),
      );
    });

    testWidgets('dark — Intermediate (orange strip)', (tester) async {
      await pumpGoldenWidget(
        tester,
        SizedBox(
          height: 120,
          child: ExerciseCardWidget(
            exercise: _exercise('Intermediate', 'Shoulders'),
            onTap: () {},
            onLongPress: () {},
          ),
        ),
        theme: AppTheme.darkTheme,
      );
      await expectLater(
        find.byType(ExerciseCardWidget),
        matchesGoldenFile('goldens/exercise_card_dark_intermediate.png'),
      );
    });

    testWidgets('dark — Advanced (red strip)', (tester) async {
      await pumpGoldenWidget(
        tester,
        SizedBox(
          height: 120,
          child: ExerciseCardWidget(
            exercise: _exercise('Advanced', 'Arms'),
            onTap: () {},
            onLongPress: () {},
          ),
        ),
        theme: AppTheme.darkTheme,
      );
      await expectLater(
        find.byType(ExerciseCardWidget),
        matchesGoldenFile('goldens/exercise_card_dark_advanced.png'),
      );
    });
  });
}
