import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_icon_widget.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  bool _isChecking = false;
  bool _isResending = false;
  int _cooldown = 0;
  Timer? _cooldownTimer;
  late final AnimationController _iconController;
  late final Animation<double> _iconScale;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _iconScale = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _iconController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _resendEmail() async {
    if (_cooldown > 0 || _isResending) return;
    setState(() => _isResending = true);
    try {
      await _authService.resendConfirmationEmail(widget.email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email sent!')),
      );
      setState(() => _cooldown = 60);
      _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        setState(() {
          _cooldown--;
          if (_cooldown <= 0) t.cancel();
        });
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to resend: $e')),
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _checkConfirmation() async {
    setState(() => _isChecking = true);
    try {
      final user = await _authService.refreshSession();
      if (!mounted) return;
      if (user?.emailConfirmedAt != null) {
        Navigator.pushReplacementNamed(
            context, AppRoutes.authenticationOnboardingFlow);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email not confirmed yet. Please check your inbox.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
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
                SizedBox(height: 6.h),
                ScaleTransition(
                  scale: _iconScale,
                  child: Container(
                    width: 22.w,
                    height: 22.w,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: CustomIconWidget(
                        iconName: 'mark_email_unread',
                        color: Colors.white,
                        size: 11.w,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  'Check your inbox',
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 1.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                  child: Text(
                    'We sent a verification link to\n${widget.email}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ),
                SizedBox(height: 5.h),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(28)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 24,
                          offset: const Offset(0, -6),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(6.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: 2.h),
                          Text(
                            'After confirming your email, tap the button below.',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: scheme.onSurface.withValues(alpha: 0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 4.h),
                          ElevatedButton(
                            onPressed: _isChecking ? null : _checkConfirmation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: scheme.tertiary,
                              foregroundColor: scheme.onTertiary,
                              padding: EdgeInsets.symmetric(vertical: 1.8.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isChecking
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: scheme.onTertiary,
                                    ),
                                  )
                                : Text(
                                    "I've confirmed my email",
                                    style:
                                        TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                                  ),
                          ),
                          SizedBox(height: 2.h),
                          TextButton(
                            onPressed: (_cooldown > 0 || _isResending)
                                ? null
                                : _resendEmail,
                            child: Text(
                              _cooldown > 0
                                  ? 'Resend in ${_cooldown}s'
                                  : 'Resend verification email',
                              style: TextStyle(fontSize: 13.sp),
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => Navigator.pushReplacementNamed(
                                context, AppRoutes.authenticationOnboardingFlow),
                            child: Text(
                              'Back to Login',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: scheme.onSurface.withValues(alpha: 0.5),
                              ),
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
