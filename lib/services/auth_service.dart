import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../services/app_cache_service.dart';

class AuthService {
  final SupabaseClient _client = SupabaseService.instance.client;

  // Sign Up
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String? captchaToken,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
        emailRedirectTo: null,
        captchaToken: captchaToken,
      ).timeout(const Duration(seconds: 15));
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
      ).timeout(const Duration(seconds: 15));
      return response;
    } catch (error) {
      throw Exception('Sign-in failed: $error');
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      AppCacheService.instance.invalidateAll();
      await _client.auth.signOut().timeout(const Duration(seconds: 10));
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
          .maybeSingle()
          .timeout(const Duration(seconds: 10));
      return response;
    } catch (error) {
      throw Exception('Failed to fetch profile: $error');
    }
  }

  // Resend confirmation email (20.1)
  Future<void> resendConfirmationEmail(String email) async {
    try {
      await _client.auth.resend(
        type: OtpType.signup,
        email: email,
      ).timeout(const Duration(seconds: 15));
    } catch (error) {
      throw Exception('Resend confirmation failed: $error');
    }
  }

  // Refresh session and return updated user (20.1)
  Future<User?> refreshSession() async {
    try {
      final response = await _client.auth
          .refreshSession()
          .timeout(const Duration(seconds: 15));
      return response.user;
    } catch (error) {
      throw Exception('Session refresh failed: $error');
    }
  }

  // Send password reset email (20.2)
  Future<void> resetPassword(String email) async {
    try {
      await _client.auth
          .resetPasswordForEmail(email)
          .timeout(const Duration(seconds: 15));
    } catch (error) {
      throw Exception('Password reset failed: $error');
    }
  }

  // Update password for logged-in user (20.2)
  Future<void> updatePassword(String newPassword) async {
    try {
      await _client.auth
          .updateUser(UserAttributes(password: newPassword))
          .timeout(const Duration(seconds: 15));
    } catch (error) {
      throw Exception('Password update failed: $error');
    }
  }

  // Delete account: re-auth then cascade-delete via RPC (20.8)
  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    try {
      // Re-authenticate first for security
      await _client.auth.signInWithPassword(
        email: email,
        password: password,
      ).timeout(const Duration(seconds: 15));

      // Cascade-delete all user data + auth row
      await _client.rpc('delete_my_account').timeout(const Duration(seconds: 15));

      AppCacheService.instance.invalidateAll();
      await _client.auth.signOut().timeout(const Duration(seconds: 10));
    } catch (error) {
      throw Exception('Account deletion failed: $error');
    }
  }
}
