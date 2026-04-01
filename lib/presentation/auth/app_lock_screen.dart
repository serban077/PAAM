import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../routes/app_routes.dart';
import '../../services/biometric_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_icon_widget.dart';
import '../main_dashboard/main_dashboard.dart';

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen>
    with SingleTickerProviderStateMixin {
  final _biometricService = BiometricService();
  bool _isAuthenticating = false;
  bool _failed = false;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    // Trigger biometric after first frame so the screen is visible first
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _tryBiometric() async {
    if (_isAuthenticating || !mounted) return;
    setState(() {
      _isAuthenticating = true;
      _failed = false;
    });
    _pulseController.repeat(reverse: true);
    try {
      final success = await _biometricService.authenticate(
        'Unlock SmartFitAI to continue',
      );
      if (!mounted) return;
      _pulseController.stop();
      _pulseController.reset();
      if (success) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 450),
            pageBuilder: (_, __, ___) => const MainDashboard(),
            transitionsBuilder: (_, animation, __, child) => FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
              child: child,
            ),
          ),
        );
        return;
      } else {
        setState(() => _failed = true);
      }
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [const Color(0xFF0D0D1A), const Color(0xFF1B2A1B)]
                  : [const Color(0xFF1B5E20), const Color(0xFF2E7D32)],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                // Icon with pulse ring during scan
                ScaleTransition(
                  scale: _isAuthenticating
                      ? _pulseAnimation
                      : const AlwaysStoppedAnimation(1.0),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_isAuthenticating)
                        Container(
                          width: 30.w,
                          height: 30.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                              width: 2,
                            ),
                          ),
                        ),
                      Container(
                        width: 24.w,
                        height: 24.w,
                        decoration: BoxDecoration(
                          color: _isAuthenticating
                              ? Colors.white.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: CustomIconWidget(
                            iconName: _isAuthenticating ? 'fingerprint' : 'lock',
                            color: Colors.white,
                            size: 12.w,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 4.h),
                Text(
                  'SmartFitAI is locked',
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 1.h),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    _isAuthenticating
                        ? 'Scanning…'
                        : 'Authenticate to continue',
                    key: ValueKey(_isAuthenticating),
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ),

                SizedBox(height: 6.h),

                if (_failed)
                  Padding(
                    padding: EdgeInsets.only(bottom: 2.h),
                    child: Text(
                      'Authentication failed. Try again.',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.red.shade300,
                      ),
                    ),
                  ),

                ElevatedButton.icon(
                  onPressed: _isAuthenticating ? null : _tryBiometric,
                  icon: _isAuthenticating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF2E7D32),
                          ),
                        )
                      : CustomIconWidget(
                          iconName: 'fingerprint',
                          color: const Color(0xFF2E7D32),
                          size: 22,
                        ),
                  label: Text(
                    _isAuthenticating ? 'Scanning…' : 'Unlock with Biometrics',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF2E7D32),
                    disabledBackgroundColor: Colors.white.withValues(alpha: 0.7),
                    padding: EdgeInsets.symmetric(
                        horizontal: 8.w, vertical: 1.8.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),

                const Spacer(),

                TextButton(
                  onPressed: () {
                    SupabaseService.instance.client.auth
                        .signOut()
                        .catchError((_) => null);
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.loginScreen,
                      (route) => false,
                    );
                  },
                  child: Text(
                    'Use email & password instead',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                ),
                SizedBox(height: 3.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
