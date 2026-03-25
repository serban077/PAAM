import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import './widgets/login_form_widget.dart';
import './widgets/onboarding_survey_widget.dart';
import './widgets/register_form_widget.dart';

class AuthenticationOnboardingFlow extends StatefulWidget {
  const AuthenticationOnboardingFlow({super.key});

  @override
  State<AuthenticationOnboardingFlow> createState() =>
      _AuthenticationOnboardingFlowState();
}

class _AuthenticationOnboardingFlowState
    extends State<AuthenticationOnboardingFlow> {
  bool _isLogin = true;
  bool _isLoading = false;
  User? _currentUser;
  bool _isCheckingAuth = true;
  bool _isOnboardingComplete = false;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    _authSubscription =
        SupabaseService.instance.client.auth.onAuthStateChange.listen((data) {
      final user = data.session?.user;

      if (user != null) {
        if (mounted) {
          setState(() {
            _currentUser = user;
            _isCheckingAuth = true;
          });
        }
        _checkOnboardingStatus();
      } else {
        if (mounted) {
          setState(() {
            _currentUser = null;
            _isCheckingAuth = false;
            _isOnboardingComplete = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkOnboardingStatus() async {
    if (_currentUser == null) {
      if (mounted) setState(() => _isCheckingAuth = false);
      return;
    }

    try {
      final response = await SupabaseService.instance.client
          .from('onboarding_responses')
          .select('id')
          .eq('user_id', _currentUser!.id)
          .limit(1)
          .timeout(const Duration(seconds: 15));

      final isComplete = response.isNotEmpty;
      if (mounted) {
        setState(() {
          _isOnboardingComplete = isComplete;
          _isCheckingAuth = false;
        });
      }

      if (isComplete && mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.mainDashboard);
      }
    } catch (e) {
      debugPrint('Error checking onboarding status: $e');
      if (mounted) setState(() => _isCheckingAuth = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not verify your onboarding status.'),
          ),
        );
      }
    }
  }

  Future<void> _handleLogin(String email, String password) async {
    setState(() => _isLoading = true);
    try {
      await SupabaseService.instance.client.auth
          .signInWithPassword(email: email, password: password)
          .timeout(const Duration(seconds: 15));
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Login failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRegister(
      String email, String password, String fullName) async {
    setState(() => _isLoading = true);
    try {
      await SupabaseService.instance.client.auth
          .signUp(
            email: email,
            password: password,
            data: {'full_name': fullName},
          )
          .timeout(const Duration(seconds: 15));
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Registration failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isCheckingAuth) return _buildSplashScreen(isDark);

    if (_currentUser != null && !_isOnboardingComplete) {
      return const OnboardingSurveyWidget();
    }

    if (_currentUser == null) return _buildAuthScreen(isDark);

    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }

  // ── Splash ────────────────────────────────────────────────────────

  Widget _buildSplashScreen(bool isDark) {
    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/images/img_app_logo.svg',
              width: 28.w,
              height: 28.w,
            ),
            SizedBox(height: 4.h),
            Text(
              'SmartFitAI',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            SizedBox(height: 6.h),
            SizedBox(
              width: 6.w,
              height: 6.w,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Auth Screen ───────────────────────────────────────────────────

  Widget _buildAuthScreen(bool isDark) {
    final gradientColors = isDark
        ? [AppTheme.backgroundDark, AppTheme.primaryVariantDark]
        : [AppTheme.primaryVariantLight, AppTheme.primaryLight];

    final cardColor = isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: gradientColors,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: 28.h, child: _buildHeroSection()),
                Expanded(child: _buildFormCard(isDark, cardColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero ───────────────────────────────────────────────────────────

  Widget _buildHeroSection() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/images/img_app_logo.svg',
            width: 18.w,
            height: 18.w,
            colorFilter: const ColorFilter.mode(
              Colors.white,
              BlendMode.srcIn,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'SmartFitAI',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
          ),
        ],
      ),
    );
  }

  // ── Form Card ──────────────────────────────────────────────────────

  Widget _buildFormCard(bool isDark, Color cardColor) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: isDark
            ? Border(
                top: BorderSide(
                  color: AppTheme.primaryDark.withValues(alpha: 0.25),
                  width: 1,
                ),
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.35)
                : AppTheme.shadowLight,
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(6.w, 2.5.h, 6.w, 4.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 10.w,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 2.5.h),

            // Tab switcher
            _buildTabSwitcher(isDark),
            SizedBox(height: 3.h),

            // Animated form
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: KeyedSubtree(
                key: ValueKey(_isLogin),
                child: _isLogin
                    ? LoginFormWidget(
                        onLogin: _handleLogin,
                        isLoading: _isLoading,
                      )
                    : RegisterFormWidget(
                        onRegister: _handleRegister,
                        isLoading: _isLoading,
                      ),
              ),
            ),
            SizedBox(height: 1.5.h),

            // Toggle link
            Center(
              child: GestureDetector(
                onTap: () => setState(() => _isLogin = !_isLogin),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 1.h),
                  child: RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium,
                      children: [
                        TextSpan(
                          text: _isLogin
                              ? "Don't have an account?  "
                              : 'Already have an account?  ',
                          style: TextStyle(
                            color: isDark
                                ? AppTheme.textSecondaryDark
                                : AppTheme.textSecondaryLight,
                          ),
                        ),
                        TextSpan(
                          text: _isLogin ? 'Sign Up' : 'Sign In',
                          style: TextStyle(
                            color: isDark
                                ? AppTheme.primaryDark
                                : AppTheme.primaryLight,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tabs ───────────────────────────────────────────────────────────

  Widget _buildTabSwitcher(bool isDark) {
    final activeColor = isDark ? AppTheme.primaryDark : AppTheme.primaryLight;
    final inactiveColor =
        isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight;

    return Row(
      children: [
        _buildTabItem('Sign In', _isLogin, activeColor, inactiveColor,
            () => setState(() => _isLogin = true)),
        SizedBox(width: 8.w),
        _buildTabItem('Sign Up', !_isLogin, activeColor, inactiveColor,
            () => setState(() => _isLogin = false)),
      ],
    );
  }

  Widget _buildTabItem(String label, bool isActive, Color activeColor,
      Color inactiveColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  color: isActive ? activeColor : inactiveColor,
                ),
          ),
          SizedBox(height: 0.5.h),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            height: 3,
            width: isActive ? 12.w : 0,
            decoration: BoxDecoration(
              color: activeColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
