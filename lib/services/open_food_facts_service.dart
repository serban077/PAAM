import 'package:dio/dio.dart';

/// Open Food Facts API service — barcode product lookup (no API key required).
/// Returns data mapped to the local `food_database` column schema.
class OpenFoodFactsService {
  static final OpenFoodFactsService _instance =
      OpenFoodFactsService._internal();

  factory OpenFoodFactsService() => _instance;

  OpenFoodFactsService._internal();

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
  Future<Map<String, dynamic>?> lookupBarcode(String barcode) async {
    try {
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

      return {
        'name': name,
        'brand': (product['brands'] as String? ?? '').trim(),
        'calories': calories,
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
    } on DioException {
      return null;
    } catch (_) {
      return null;
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
