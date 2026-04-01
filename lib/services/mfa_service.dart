import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class MfaService {
  final SupabaseClient _client = SupabaseService.instance.client;

  /// Enroll a new TOTP factor.
  /// Returns a map with keys: `qrUri`, `secret`, `factorId`.
  Future<Map<String, String>> enrollTotp() async {
    try {
      final response = await _client.auth.mfa
          .enroll(factorType: FactorType.totp, issuer: 'SmartFitAI')
          .timeout(const Duration(seconds: 15));
      final totp = response.totp;
      if (totp == null) throw Exception('TOTP data missing in enrollment response');
      return {
        'qrUri': totp.uri,
        'secret': totp.secret,
        'factorId': response.id,
      };
    } catch (error) {
      throw Exception('TOTP enrollment failed: $error');
    }
  }

  /// Verify a TOTP enrollment by challenging and verifying the OTP code.
  Future<void> verifyEnrollment({
    required String factorId,
    required String code,
  }) async {
    try {
      final challenge = await _client.auth.mfa
          .challenge(factorId: factorId)
          .timeout(const Duration(seconds: 15));
      await _client.auth.mfa
          .verify(
            factorId: factorId,
            challengeId: challenge.id,
            code: code,
          )
          .timeout(const Duration(seconds: 15));
    } catch (error) {
      throw Exception('TOTP verification failed: $error');
    }
  }

  /// Returns list of enrolled TOTP factors for the current user.
  Future<List<Factor>> listFactors() async {
    try {
      final response = await _client.auth.mfa
          .listFactors()
          .timeout(const Duration(seconds: 15));
      return response.totp;
    } catch (error) {
      throw Exception('List factors failed: $error');
    }
  }

  /// Unenroll (disable) a TOTP factor by its ID.
  Future<void> unenroll(String factorId) async {
    try {
      await _client.auth.mfa
          .unenroll(factorId)
          .timeout(const Duration(seconds: 15));
    } catch (error) {
      throw Exception('TOTP unenroll failed: $error');
    }
  }

  /// Returns true if the current user has a verified TOTP factor.
  Future<bool> get isTotpEnabled async {
    final factors = await listFactors();
    return factors.any((f) => f.status == FactorStatus.verified);
  }

  /// Returns the factorId of the first verified TOTP factor, or null.
  Future<String?> get verifiedFactorId async {
    final factors = await listFactors();
    final verified = factors.where((f) => f.status == FactorStatus.verified);
    return verified.isEmpty ? null : verified.first.id;
  }

  /// Check current authenticator assurance level.
  /// Returns true if MFA challenge is needed (factor enrolled but not yet verified this session).
  Future<bool> needsMfaChallenge() async {
    try {
      final response = _client.auth.mfa.getAuthenticatorAssuranceLevel();
      // nextLevel is aal2 when a TOTP factor is enrolled; currentLevel is aal1
      // until the user completes the TOTP challenge for this session.
      return response.nextLevel?.name == 'aal2' &&
          response.currentLevel?.name == 'aal1';
    } catch (_) {
      return false;
    }
  }
}
