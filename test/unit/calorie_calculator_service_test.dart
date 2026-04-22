import 'package:flutter_test/flutter_test.dart';
import 'package:smartfitai/services/calorie_calculator_service.dart';

void main() {
  group('CalorieCalculatorService', () {
    // ──────────────────────────────────────────────
    // calculateBMR — Mifflin-St Jeor
    // ──────────────────────────────────────────────
    group('calculateBMR', () {
      test('male 80 kg / 180 cm / age 25', () {
        // (10×80) + (6.25×180) − (5×25) + 5 = 1805
        expect(
          CalorieCalculatorService.calculateBMR(
            weightKg: 80,
            heightCm: 180,
            age: 25,
            gender: 'male',
          ),
          equals(1805.0),
        );
      });

      test('female 60 kg / 165 cm / age 30', () {
        // (10×60) + (6.25×165) − (5×30) − 161 = 1320.25
        expect(
          CalorieCalculatorService.calculateBMR(
            weightKg: 60,
            heightCm: 165,
            age: 30,
            gender: 'female',
          ),
          closeTo(1320.25, 0.01),
        );
      });

      test('gender "m" alias maps to male path (+5)', () {
        final bmr = CalorieCalculatorService.calculateBMR(
          weightKg: 70,
          heightCm: 175,
          age: 30,
          gender: 'm',
        );
        final base = (10 * 70.0) + (6.25 * 175) - (5 * 30);
        expect(bmr, closeTo(base + 5, 0.01));
      });

      test('gender "masculin" maps to male path (+5)', () {
        final bmr = CalorieCalculatorService.calculateBMR(
          weightKg: 70,
          heightCm: 175,
          age: 30,
          gender: 'masculin',
        );
        final base = (10 * 70.0) + (6.25 * 175) - (5 * 30);
        expect(bmr, closeTo(base + 5, 0.01));
      });

      test('unknown gender defaults to female path (−161)', () {
        final bmr = CalorieCalculatorService.calculateBMR(
          weightKg: 70,
          heightCm: 175,
          age: 30,
          gender: 'other',
        );
        final base = (10 * 70.0) + (6.25 * 175) - (5 * 30);
        expect(bmr, closeTo(base - 161, 0.01));
      });

      test('case-insensitive matching', () {
        final bmrUpper = CalorieCalculatorService.calculateBMR(
          weightKg: 80, heightCm: 180, age: 25, gender: 'MALE',
        );
        final bmrLower = CalorieCalculatorService.calculateBMR(
          weightKg: 80, heightCm: 180, age: 25, gender: 'male',
        );
        expect(bmrUpper, equals(bmrLower));
      });
    });

    // ──────────────────────────────────────────────
    // calculateTDEE — activity multipliers
    // ──────────────────────────────────────────────
    group('calculateTDEE', () {
      const bmr = 1800.0;

      test('0 days/week → ×1.2 (sedentary)', () {
        expect(
          CalorieCalculatorService.calculateTDEE(bmr: bmr, weeklyTrainingFrequency: 0),
          closeTo(bmr * 1.2, 0.01),
        );
      });

      test('1 day/week → ×1.2 (boundary ≤1)', () {
        expect(
          CalorieCalculatorService.calculateTDEE(bmr: bmr, weeklyTrainingFrequency: 1),
          closeTo(bmr * 1.2, 0.01),
        );
      });

      test('2 days/week → ×1.375 (lightly active)', () {
        expect(
          CalorieCalculatorService.calculateTDEE(bmr: bmr, weeklyTrainingFrequency: 2),
          closeTo(bmr * 1.375, 0.01),
        );
      });

      test('3 days/week → ×1.375 (boundary ≤3)', () {
        expect(
          CalorieCalculatorService.calculateTDEE(bmr: bmr, weeklyTrainingFrequency: 3),
          closeTo(bmr * 1.375, 0.01),
        );
      });

      test('4 days/week → ×1.55 (moderately active)', () {
        expect(
          CalorieCalculatorService.calculateTDEE(bmr: bmr, weeklyTrainingFrequency: 4),
          closeTo(bmr * 1.55, 0.01),
        );
      });

      test('5 days/week → ×1.55 (boundary ≤5)', () {
        expect(
          CalorieCalculatorService.calculateTDEE(bmr: bmr, weeklyTrainingFrequency: 5),
          closeTo(bmr * 1.55, 0.01),
        );
      });

      test('6 days/week → ×1.725 (very active)', () {
        expect(
          CalorieCalculatorService.calculateTDEE(bmr: bmr, weeklyTrainingFrequency: 6),
          closeTo(bmr * 1.725, 0.01),
        );
      });

      test('7 days/week → ×1.725 (boundary >5)', () {
        expect(
          CalorieCalculatorService.calculateTDEE(bmr: bmr, weeklyTrainingFrequency: 7),
          closeTo(bmr * 1.725, 0.01),
        );
      });
    });

    // ──────────────────────────────────────────────
    // calculateDailyCalorieGoal
    // ──────────────────────────────────────────────
    group('calculateDailyCalorieGoal', () {
      const tdee = 2500.0;

      test('"weight_loss" → TDEE − 500', () {
        expect(
          CalorieCalculatorService.calculateDailyCalorieGoal(tdee: tdee, fitnessGoal: 'weight_loss'),
          equals(2000),
        );
      });

      test('"pierdere" (Romanian) → TDEE − 500', () {
        expect(
          CalorieCalculatorService.calculateDailyCalorieGoal(tdee: tdee, fitnessGoal: 'pierdere'),
          equals(2000),
        );
      });

      test('"slabire" (Romanian) → TDEE − 500', () {
        expect(
          CalorieCalculatorService.calculateDailyCalorieGoal(tdee: tdee, fitnessGoal: 'slabire'),
          equals(2000),
        );
      });

      test('"muscle_gain" → TDEE + 300', () {
        expect(
          CalorieCalculatorService.calculateDailyCalorieGoal(tdee: tdee, fitnessGoal: 'muscle_gain'),
          equals(2800),
        );
      });

      test('"gain" alias → TDEE + 300', () {
        expect(
          CalorieCalculatorService.calculateDailyCalorieGoal(tdee: tdee, fitnessGoal: 'gain'),
          equals(2800),
        );
      });

      test('"bulk" alias → TDEE + 300', () {
        expect(
          CalorieCalculatorService.calculateDailyCalorieGoal(tdee: tdee, fitnessGoal: 'bulk'),
          equals(2800),
        );
      });

      test('"crestere" (Romanian) → TDEE + 300', () {
        expect(
          CalorieCalculatorService.calculateDailyCalorieGoal(tdee: tdee, fitnessGoal: 'crestere'),
          equals(2800),
        );
      });

      test('"masa" (Romanian) → TDEE + 300', () {
        expect(
          CalorieCalculatorService.calculateDailyCalorieGoal(tdee: tdee, fitnessGoal: 'masa'),
          equals(2800),
        );
      });

      test('"maintenance" → TDEE (rounded)', () {
        expect(
          CalorieCalculatorService.calculateDailyCalorieGoal(tdee: 2500.6, fitnessGoal: 'maintenance'),
          equals(2501),
        );
      });

      test('unknown goal defaults to TDEE (rounded)', () {
        expect(
          CalorieCalculatorService.calculateDailyCalorieGoal(tdee: tdee, fitnessGoal: 'general_fitness'),
          equals(2500),
        );
      });
    });

    // ──────────────────────────────────────────────
    // calculateDailyCalorieGoalWithDeadline
    // ──────────────────────────────────────────────
    group('calculateDailyCalorieGoalWithDeadline', () {
      const tdee = 2500.0;

      test('weight diff < 0.5 kg → returns TDEE', () {
        expect(
          CalorieCalculatorService.calculateDailyCalorieGoalWithDeadline(
            tdee: tdee,
            currentWeightKg: 80.0,
            targetWeightKg: 80.3,
            targetTimeframeWeeks: 12,
          ),
          equals(tdee.round()),
        );
      });

      test('timeframe = 0 → returns TDEE', () {
        expect(
          CalorieCalculatorService.calculateDailyCalorieGoalWithDeadline(
            tdee: tdee,
            currentWeightKg: 80.0,
            targetWeightKg: 75.0,
            targetTimeframeWeeks: 0,
          ),
          equals(tdee.round()),
        );
      });

      test('normal weight loss: 80→70 kg over 12 weeks', () {
        // weekly = 10/12 ≈ 0.833, daily ≈ 916.7, target = 2500 − 916.7 ≈ 1583
        final result = CalorieCalculatorService.calculateDailyCalorieGoalWithDeadline(
          tdee: 2500.0,
          currentWeightKg: 80.0,
          targetWeightKg: 70.0,
          targetTimeframeWeeks: 12,
        );
        expect(result, greaterThanOrEqualTo(1200));
        expect(result, lessThan(2500));
      });

      test('extreme loss floors at 1200 kcal minimum', () {
        // 80→60 kg over 12 weeks, tdee=1700: daily deficit ≈ 1833 → would go below 0 → clamped to 1200
        final result = CalorieCalculatorService.calculateDailyCalorieGoalWithDeadline(
          tdee: 1700.0,
          currentWeightKg: 80.0,
          targetWeightKg: 60.0,
          targetTimeframeWeeks: 12,
        );
        expect(result, equals(1200));
      });

      test('mild gain stays within TDEE + 500 cap', () {
        // 60→62 kg over 10 weeks: daily surplus ≈ 220, result = 2000 + 220 = 2220
        final result = CalorieCalculatorService.calculateDailyCalorieGoalWithDeadline(
          tdee: 2000.0,
          currentWeightKg: 60.0,
          targetWeightKg: 62.0,
          targetTimeframeWeeks: 10,
        );
        expect(result, greaterThan(2000));
        expect(result, lessThanOrEqualTo(2500));
      });

      test('aggressive gain caps at TDEE + 500', () {
        // 60→65 kg over 10 weeks, tdee=2000: daily surplus ≈ 550 → capped to 2500
        final result = CalorieCalculatorService.calculateDailyCalorieGoalWithDeadline(
          tdee: 2000.0,
          currentWeightKg: 60.0,
          targetWeightKg: 65.0,
          targetTimeframeWeeks: 10,
        );
        expect(result, equals(2500));
      });
    });

    // ──────────────────────────────────────────────
    // calculateMacros
    // ──────────────────────────────────────────────
    group('calculateMacros', () {
      test('weight_loss: protein = weight × 2.2', () {
        final macros = CalorieCalculatorService.calculateMacros(
          dailyCalories: 2000,
          weightKg: 70,
          fitnessGoal: 'weight_loss',
        );
        expect(macros['protein_g'], closeTo(70 * 2.2, 0.01));
      });

      test('muscle_gain: protein = weight × 2.0', () {
        final macros = CalorieCalculatorService.calculateMacros(
          dailyCalories: 2500,
          weightKg: 80,
          fitnessGoal: 'muscle_gain',
        );
        expect(macros['protein_g'], closeTo(80 * 2.0, 0.01));
      });

      test('maintenance: protein = weight × 1.8', () {
        final macros = CalorieCalculatorService.calculateMacros(
          dailyCalories: 1800,
          weightKg: 60,
          fitnessGoal: 'maintenance',
        );
        expect(macros['protein_g'], closeTo(60 * 1.8, 0.01));
      });

      test('fat = 25% of calories ÷ 9', () {
        final macros = CalorieCalculatorService.calculateMacros(
          dailyCalories: 2000,
          weightKg: 70,
          fitnessGoal: 'maintenance',
        );
        expect(macros['fat_g'], closeTo(2000 * 0.25 / 9, 0.01));
      });

      test('carbs are non-negative even with heavy macros', () {
        // Very low calories, heavy weight → protein + fat may exceed budget
        final macros = CalorieCalculatorService.calculateMacros(
          dailyCalories: 800,
          weightKg: 120,
          fitnessGoal: 'weight_loss',
        );
        expect(macros['carbs_g'], greaterThanOrEqualTo(0));
      });

      test('all three macro keys are present', () {
        final macros = CalorieCalculatorService.calculateMacros(
          dailyCalories: 2000,
          weightKg: 70,
          fitnessGoal: 'maintenance',
        );
        expect(macros.containsKey('protein_g'), isTrue);
        expect(macros.containsKey('carbs_g'), isTrue);
        expect(macros.containsKey('fat_g'), isTrue);
      });
    });

    // ──────────────────────────────────────────────
    // calculateNutritionGoals — integration
    // ──────────────────────────────────────────────
    group('calculateNutritionGoals', () {
      test('standard path returns all required keys', () {
        final result = CalorieCalculatorService.calculateNutritionGoals(
          weightKg: 80,
          heightCm: 180,
          age: 25,
          gender: 'male',
          weeklyTrainingFrequency: 3,
          fitnessGoal: 'weight_loss',
        );
        expect(result.containsKey('bmr'), isTrue);
        expect(result.containsKey('tdee'), isTrue);
        expect(result.containsKey('daily_calorie_goal'), isTrue);
        expect(result.containsKey('protein_goal_g'), isTrue);
        expect(result.containsKey('carbs_goal_g'), isTrue);
        expect(result.containsKey('fat_goal_g'), isTrue);
      });

      test('standard path: BMR < TDEE < calorie_goal for muscle_gain', () {
        final result = CalorieCalculatorService.calculateNutritionGoals(
          weightKg: 75,
          heightCm: 175,
          age: 28,
          gender: 'male',
          weeklyTrainingFrequency: 4,
          fitnessGoal: 'muscle_gain',
        );
        expect(result['bmr'], lessThan(result['tdee']));
        expect(result['daily_calorie_goal'], greaterThan(result['tdee'] as int));
      });

      test('deadline path is used when target weight + timeframe provided', () {
        final withDeadline = CalorieCalculatorService.calculateNutritionGoals(
          weightKg: 80,
          heightCm: 180,
          age: 25,
          gender: 'male',
          weeklyTrainingFrequency: 3,
          fitnessGoal: 'weight_loss',
          targetWeightKg: 70,
          targetTimeframeWeeks: 12,
        );
        final withoutDeadline = CalorieCalculatorService.calculateNutritionGoals(
          weightKg: 80,
          heightCm: 180,
          age: 25,
          gender: 'male',
          weeklyTrainingFrequency: 3,
          fitnessGoal: 'weight_loss',
        );
        // Deadline-based calc gives different result than standard −500 goal
        expect(
          withDeadline['daily_calorie_goal'],
          isNot(equals(withoutDeadline['daily_calorie_goal'])),
        );
      });
    });
  });
}
