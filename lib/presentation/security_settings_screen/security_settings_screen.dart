import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../routes/app_routes.dart';
import '../../services/analytics_service.dart';
import '../../services/auth_service.dart';
import '../../services/biometric_service.dart';
import '../../services/mfa_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_icon_widget.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  final _authService = AuthService();
  final _biometricService = BiometricService();
  final _mfaService = MfaService();

  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;
  bool _isTotpEnabled = false;
  String? _verifiedFactorId;
  bool _isAnalyticsEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _biometricService.isAvailable(),
        _biometricService.isBiometricEnabled,
        _mfaService.isTotpEnabled,
        _mfaService.verifiedFactorId,
        AnalyticsService.instance.isOptedOut(),
      ]);
      if (!mounted) return;
      setState(() {
        _isBiometricAvailable = results[0] as bool;
        _isBiometricEnabled = results[1] as bool;
        _isTotpEnabled = results[2] as bool;
        _verifiedFactorId = results[3] as String?;
        _isAnalyticsEnabled = !(results[4] as bool);
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleBiometric(bool enabled) async {
    if (enabled) {
      final confirmed = await _biometricService.authenticate(
        'Confirm your identity to enable biometric login',
      );
      if (!confirmed) return;
    }
    await _biometricService.setBiometricEnabled(enabled);
    if (mounted) setState(() => _isBiometricEnabled = enabled);
  }

  Future<void> _openTwoFactorSetup() async {
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.twoFactorSetup,
    );
    if (result == true) await _loadState();
  }

  Future<void> _disableTotp() async {
    final confirmed = await _showConfirmDialog(
      title: 'Disable 2FA',
      message:
          'Are you sure you want to disable two-factor authentication? Your account will be less secure.',
      confirmLabel: 'Disable',
      isDestructive: true,
    );
    if (!confirmed) return;

    try {
      if (_verifiedFactorId != null) {
        await _mfaService.unenroll(_verifiedFactorId!);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Two-factor authentication disabled.')),
        );
        await _loadState();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _sendChangePasswordEmail() async {
    final user = _authService.getCurrentUser();
    if (user?.email == null) return;
    try {
      await _authService.resetPassword(user!.email!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset link sent to ${user.email}'),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _signOutAllDevices() async {
    final confirmed = await _showConfirmDialog(
      title: 'Sign Out All Devices',
      message: 'This will sign out all other devices. You will remain logged in on this one.',
      confirmLabel: 'Sign Out Others',
      isDestructive: false,
    );
    if (!confirmed) return;

    try {
      await SupabaseService.instance.client.auth
          .signOut(scope: SignOutScope.others)
          .timeout(const Duration(seconds: 15));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All other devices signed out.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deleteAccount() async {
    // Step 1: Warn
    final proceed = await _showConfirmDialog(
      title: 'Delete Account',
      message:
          'This will permanently delete your account and all data. This cannot be undone.',
      confirmLabel: 'Continue',
      isDestructive: true,
    );
    if (!proceed) return;

    if (!mounted) return;
    // Step 2: Ask for password re-auth
    final passwordController = TextEditingController();
    final reauthed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm your password'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    final password = passwordController.text;
    passwordController.dispose();

    if (reauthed != true || password.isEmpty) return;

    try {
      final user = _authService.getCurrentUser();
      if (user?.email == null) return;
      await _authService.deleteAccount(email: user!.email!, password: password);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.authenticationOnboardingFlow,
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('Invalid') || e.toString().contains('password')
                  ? 'Incorrect password. Please try again.'
                  : 'Failed to delete account: $e',
            ),
          ),
        );
      }
    }
  }

  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required bool isDestructive,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: isDestructive
                ? TextButton.styleFrom(foregroundColor: Colors.red)
                : null,
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              children: [
                _SectionHeader(title: 'Sign-In Methods'),
                _buildSignInMethodsCard(scheme),
                SizedBox(height: 2.h),
                _SectionHeader(title: 'Two-Factor Authentication'),
                _buildTwoFactorCard(scheme),
                SizedBox(height: 2.h),
                _SectionHeader(title: 'Password'),
                _buildPasswordCard(scheme),
                SizedBox(height: 2.h),
                _SectionHeader(title: 'Sessions'),
                _buildSessionsCard(scheme),
                SizedBox(height: 2.h),
                _SectionHeader(title: 'Analytics'),
                _buildAnalyticsCard(scheme),
                SizedBox(height: 2.h),
                _SectionHeader(title: 'Account'),
                _buildAccountCard(scheme),
                SizedBox(height: 4.h),
              ],
            ),
    );
  }

  Widget _buildSignInMethodsCard(ColorScheme scheme) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          ListTile(
            leading: CustomIconWidget(
              iconName: 'email',
              color: scheme.primary,
              size: 22,
            ),
            title: const Text('Email & Password'),
            trailing: Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.4.h),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Active',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (_isBiometricAvailable) ...[
            const Divider(height: 1, indent: 16, endIndent: 16),
            SwitchListTile(
              secondary: CustomIconWidget(
                iconName: 'fingerprint',
                color: scheme.primary,
                size: 22,
              ),
              title: const Text('Biometric Login'),
              subtitle: const Text('Fingerprint or Face ID'),
              value: _isBiometricEnabled,
              onChanged: _toggleBiometric,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTwoFactorCard(ColorScheme scheme) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          ListTile(
            leading: CustomIconWidget(
              iconName: 'security',
              color: scheme.primary,
              size: 22,
            ),
            title: const Text('Authenticator App (TOTP)'),
            trailing: Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.4.h),
              decoration: BoxDecoration(
                color: _isTotpEnabled
                    ? Colors.green.withValues(alpha: 0.12)
                    : scheme.onSurface.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _isTotpEnabled ? 'Enabled' : 'Disabled',
                style: TextStyle(
                  color: _isTotpEnabled
                      ? Colors.green.shade700
                      : scheme.onSurface.withValues(alpha: 0.55),
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            title: Text(
              _isTotpEnabled ? 'Disable 2FA' : 'Set up 2FA',
              style: TextStyle(
                color: _isTotpEnabled ? scheme.error : scheme.tertiary,
                fontWeight: FontWeight.w600,
                fontSize: 13.sp,
              ),
            ),
            trailing: CustomIconWidget(
              iconName: 'chevron_right',
              color: scheme.onSurface.withValues(alpha: 0.4),
              size: 20,
            ),
            onTap: _isTotpEnabled ? _disableTotp : _openTwoFactorSetup,
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordCard(ColorScheme scheme) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: CustomIconWidget(
          iconName: 'lock',
          color: scheme.primary,
          size: 22,
        ),
        title: const Text('Change Password'),
        subtitle: const Text('Send a reset link to your email'),
        trailing: CustomIconWidget(
          iconName: 'chevron_right',
          color: scheme.onSurface.withValues(alpha: 0.4),
          size: 20,
        ),
        onTap: _sendChangePasswordEmail,
      ),
    );
  }

  Widget _buildSessionsCard(ColorScheme scheme) {
    final user = _authService.getCurrentUser();
    final lastSignIn = user?.lastSignInAt;
    String lastSignInText = 'Unknown';
    if (lastSignIn != null) {
      final dt = DateTime.tryParse(lastSignIn);
      if (dt != null) {
        lastSignInText =
            '${dt.day}/${dt.month}/${dt.year} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
    }

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          ListTile(
            leading: CustomIconWidget(
              iconName: 'access_time',
              color: scheme.primary,
              size: 22,
            ),
            title: const Text('Last sign-in'),
            subtitle: Text(lastSignInText),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: CustomIconWidget(
              iconName: 'logout',
              color: scheme.primary,
              size: 22,
            ),
            title: const Text('Sign out all other devices'),
            trailing: CustomIconWidget(
              iconName: 'chevron_right',
              color: scheme.onSurface.withValues(alpha: 0.4),
              size: 20,
            ),
            onTap: _signOutAllDevices,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(ColorScheme scheme) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: SwitchListTile(
        secondary: CustomIconWidget(
          iconName: 'analytics',
          color: scheme.primary,
          size: 22,
        ),
        title: const Text('Help improve the app'),
        subtitle: const Text('Share anonymous usage data'),
        value: _isAnalyticsEnabled,
        onChanged: (enabled) async {
          setState(() => _isAnalyticsEnabled = enabled);
          await AnalyticsService.instance.setOptOut(!enabled);
        },
      ),
    );
  }

  Widget _buildAccountCard(ColorScheme scheme) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: CustomIconWidget(
          iconName: 'delete_forever',
          color: scheme.error,
          size: 22,
        ),
        title: Text(
          'Delete Account',
          style: TextStyle(
            color: scheme.error,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: const Text('Permanently delete all data'),
        trailing: CustomIconWidget(
          iconName: 'chevron_right',
          color: scheme.onSurface.withValues(alpha: 0.4),
          size: 20,
        ),
        onTap: _deleteAccount,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 2.w, bottom: 1.h),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
