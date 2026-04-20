/// In-memory cache with TTL for frequently-accessed data.
///
/// Eliminates redundant Supabase queries when navigating between screens.
/// Call [invalidateAll] on logout. Call targeted invalidation methods
/// after mutations (profile update, meal add/delete, contribution add/delete).
class AppCacheService {
  AppCacheService._();
  static final AppCacheService instance = AppCacheService._();

  // ── TTL configuration ──────────────────────────────────────────────
  static const _profileTtl           = Duration(minutes: 5);
  static const _streakTtl            = Duration(minutes: 10);
  static const _nutritionTtl         = Duration(minutes: 5);
  static const _exerciseTtl          = Duration(minutes: 30);
  static const _measurementsTtl      = Duration(minutes: 5);
  static const _strengthPrTtl        = Duration(minutes: 5);
  static const _foodSearchTtl        = Duration(minutes: 3);
  static const _contributionsTtl     = Duration(minutes: 5);
  static const _activeWorkoutTtl     = Duration(minutes: 10);
  static const _weeklyScheduleTtl    = Duration(minutes: 10);
  static const _externalSearchTtl    = Duration(minutes: 10);
  static const _visionCacheTtl       = Duration(minutes: 10);
  static const _foodSearchMax        = 20;
  static const _externalSearchMax    = 20;

  // ── User profile ───────────────────────────────────────────────────
  Map<String, dynamic>? _userProfile;
  DateTime? _userProfileAt;

  Map<String, dynamic>? getUserProfile() {
    if (_userProfile == null || _userProfileAt == null) return null;
    if (DateTime.now().difference(_userProfileAt!) > _profileTtl) {
      _userProfile = null;
      return null;
    }
    return _userProfile;
  }

  void setUserProfile(Map<String, dynamic> profile) {
    _userProfile = profile;
    _userProfileAt = DateTime.now();
  }

  void invalidateProfile() {
    _userProfile = null;
    _userProfileAt = null;
  }

  // ── Today's workout ────────────────────────────────────────────────
  Map<String, dynamic>? _todayWorkout;
  String? _todayWorkoutDateKey;

  Map<String, dynamic>? getTodayWorkout(String dateKey) {
    if (_todayWorkoutDateKey != dateKey) return null;
    return _todayWorkout;
  }

  void setTodayWorkout(String dateKey, Map<String, dynamic>? workout) {
    _todayWorkoutDateKey = dateKey;
    _todayWorkout = workout;
  }

  // ── Workout streak ─────────────────────────────────────────────────
  int? _workoutStreak;
  DateTime? _streakAt;

  int? getWorkoutStreak() {
    if (_workoutStreak == null || _streakAt == null) return null;
    if (DateTime.now().difference(_streakAt!) > _streakTtl) {
      _workoutStreak = null;
      return null;
    }
    return _workoutStreak;
  }

  void setWorkoutStreak(int streak) {
    _workoutStreak = streak;
    _streakAt = DateTime.now();
  }

  // ── Nutrition (keyed by date string "yyyy-MM-dd") ──────────────────
  final Map<String, _NutritionCacheEntry> _nutritionCache = {};

