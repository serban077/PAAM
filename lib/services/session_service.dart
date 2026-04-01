import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class SessionService {
  static const _tokenKey = 'supabase_refresh_token';
  static const _rememberMeKey = 'remember_me';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Persist the refresh token to secure storage.
  Future<void> persistSession(Session session) async {
    try {
      await _storage.write(key: _tokenKey, value: session.refreshToken);
    } catch (_) {
      // Non-fatal — session will just not survive cold restart
    }
  }

  /// Restore a persisted session on app cold start.
  /// Returns the restored User, or null if no token stored / refresh fails.
  Future<User?> loadPersistedSession() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token == null) return null;
      final response = await SupabaseService.instance.client.auth
          .setSession(token)
          .timeout(const Duration(seconds: 15));
      return response.user;
    } catch (_) {
      await clearSession();
      return null;
    }
  }

  /// Clear stored token (call on explicit sign-out).
  Future<void> clearSession() async {
    try {
      await _storage.delete(key: _tokenKey);
    } catch (_) {}
  }

  /// Whether the user opted into "remember me".
  Future<bool> get rememberMe async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberMeKey) ?? true; // default: checked
  }

  Future<void> setRememberMe(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, value);
  }
}
