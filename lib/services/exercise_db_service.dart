import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fetches 3D exercise demonstration GIFs from ExerciseDB (RapidAPI).
///
/// Free tier: 180px animated GIFs, ~500 requests/month.
/// Results are cached in SharedPreferences so each exercise costs only one
/// API call ever (the actual GIF image is cached by CachedNetworkImage).
///
/// If `EXERCISEDB_API_KEY` is not set in env.json the service gracefully
/// returns null everywhere — callers should fall back to free-exercise-db.
class ExerciseDbService {
  static const _apiKey = String.fromEnvironment('EXERCISEDB_API_KEY');
  static const _host = 'exercisedb.p.rapidapi.com';
  static const _baseUrl = 'https://$_host';
  static const _cachePrefix = 'edb_id_';

  static final ExerciseDbService _instance = ExerciseDbService._();
  factory ExerciseDbService() => _instance;
  ExerciseDbService._();

  final Dio _dio = Dio();
  final Map<String, String?> _memCache = {};

  /// Whether the API key is configured.
  bool get isAvailable => _apiKey.isNotEmpty;

  /// Headers for ExerciseDB API + GIF image requests.
  Map<String, String> get authHeaders => {
        'X-RapidAPI-Key': _apiKey,
        'X-RapidAPI-Host': _host,
      };

  /// Look up the ExerciseDB ID for [exerciseName] (English).
  /// Returns cached value if available, otherwise queries API and caches.
  Future<String?> getExerciseId(String exerciseName) async {
    if (!isAvailable) return null;

    final key = exerciseName.toLowerCase().trim();

    // 1. In-memory cache
    if (_memCache.containsKey(key)) return _memCache[key];

    // 2. SharedPreferences cache
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('$_cachePrefix$key');
      if (stored != null && stored.isNotEmpty) {
        _memCache[key] = stored;
        return stored;
      }
      // A stored empty string means "looked up, not found" — don't retry.
      if (stored == '') {
        _memCache[key] = null;
        return null;
      }
    } catch (_) {}

    // 3. API lookup
    try {
      final response = await _dio
          .get(
            '$_baseUrl/exercises/name/${Uri.encodeComponent(key)}',
            options: Options(headers: authHeaders),
          )
          .timeout(const Duration(seconds: 15));

      if (response.data is List && (response.data as List).isNotEmpty) {
        final id = (response.data as List).first['id'].toString();
        _memCache[key] = id;
        _persist(key, id);
        return id;
      }
    } catch (e) {
      debugPrint('ExerciseDbService lookup error: $e');
    }

    // Mark as "not found" so we don't retry next time
    _memCache[key] = null;
    _persist(key, '');
    return null;
  }

  /// Build the GIF image URL for a given ExerciseDB [exerciseId].
  /// Load this URL via CachedNetworkImage with [authHeaders].
  String gifUrl(String exerciseId) =>
      '$_baseUrl/image/$exerciseId';

  // ── Private ────────────────────────────────────────────────────────
  Future<void> _persist(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_cachePrefix$key', value);
    } catch (_) {}
  }
}
