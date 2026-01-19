import '../services/supabase_service.dart';

/// Service for managing body measurements
class BodyMeasurementsService {
  final _client = SupabaseService.instance.client;

  /// Get all measurements for a user, optionally filtered by type
  Future<List<Map<String, dynamic>>> getMeasurements({
    String? measurementType,
    int? limit,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Build query based on filters
      dynamic query = _client
          .from('body_measurements')
          .select()
          .eq('user_id', userId);

      if (measurementType != null) {
        query = query.eq('measurement_type', measurementType);
      }

      query = query.order('measured_at', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error loading measurements: $e');
    }
  }

  /// Get latest measurement for each type
  Future<Map<String, Map<String, dynamic>>> getLatestMeasurements() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final allMeasurements = await getMeasurements();
      
      // Group by type and get latest for each
      final Map<String, Map<String, dynamic>> latestByType = {};
      
      for (var measurement in allMeasurements) {
        final type = measurement['measurement_type'] as String;
        if (!latestByType.containsKey(type)) {
          latestByType[type] = measurement;
        }
      }

      return latestByType;
    } catch (e) {
      throw Exception('Error loading latest measurements: $e');
    }
  }

  /// Add a new measurement
  Future<void> addMeasurement({
    required String measurementType,
    required double value,
    String? notes,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _client.from('body_measurements').insert({
        'user_id': userId,
        'measurement_type': measurementType,
        'value': value,
        'notes': notes,
        'measured_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Error adding measurement: $e');
    }
  }

  /// Delete a measurement
  Future<void> deleteMeasurement(String measurementId) async {
    try {
      await _client
          .from('body_measurements')
          .delete()
          .eq('id', measurementId);
    } catch (e) {
      throw Exception('Error deleting measurement: $e');
    }
  }

  /// Get measurement history for a specific type
  Future<List<Map<String, dynamic>>> getMeasurementHistory(
    String measurementType, {
    int? limit = 10,
  }) async {
    return getMeasurements(
      measurementType: measurementType,
      limit: limit,
    );
  }
}
