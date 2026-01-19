import 'package:dio/dio.dart';
import '../models/ai_plan_models.dart';

class AIPlanService {
  final Dio _dio = Dio();
  
  // Replace with your actual API endpoint
  static const String _baseUrl = 'https://your-api-endpoint.com';

  Future<AIPlanResponse> fetchAIPlan({
    required String userId,
    required Map<String, dynamic> userProfile,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/generate-plan',
        data: {
          'user_id': userId,
          'profile': userProfile,
        },
      );

      if (response.statusCode == 200) {
        return AIPlanResponse.fromJson(response.data);
      } else {
        throw Exception('Failed to fetch AI plan');
      }
    } catch (e) {
      throw Exception('Error fetching AI plan: $e');
    }
  }

  Future<List<FoodItem>> searchFood(String query) async {
    try {
      // Option 1: Using Supabase
      // final supabase = Supabase.instance.client;
      // final response = await supabase
      //     .from('food_database')
      //     .select()
      //     .ilike('name', '%$query%')
      //     .limit(20);
      // return (response as List).map((e) => FoodItem.fromJson(e)).toList();

      // Option 2: Using your own API
      final response = await _dio.get(
        '$_baseUrl/food/search',
        queryParameters: {'q': query},
      );

      if (response.statusCode == 200) {
        return (response.data as List)
            .map((e) => FoodItem.fromJson(e))
            .toList();
      } else {
        throw Exception('Failed to search food');
      }
    } catch (e) {
      throw Exception('Error searching food: $e');
    }
  }
}
