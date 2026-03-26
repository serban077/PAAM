import 'package:dio/dio.dart';

/// USDA FoodData Central search service.
///
/// API key is free — register at https://fdc.nal.usda.gov/api-guide.html
/// Store as `USDA_API_KEY` in env.json.
/// If the key is absent the service returns [] gracefully.
class UsdaFoodService {
  static final UsdaFoodService _instance = UsdaFoodService._internal();

  factory UsdaFoodService() => _instance;

  UsdaFoodService._internal();

  static const _apiKey = String.fromEnvironment(
    'USDA_API_KEY',
    defaultValue: '',
  );

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.nal.usda.gov',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  /// Searches USDA FoodData Central for foods matching [query].
  ///
  /// Nutrient IDs used: 1008=kcal, 1003=protein, 1005=carbs, 1004=fat.
  /// Returns [] if the API key is absent or on any network error.
  Future<List<Map<String, dynamic>>> searchFoods(String query) async {
    if (_apiKey.isEmpty) return [];
    try {
      final response = await _dio
          .get(
            '/fdc/v1/foods/search',
            queryParameters: {
              'query': query,
              'api_key': _apiKey,
              'pageSize': '20',
            },
          )
          .timeout(const Duration(seconds: 15));

      final foods =
          (response.data as Map<String, dynamic>?)?['foods']
              as List<dynamic>? ??
          [];

      return foods
          .whereType<Map<String, dynamic>>()
          .map((food) {
            // Build nutrient lookup map keyed by nutrientId
            final nutrientMap = <int, double>{};
            for (final n
                in (food['foodNutrients'] as List<dynamic>? ?? [])) {
              final entry = n as Map<String, dynamic>;
              final id = entry['nutrientId'] as int?;
              final val = _toDouble(entry['value']);
              if (id != null && val != null) nutrientMap[id] = val;
            }

            final kcal = nutrientMap[1008] ?? 0.0;
            if (kcal == 0) return null;

            final name = (food['description'] as String? ?? '').trim();
            if (name.isEmpty) return null;

            final rawBrand = (food['brandOwner'] as String? ?? '').trim();

            return <String, dynamic>{
              'name': name,
              'brand': rawBrand.isEmpty ? null : rawBrand, // null, not ''
              'calories': kcal.round(),                    // integer column in DB
              'protein_g': nutrientMap[1003] ?? 0.0,
              'carbs_g': nutrientMap[1005] ?? 0.0,
              'fat_g': nutrientMap[1004] ?? 0.0,
              'serving_size': 100.0,
              'serving_unit': 'g',
              'barcode': null,
              'is_verified': false,
              'image_front_url': null,
              '_source': 'USDA',
            };
          })
          .whereType<Map<String, dynamic>>()
          .toList();
    } on DioException {
      return [];
    } catch (_) {
      return [];
    }
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}
