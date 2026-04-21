import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/analytics_service.dart';
import '../../../widgets/password_strength_indicator.dart';

class RegisterFormWidget extends StatefulWidget {
  final Function(String email, String password, String fullName) onRegister;
  final bool isLoading;

  const RegisterFormWidget({
    super.key,
    required this.onRegister,
    required this.isLoading,
  });

  @override
  State<RegisterFormWidget> createState() => _RegisterFormWidgetState();
}

class _RegisterFormWidgetState extends State<RegisterFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      if (!_acceptedTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please accept the terms and conditions')),
        );
        return;
      }
      unawaited(AnalyticsService.instance.track('signup_started'));
      widget.onRegister(
        _emailController.text.trim(),
        _passwordController.text,
        _fullNameController.text.trim(),
      );
    }
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
          // Full Name
          TextFormField(
            controller: _fullNameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Full Name',
              prefixIcon: CustomIconWidget(
                iconName: 'person_outlined',
                size: 22,
                color: iconColor,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Enter your full name';
              return null;
            },
          ),
          SizedBox(height: 2.h),

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
            onChanged: (_) => setState(() {}),
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
              if (value == null || value.isEmpty) return 'Enter a password';
              if (value.length < 8) return 'At least 8 characters';
              if (!value.contains(RegExp(r'[A-Z]'))) {
                return 'Add at least one uppercase letter';
              }
              if (!value.contains(RegExp(r'\d'))) {
                return 'Add at least one number';
              }
              return null;
            },
          ),
          PasswordStrengthIndicator(password: _passwordController.text),
          SizedBox(height: 2.h),

          // Confirm Password
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: CustomIconWidget(
                iconName: 'lock_outlined',
                size: 22,
                color: iconColor,
              ),
              suffixIcon: IconButton(
                icon: CustomIconWidget(
                  iconName: _obscureConfirmPassword
                      ? 'visibility_off_outlined'
                      : 'visibility_outlined',
                  size: 22,
                  color: iconColor,
                ),
                onPressed: () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Confirm your password';
              if (value != _passwordController.text) {
                return "Passwords don't match";
              }
              return null;
            },
          ),
          SizedBox(height: 1.5.h),

          // Terms
          InkWell(
            onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 0.5.h),
              child: Row(
                children: [
                  SizedBox(
                    width: 6.w,
                    height: 6.w,
                    child: Checkbox(
                      value: _acceptedTerms,
                      onChanged: (value) =>
                          setState(() => _acceptedTerms = value ?? false),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'I accept the terms and conditions',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: isDark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 2.h),

          // Create Account button
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
                      'Create Account',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
