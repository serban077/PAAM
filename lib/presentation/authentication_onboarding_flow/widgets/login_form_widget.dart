import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/biometric_service.dart';
import '../../../services/session_service.dart';

class LoginFormWidget extends StatefulWidget {
  final Function(String email, String password) onLogin;
  final bool isLoading;

  const LoginFormWidget({
    super.key,
    required this.onLogin,
    required this.isLoading,
  });

  @override
  State<LoginFormWidget> createState() => _LoginFormWidgetState();
}

class _LoginFormWidgetState extends State<LoginFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _sessionService = SessionService();
  final _biometricService = BiometricService();
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isBiometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final remember = await _sessionService.rememberMe;
    final biometricAvail = await _biometricService.isAvailable();
    if (mounted) {
      setState(() {
        _rememberMe = remember;
        _isBiometricAvailable = biometricAvail;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      _sessionService.setRememberMe(_rememberMe);
      widget.onLogin(_emailController.text.trim(), _passwordController.text);
    }
  }

  void _fillDemoCredentials() {
    _emailController.text = 'test@smartfitai.ro';
    _passwordController.text = 'Test123!';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: CustomIconWidget(
                iconName: 'email_outlined',
                size: 22,
                color: iconColor,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Enter your email';
              if (!value.contains('@')) return 'Invalid email';
              return null;
            },
          ),
          SizedBox(height: 2.h),

          // Password
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: CustomIconWidget(
                iconName: 'lock_outlined',
                size: 22,
                color: iconColor,
              ),
              suffixIcon: IconButton(
                icon: CustomIconWidget(
                  iconName: _obscurePassword
                      ? 'visibility_off_outlined'
                      : 'visibility_outlined',
                  size: 22,
                  color: iconColor,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Enter your password';
              return null;
            },
          ),
          SizedBox(height: 0.5.h),

          // Forgot password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.forgotPassword),
              style: TextButton.styleFrom(
                padding:
                    EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                minimumSize: Size.zero,
              ),
              child: Text(
                'Forgot password?',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: isDark
                      ? AppTheme.secondaryDark
                      : AppTheme.secondaryLight,
                ),
              ),
            ),
          ),
          SizedBox(height: 1.h),

          // Remember me
          InkWell(
            onTap: () => setState(() => _rememberMe = !_rememberMe),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 0.5.h),
              child: Row(
                children: [
                  SizedBox(
                    width: 6.w,
                    height: 6.w,
                    child: Checkbox(
                      value: _rememberMe,
                      onChanged: (v) =>
                          setState(() => _rememberMe = v ?? true),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Remember me',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: isDark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 2.h),

          // Sign In button
          SizedBox(
            height: 6.5.h,
            child: ElevatedButton(
              onPressed: widget.isLoading ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.tertiary,
                foregroundColor: Theme.of(context).colorScheme.onTertiary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: widget.isLoading
                  ? SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Theme.of(context).colorScheme.onTertiary,
                      ),
                    )
                  : Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
            ),
          ),
          SizedBox(height: 1.5.h),

          // Biometric login shortcut
          if (_isBiometricAvailable) ...[
            OutlinedButton.icon(
              onPressed: () async {
                final success = await _biometricService.authenticate(
                  'Sign in to SmartFitAI',
                );
                if (success && context.mounted) {
                  // Session already restored via SessionService on app start;
                  // biometric just confirms identity — trigger auth state re-check
                  Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.authenticationOnboardingFlow,
                  );
                }
              },
              icon: CustomIconWidget(
                iconName: 'fingerprint',
                size: 20,
                color: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
              ),
              label: Text(
                'Sign in with Biometrics',
                style: TextStyle(fontSize: 13.sp),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: Size(double.infinity, 5.5.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
            SizedBox(height: 1.5.h),
          ],

          // Demo credentials hint
          Center(
            child: GestureDetector(
              onTap: _fillDemoCredentials,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 0.8.h),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomIconWidget(
                      iconName: 'info_outline',
                      size: 14,
                      color: isDark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight,
                    ),
                    SizedBox(width: 1.5.w),
                    Text(
                      'Tap to fill demo credentials',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: isDark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
