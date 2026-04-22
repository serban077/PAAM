import 'package:flutter_test/flutter_test.dart';
import 'package:smartfitai/services/app_cache_service.dart';

void main() {
  // Reset cache state before each test so singleton doesn't bleed between cases.
  setUp(() => AppCacheService.instance.invalidateAll());

  group('AppCacheService', () {
    // ──────────────────────────────────────────────
    // User profile
    // ──────────────────────────────────────────────
    group('user profile', () {
      test('returns null when not set', () {
        expect(AppCacheService.instance.getUserProfile(), isNull);
      });

      test('returns cached value immediately after set', () {
        final profile = {'id': 'u1', 'name': 'Alice'};
        AppCacheService.instance.setUserProfile(profile);
        expect(AppCacheService.instance.getUserProfile(), equals(profile));
      });

      test('invalidateProfile clears the cached value', () {
        AppCacheService.instance.setUserProfile({'id': 'u1'});
        AppCacheService.instance.invalidateProfile();
        expect(AppCacheService.instance.getUserProfile(), isNull);
      });
    });

    // ──────────────────────────────────────────────
    // Date-keyed today workout
    // ──────────────────────────────────────────────
    group('today workout (date-keyed)', () {
      test('returns null for unknown date key', () {
        expect(AppCacheService.instance.getTodayWorkout('2024-01-01'), isNull);
      });

      test('returns cached workout for matching date key', () {
        final workout = {'id': 'w1', 'name': 'Push Day'};
        AppCacheService.instance.setTodayWorkout('2024-01-01', workout);
        expect(AppCacheService.instance.getTodayWorkout('2024-01-01'), equals(workout));
      });

      test('returns null for a different date key', () {
        AppCacheService.instance.setTodayWorkout('2024-01-01', {'id': 'w1'});
        expect(AppCacheService.instance.getTodayWorkout('2024-01-02'), isNull);
      });
    });

    // ──────────────────────────────────────────────
    // Nutrition (date-keyed map)
    // ──────────────────────────────────────────────
    group('nutrition (date-keyed)', () {
      test('returns null for unknown date key', () {
        expect(AppCacheService.instance.getNutrition('2024-01-01'), isNull);
      });

      test('returns cached data for matching date key', () {
        final data = NutritionCacheData(
          meals: [],
          dailyTotals: {'calories': 1500.0, 'protein_g': 120.0, 'carbs_g': 180.0, 'fat_g': 50.0},
          dailyGoal: {'daily_calorie_goal': 2000},
        );
        AppCacheService.instance.setNutrition('2024-01-01', data);
        final cached = AppCacheService.instance.getNutrition('2024-01-01');
        expect(cached, isNotNull);
        expect(cached!.dailyTotals['calories'], equals(1500.0));
      });

      test('returns null for a different date key', () {
        final data = NutritionCacheData(meals: [], dailyTotals: {}, dailyGoal: {});
        AppCacheService.instance.setNutrition('2024-01-01', data);
        expect(AppCacheService.instance.getNutrition('2024-01-02'), isNull);
      });

      test('invalidateNutrition removes only the specified key', () {
        final data = NutritionCacheData(meals: [], dailyTotals: {}, dailyGoal: {});
        AppCacheService.instance.setNutrition('2024-01-01', data);
        AppCacheService.instance.setNutrition('2024-01-02', data);
        AppCacheService.instance.invalidateNutrition('2024-01-01');
        expect(AppCacheService.instance.getNutrition('2024-01-01'), isNull);
        expect(AppCacheService.instance.getNutrition('2024-01-02'), isNotNull);
      });
    });

    // ──────────────────────────────────────────────
    // Food search LRU eviction (max 20)
    // ──────────────────────────────────────────────
    group('food search LRU', () {
      test('returns null for uncached query', () {
        expect(AppCacheService.instance.getFoodSearch('apple'), isNull);
      });

      test('returns cached results immediately after set', () {
        final results = [{'name': 'Apple', 'calories': 52}];
        AppCacheService.instance.setFoodSearch('apple', results);
        expect(AppCacheService.instance.getFoodSearch('apple'), equals(results));
      });

      test('query normalised to lowercase', () {
        AppCacheService.instance.setFoodSearch('Apple', [{'name': 'Apple'}]);
        expect(AppCacheService.instance.getFoodSearch('apple'), isNotNull);
        expect(AppCacheService.instance.getFoodSearch('APPLE'), isNotNull);
      });

      test('oldest entry evicted when capacity reaches 20', () {
        // Fill all 20 slots with distinct queries
        for (int i = 0; i < 20; i++) {
          AppCacheService.instance.setFoodSearch('query$i', [{'id': i}]);
        }
        // All 20 entries present
        expect(AppCacheService.instance.getFoodSearch('query0'), isNotNull);

        // Adding a 21st evicts the oldest (query0)
        AppCacheService.instance.setFoodSearch('query20', [{'id': 20}]);
        expect(AppCacheService.instance.getFoodSearch('query0'), isNull);
        expect(AppCacheService.instance.getFoodSearch('query20'), isNotNull);
      });
    });

    // ──────────────────────────────────────────────
    // External search LRU eviction (max 20)
    // ──────────────────────────────────────────────
    group('external food search LRU', () {
      test('returns null when not cached', () {
        expect(AppCacheService.instance.getExternalFoodSearch('banana'), isNull);
      });

      test('oldest entry evicted at capacity 20', () {
        for (int i = 0; i < 20; i++) {
          AppCacheService.instance.setExternalFoodSearch('ext$i', [{'id': i}]);
        }
        AppCacheService.instance.setExternalFoodSearch('ext20', [{'id': 20}]);
        expect(AppCacheService.instance.getExternalFoodSearch('ext0'), isNull);
        expect(AppCacheService.instance.getExternalFoodSearch('ext20'), isNotNull);
      });
    });

    // ──────────────────────────────────────────────
    // Contributions
    // ──────────────────────────────────────────────
    group('contributions', () {
      test('returns null when not set', () {
        expect(AppCacheService.instance.getContributions(), isNull);
      });

      test('returns cached list after set', () {
        final list = [{'id': 'f1'}, {'id': 'f2'}];
        AppCacheService.instance.setContributions(list);
        expect(AppCacheService.instance.getContributions(), equals(list));
      });

      test('invalidateContributions clears the list', () {
        AppCacheService.instance.setContributions([{'id': 'f1'}]);
        AppCacheService.instance.invalidateContributions();
        expect(AppCacheService.instance.getContributions(), isNull);
      });
    });

    // ──────────────────────────────────────────────
    // AI plan cache (keyed by profile hash)
    // ──────────────────────────────────────────────
    group('AI plan cache', () {
      test('getWorkoutPlan returns null for unknown hash', () {
        expect(AppCacheService.instance.getWorkoutPlan('hash_xyz'), isNull);
      });

      test('getWorkoutPlan returns plan for matching hash', () {
        final plan = {'days': 5, 'goal': 'strength'};
        AppCacheService.instance.setWorkoutPlan('hash_abc', plan);
        expect(AppCacheService.instance.getWorkoutPlan('hash_abc'), equals(plan));
      });

      test('different hashes have isolated entries', () {
        AppCacheService.instance.setWorkoutPlan('hash_a', {'days': 3});
        AppCacheService.instance.setWorkoutPlan('hash_b', {'days': 5});
        expect(AppCacheService.instance.getWorkoutPlan('hash_a')!['days'], equals(3));
        expect(AppCacheService.instance.getWorkoutPlan('hash_b')!['days'], equals(5));
      });

      test('invalidateAIPlanCache clears both workout and nutrition plans', () {
        AppCacheService.instance.setWorkoutPlan('h', {'days': 3});
        AppCacheService.instance.setNutritionPlan('h', {'calories': 2000});
        AppCacheService.instance.invalidateAIPlanCache();
        expect(AppCacheService.instance.getWorkoutPlan('h'), isNull);
        expect(AppCacheService.instance.getNutritionPlan('h'), isNull);
      });
    });

    // ──────────────────────────────────────────────
    // invalidateAll
    // ──────────────────────────────────────────────
    group('invalidateAll', () {
      test('clears all caches simultaneously', () {
        // Populate a representative set
        AppCacheService.instance.setUserProfile({'id': 'u1'});
        AppCacheService.instance.setFoodSearch('apple', [{'name': 'Apple'}]);
        AppCacheService.instance.setWorkoutStreak(7);
        AppCacheService.instance.setContributions([{'id': 'f1'}]);
        AppCacheService.instance.setWorkoutPlan('h', {'days': 3});

        AppCacheService.instance.invalidateAll();

        expect(AppCacheService.instance.getUserProfile(), isNull);
        expect(AppCacheService.instance.getFoodSearch('apple'), isNull);
        expect(AppCacheService.instance.getWorkoutStreak(), isNull);
        expect(AppCacheService.instance.getContributions(), isNull);
        expect(AppCacheService.instance.getWorkoutPlan('h'), isNull);
      });
    });
  });
}
