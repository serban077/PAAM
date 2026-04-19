import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../routes/app_routes.dart';
import '../../services/mfa_service.dart';
import '../../widgets/custom_icon_widget.dart';

class TotpChallengeScreen extends StatefulWidget {
  final String factorId;

  const TotpChallengeScreen({super.key, required this.factorId});

  @override
  State<TotpChallengeScreen> createState() => _TotpChallengeScreenState();
}

class _TotpChallengeScreenState extends State<TotpChallengeScreen> {
  final _mfaService = MfaService();
  final _otpController = TextEditingController();
  bool _isVerifying = false;
  String? _error;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify(String code) async {
    if (code.length != 6) return;
    setState(() {
      _isVerifying = true;
      _error = null;
    });
    try {
      await _mfaService.verifyEnrollment(
        factorId: widget.factorId,
        code: code,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(
          context, AppRoutes.authenticationOnboardingFlow);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Invalid code. Please try again.';
        _otpController.clear();
      });
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  void _showBackupCodeDialog() {
    final backupController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter Backup Code'),
        content: TextField(
          controller: backupController,
          decoration: const InputDecoration(
            hintText: 'xxxxxxxx',
            border: OutlineInputBorder(),
          ),
          maxLength: 10,
          keyboardType: TextInputType.text,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Backup codes are used the same way as TOTP codes in Supabase MFA
              _verify(backupController.text.trim());
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    ).then((_) => backupController.dispose());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [const Color(0xFF1A1A2E), const Color(0xFF1B5E20)]
                      : [const Color(0xFF81C784), const Color(0xFF2E7D32)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: 5.h),
                Container(
                  width: 20.w,
                  height: 20.w,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: CustomIconWidget(
                      iconName: 'security',
                      color: Colors.white,
                      size: 10.w,
                    ),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Two-Factor Authentication',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'Enter the 6-digit code from your\nauthenticator app',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                SizedBox(height: 4.h),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(28)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8.w, vertical: 5.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28.sp,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 8,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: '000000',
                              hintStyle: TextStyle(
                                color: scheme.onSurface.withValues(alpha: 0.3),
                                letterSpacing: 8,
                                fontSize: 28.sp,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onChanged: (v) {
                              if (v.length == 6) _verify(v);
                            },
                          ),
                          if (_error != null) ...[
                            SizedBox(height: 1.5.h),
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: scheme.error,
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                          SizedBox(height: 4.h),
                          ElevatedButton(
                            onPressed: _isVerifying
                                ? null
                                : () => _verify(_otpController.text),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: scheme.tertiary,
                              foregroundColor: scheme.onTertiary,
                              padding: EdgeInsets.symmetric(vertical: 1.8.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isVerifying
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: scheme.onTertiary,
                                    ),
                                  )
                                : Text(
                                    'Verify',
                                    style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600),
                                  ),
                          ),
                          SizedBox(height: 2.h),
                          TextButton(
                            onPressed: _showBackupCodeDialog,
                            child: Text(
                              'Use a backup code',
                              style: TextStyle(fontSize: 12.sp),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
