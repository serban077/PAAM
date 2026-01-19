import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
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

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    SupabaseService.instance.client.auth.onAuthStateChange.listen((data) {
      final user = data.session?.user;
      setState(() {
        _currentUser = user;
        _isCheckingAuth = true; // Start check on any auth change
      });
      if (user != null) {
        _checkOnboardingStatus();
      } else {
        setState(() {
          _isCheckingAuth = false;
          _isOnboardingComplete = false;
        });
      }
    });
  }

  Future<void> _checkOnboardingStatus() async {
    if (_currentUser == null) {
      setState(() => _isCheckingAuth = false);
      return;
    }

    try {
      final response = await SupabaseService.instance.client
          .from('onboarding_responses')
          .select('id')
          .eq('user_id', _currentUser!.id)
          .limit(1);

      final isComplete = response.isNotEmpty;
      setState(() {
        _isOnboardingComplete = isComplete;
        _isCheckingAuth = false;
      });

      if (isComplete && mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.mainDashboard);
      }
    } catch (e) {
      debugPrint('Error checking onboarding status: $e');
      setState(() => _isCheckingAuth = false);
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
          .signInWithPassword(email: email, password: password);
      // Auth state listener will handle the rest
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRegister(
      String email, String password, String fullName) async {
    setState(() => _isLoading = true);
    try {
      await SupabaseService.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
      // Auth state listener will handle the rest
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_currentUser != null && !_isOnboardingComplete) {
      return const OnboardingSurveyWidget();
    }

    if (_currentUser == null) {
      return Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(5.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 5.h),
                Text(
                  'SmartFit AI',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  _isLogin ? 'Conectează-te' : 'Creează cont',
                  style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4.h),
                _isLogin
                    ? LoginFormWidget(
                        onLogin: _handleLogin,
                        isLoading: _isLoading,
                      )
                    : RegisterFormWidget(
                        onRegister: _handleRegister,
                        isLoading: _isLoading,
                      ),
                SizedBox(height: 3.h),
                TextButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin),
                  child: Text(
                    _isLogin
                        ? 'Nu ai cont? Înregistrează-te'
                        : 'Ai deja cont? Conectează-te',
                    style: TextStyle(fontSize: 14.sp),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // This case should ideally not be reached if navigation works correctly
    // but as a fallback, show a loading screen or an error.
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
