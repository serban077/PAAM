import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class AuthService {
  final SupabaseClient _client = SupabaseService.instance.client;

  // Sign Up
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
      return response;
    } catch (error) {
      throw Exception('Sign-up failed: $error');
    }
  }

  // Sign In
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (error) {
      throw Exception('Sign-in failed: $error');
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (error) {
      throw Exception('Sign-out failed: $error');
    }
  }

  // Get Current User
  User? getCurrentUser() {
    return _client.auth.currentUser;
  }

  // Check if user is authenticated
  bool isAuthenticated() {
    return _client.auth.currentUser != null;
  }

  // Get Auth State Stream
  Stream<AuthState> get authStateChanges {
    return _client.auth.onAuthStateChange;
  }

  // Update User Profile
  Future<void> updateUserProfile({
    required Map<String, dynamic> profileData,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      await _client.from('user_profiles').update(profileData).eq('id', userId);
    } catch (error) {
      throw Exception('Profile update failed: $error');
    }
  }

  // Get User Profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      final response = await _client
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to fetch profile: $error');
    }
  }
}