  NutritionCacheData? getNutrition(String dateKey) {
    final entry = _nutritionCache[dateKey];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.cachedAt) > _nutritionTtl) {
      _nutritionCache.remove(dateKey);
      return null;
    }
    return entry.data;
  }

  void setNutrition(String dateKey, NutritionCacheData data) {
    _nutritionCache[dateKey] = _NutritionCacheEntry(
      data: data,
      cachedAt: DateTime.now(),
    );
  }

  void invalidateNutrition(String dateKey) {
    _nutritionCache.remove(dateKey);
  }

  // ── Exercise library (static data, long TTL) ───────────────────────
  List<Map<String, dynamic>>? _exerciseLibrary;
  DateTime? _exerciseLibraryAt;

  List<Map<String, dynamic>>? getExerciseLibrary() {
    if (_exerciseLibrary == null || _exerciseLibraryAt == null) return null;
    if (DateTime.now().difference(_exerciseLibraryAt!) > _exerciseTtl) {
      _exerciseLibrary = null;
      return null;
    }
    return _exerciseLibrary;
  }

  void setExerciseLibrary(List<Map<String, dynamic>> exercises) {
    _exerciseLibrary = exercises;
    _exerciseLibraryAt = DateTime.now();
  }

  void invalidateExerciseLibrary() {
    _exerciseLibrary = null;
    _exerciseLibraryAt = null;
  }

  // ── Body measurements ──────────────────────────────────────────────
  List<Map<String, dynamic>>? _bodyMeasurements;
  DateTime? _bodyMeasurementsAt;

  List<Map<String, dynamic>>? getBodyMeasurements() {
    if (_bodyMeasurements == null || _bodyMeasurementsAt == null) return null;
    if (DateTime.now().difference(_bodyMeasurementsAt!) > _measurementsTtl) {
      _bodyMeasurements = null;
      return null;
    }
    return _bodyMeasurements;
  }

  void setBodyMeasurements(List<Map<String, dynamic>> data) {
    _bodyMeasurements = data;
    _bodyMeasurementsAt = DateTime.now();
  }

  void invalidateBodyMeasurements() {
    _bodyMeasurements = null;
    _bodyMeasurementsAt = null;
  }

  // ── Strength PRs ───────────────────────────────────────────────────
  List<Map<String, dynamic>>? _strengthPrs;
  DateTime? _strengthPrsAt;

  List<Map<String, dynamic>>? getStrengthPrs() {
    if (_strengthPrs == null || _strengthPrsAt == null) return null;
    if (DateTime.now().difference(_strengthPrsAt!) > _strengthPrTtl) {
      _strengthPrs = null;
      return null;
    }
    return _strengthPrs;
  }

  void setStrengthPrs(List<Map<String, dynamic>> prs) {
    _strengthPrs = prs;
    _strengthPrsAt = DateTime.now();
  }

  void invalidateStrengthPrs() {
    _strengthPrs = null;
    _strengthPrsAt = null;
  }

  // ── Food search LRU (max 20 entries, TTL 3 min) ────────────────────
  final Map<String, _FoodSearchEntry> _foodSearch = {};

  List<Map<String, dynamic>>? getFoodSearch(String query) {
    final key = query.toLowerCase().trim();
    final entry = _foodSearch[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.cachedAt) > _foodSearchTtl) {
      _foodSearch.remove(key);
      return null;
    }
    return entry.results;
  }

  void setFoodSearch(String query, List<Map<String, dynamic>> results) {
    final key = query.toLowerCase().trim();
    if (_foodSearch.length >= _foodSearchMax) {
      _foodSearch.remove(_foodSearch.keys.first); // evict oldest
    }
    _foodSearch[key] = _FoodSearchEntry(
      results: results,
      cachedAt: DateTime.now(),
    );
  }

  // ── Active workout plan ────────────────────────────────────────────
  Map<String, dynamic>? _activeWorkout;
  DateTime? _activeWorkoutAt;

  Map<String, dynamic>? getActiveWorkout() {
    if (_activeWorkout == null || _activeWorkoutAt == null) return null;
    if (DateTime.now().difference(_activeWorkoutAt!) > _activeWorkoutTtl) {
      _activeWorkout = null;
      return null;
    }
    return _activeWorkout;
  }

  void setActiveWorkout(Map<String, dynamic>? workout) {
    _activeWorkout = workout;
    _activeWorkoutAt = DateTime.now();
  }

  void invalidateActiveWorkout() {
    _activeWorkout = null;
    _activeWorkoutAt = null;
  }

  // ── Weekly schedule (scheduled day numbers for active plan) ───────
  List<int>? _weeklySchedule;
  DateTime? _weeklyScheduleAt;

  List<int>? getWeeklySchedule() {
    if (_weeklySchedule == null || _weeklyScheduleAt == null) return null;
    if (DateTime.now().difference(_weeklyScheduleAt!) > _weeklyScheduleTtl) {
      _weeklySchedule = null;
      return null;
    }
    return _weeklySchedule;
  }

  void setWeeklySchedule(List<int> days) {
    _weeklySchedule = days;
    _weeklyScheduleAt = DateTime.now();
  }

  void invalidateWeeklySchedule() {
    _weeklySchedule = null;
    _weeklyScheduleAt = null;
  }

  // ── External food search LRU (OFF + USDA combined, 10 min TTL) ───
  final Map<String, _FoodSearchEntry> _externalSearch = {};

  /// Returns cached OFF + USDA results for [query] (case-insensitive) or
  /// `null` on a cache miss / TTL expiry.
  List<Map<String, dynamic>>? getExternalFoodSearch(String query) {
    final key = query.toLowerCase().trim();
    final entry = _externalSearch[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.cachedAt) > _externalSearchTtl) {
      _externalSearch.remove(key);
      return null;
    }
    return entry.results;
  }

  void setExternalFoodSearch(
    String query,
    List<Map<String, dynamic>> results,
  ) {
    final key = query.toLowerCase().trim();
    if (_externalSearch.length >= _externalSearchMax) {
      _externalSearch.remove(_externalSearch.keys.first); // evict oldest
    }
    _externalSearch[key] = _FoodSearchEntry(
      results: results,
      cachedAt: DateTime.now(),
    );
  }

  // ── Gemini Vision result cache (10 min TTL) ────────────────────────
  //
  // Key is a lightweight image fingerprint computed in photo_recipe_screen.dart.
  // Stores the raw ingredient maps so AppCacheService stays decoupled from
  // smart_recipe_models.dart.
  final Map<String, _FoodSearchEntry> _visionCache = {};

  /// Returns cached ingredient maps for [imageKey] or `null` on miss / expiry.
  List<Map<String, dynamic>>? getVisionResult(String imageKey) {
    final entry = _visionCache[imageKey];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.cachedAt) > _visionCacheTtl) {
      _visionCache.remove(imageKey);
      return null;
    }
    return entry.results;
  }

  void setVisionResult(String imageKey, List<Map<String, dynamic>> ingredients) {
    _visionCache[imageKey] = _FoodSearchEntry(
      results: ingredients,
      cachedAt: DateTime.now(),
    );
  }

  // ── User contributions ─────────────────────────────────────────────
  List<Map<String, dynamic>>? _contributions;
  DateTime? _contributionsAt;

  List<Map<String, dynamic>>? getContributions() {
    if (_contributions == null || _contributionsAt == null) return null;
    if (DateTime.now().difference(_contributionsAt!) > _contributionsTtl) {
      _contributions = null;
      return null;
    }
    return _contributions;
  }

  void setContributions(List<Map<String, dynamic>> data) {
    _contributions = data;
    _contributionsAt = DateTime.now();
  }

  void invalidateContributions() {
    _contributions = null;
    _contributionsAt = null;
  }

  // ── Global ─────────────────────────────────────────────────────────

  void invalidateAll() {
    _userProfile = null;
    _userProfileAt = null;
    _todayWorkout = null;
    _todayWorkoutDateKey = null;
    _workoutStreak = null;
    _streakAt = null;
    _nutritionCache.clear();
    _exerciseLibrary = null;
    _exerciseLibraryAt = null;
    _bodyMeasurements = null;
    _bodyMeasurementsAt = null;
    _strengthPrs = null;
    _strengthPrsAt = null;
    _foodSearch.clear();
    _externalSearch.clear();
    _visionCache.clear();
    _contributions = null;
    _contributionsAt = null;
    _activeWorkout = null;
    _activeWorkoutAt = null;
    _weeklySchedule = null;
    _weeklyScheduleAt = null;
  }
}

// ── Supporting types ──────────────────────────────────────────────────

class NutritionCacheData {
  final List<Map<String, dynamic>> meals;
  final Map<String, double> dailyTotals;
  final Map<String, dynamic> dailyGoal;

  const NutritionCacheData({
    required this.meals,
    required this.dailyTotals,
    required this.dailyGoal,
  });
}

class _NutritionCacheEntry {
  final NutritionCacheData data;
  final DateTime cachedAt;

  const _NutritionCacheEntry({required this.data, required this.cachedAt});
}

class _FoodSearchEntry {
  final List<Map<String, dynamic>> results;
  final DateTime cachedAt;

  const _FoodSearchEntry({required this.results, required this.cachedAt});
}
