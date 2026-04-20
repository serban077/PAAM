import 'package:dio/dio.dart';

import '_dio_interceptors.dart';

/// Open Food Facts API service — barcode product lookup (no API key required).
/// Returns data mapped to the local `food_database` column schema.
class OpenFoodFactsService {
  static final OpenFoodFactsService _instance =
      OpenFoodFactsService._internal();

  factory OpenFoodFactsService() => _instance;

  OpenFoodFactsService._internal() {
    _dio.interceptors.add(AppLogInterceptor());
  }

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://world.openfoodfacts.org',
      headers: {'User-Agent': 'SmartFitAI - Flutter - educational project'},
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  /// Looks up a product by barcode.
  ///
  /// Returns a Map matching `food_database` columns (without `id`) on success,
  /// or `null` if the product is not found or the request fails.
  /// Throws [NetworkOfflineException] when the device has no connectivity.
  Future<Map<String, dynamic>?> lookupBarcode(String barcode) async {
    await assertConnected();
    try {
      return await withRetry(() async {
        final response = await _dio
            .get('/api/v0/product/$barcode.json')
            .timeout(const Duration(seconds: 15));

        final data = response.data as Map<String, dynamic>?;
        if (data == null) return null;

        final status = data['status'];
        if (status != 1) return null;

        final product = data['product'] as Map<String, dynamic>?;
        if (product == null) return null;

        final nutriments = product['nutriments'] as Map<String, dynamic>? ?? {};

        final name = (product['product_name'] as String? ?? '').trim();
        if (name.isEmpty) return null;

        final calories =
            _toDouble(nutriments['energy-kcal_100g']) ??
            _toDouble(nutriments['energy-kcal']) ??
            0.0;
        final protein =
            _toDouble(nutriments['proteins_100g']) ??
            _toDouble(nutriments['proteins']) ??
            0.0;
        final carbs =
            _toDouble(nutriments['carbohydrates_100g']) ??
            _toDouble(nutriments['carbohydrates']) ??
            0.0;
        final fat =
            _toDouble(nutriments['fat_100g']) ??
            _toDouble(nutriments['fat']) ??
            0.0;

        final rawBrand = (product['brands'] as String? ?? '').trim();

        return {
          'name': name,
          'brand': rawBrand.isEmpty ? null : rawBrand,   // null, not '' — matches DB
          'calories': calories.round(),                   // integer column in DB
          'protein_g': protein,
          'carbs_g': carbs,
          'fat_g': fat,
          'serving_size': 100.0,
          'serving_unit': 'g',
          'barcode': barcode,
          'is_verified': false,
          'image_front_url':
              product['image_front_url'] as String? ??
              product['image_url'] as String?,
        };
      });
    } on NetworkOfflineException {
      rethrow;
    } on DioException {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Searches for products by text query.
  ///
  /// Returns up to 20 results per page, filtered to only items with known
  /// calorie data. Returns `[]` on any error — never throws.
  /// Pass [cancelToken] to abort a previous in-flight search when the query changes.
  /// Throws [NetworkOfflineException] when the device has no connectivity.
  Future<List<Map<String, dynamic>>> searchFoods(
    String query, {
    int page = 1,
    CancelToken? cancelToken,
  }) async {
    await assertConnected();
    try {
      return await withRetry(() async {
        final response = await _dio
            .get(
              '/cgi/search.pl',
              queryParameters: {
                'search_terms': query,
                'json': '1',
                'page_size': '20',
                'page': '$page',
              },
              cancelToken: cancelToken,
            )
            .timeout(const Duration(seconds: 15));

        final data = response.data as Map<String, dynamic>?;
        final products = data?['products'] as List<dynamic>? ?? [];

        return products
            .whereType<Map<String, dynamic>>()
            .map((p) {
              final nutriments =
                  p['nutriments'] as Map<String, dynamic>? ?? {};
              final kcal = _toDouble(nutriments['energy-kcal_100g']) ??
                  _toDouble(nutriments['energy-kcal']);
              if (kcal == null || kcal == 0) return null;

              final name = (p['product_name'] as String? ?? '').trim();
              if (name.isEmpty) return null;

              final rawBrand = (p['brands'] as String? ?? '').trim();

              return <String, dynamic>{
                'name': name,
                'brand': rawBrand.isEmpty ? null : rawBrand, // null, not ''
                'calories': kcal.round(),                    // integer column in DB
                'protein_g':
                    _toDouble(nutriments['proteins_100g']) ??
                    _toDouble(nutriments['proteins']) ??
                    0.0,
                'carbs_g':
                    _toDouble(nutriments['carbohydrates_100g']) ??
                    _toDouble(nutriments['carbohydrates']) ??
                    0.0,
                'fat_g':
                    _toDouble(nutriments['fat_100g']) ??
                    _toDouble(nutriments['fat']) ??
                    0.0,
                'serving_size': 100.0,
                'serving_unit': 'g',
                'barcode': null,
                'is_verified': false,
                'image_front_url':
                    p['image_front_url'] as String? ??
                    p['image_url'] as String?,
                '_source': 'Open Food Facts',
              };
            })
            .whereType<Map<String, dynamic>>()
            .toList();
      });
    } on NetworkOfflineException {
      rethrow;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) return [];
      return [];
    } catch (_) {
      return [];
    }
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
