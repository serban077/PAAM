import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

enum _PasswordStrength { weak, fair, strong, veryStrong }

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({super.key, required this.password});

  _PasswordStrength _evaluate(String pw) {
    if (pw.length < 8) return _PasswordStrength.weak;
    final hasDigit = pw.contains(RegExp(r'\d'));
    final hasUpper = pw.contains(RegExp(r'[A-Z]'));
    final hasSpecial = pw.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
    if (pw.length >= 12 && hasDigit && hasSpecial && hasUpper) {
      return _PasswordStrength.veryStrong;
    }
    if (pw.length >= 12 && hasDigit) return _PasswordStrength.strong;
    return _PasswordStrength.fair;
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    final strength = _evaluate(password);
    final (label, color, value, hint) = switch (strength) {
      _PasswordStrength.weak => (
          'Weak',
          Colors.red,
          0.25,
          'Use at least 8 characters',
        ),
      _PasswordStrength.fair => (
          'Fair',
          Colors.orange,
          0.50,
          'Add a number and uppercase letter',
        ),
      _PasswordStrength.strong => (
          'Strong',
          Colors.lightGreen,
          0.75,
          'Add a special character for max security',
        ),
      _PasswordStrength.veryStrong => (
          'Very Strong',
          Colors.green,
          1.0,
          'Great password!',
        ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 0.8.h),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          height: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        SizedBox(height: 0.5.h),
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const Spacer(),
            Text(
              hint,
              style: TextStyle(
                fontSize: 10.sp,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
