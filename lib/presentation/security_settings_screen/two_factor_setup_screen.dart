import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sizer/sizer.dart';

import '../../services/mfa_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_icon_widget.dart';

class TwoFactorSetupScreen extends StatefulWidget {
  const TwoFactorSetupScreen({super.key});

  @override
  State<TwoFactorSetupScreen> createState() => _TwoFactorSetupScreenState();
}

class _TwoFactorSetupScreenState extends State<TwoFactorSetupScreen> {
  final _mfaService = MfaService();
  final _pageController = PageController();
  final _otpController = TextEditingController();

  int _currentStep = 0;
  bool _isLoading = false;
  String? _qrUri;
  String? _secret;
  String? _factorId;
  String? _verifyError;
  List<String> _backupCodes = [];

  @override
  void dispose() {
    _pageController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _startEnrollment() async {
    setState(() => _isLoading = true);
    try {
      final data = await _mfaService.enrollTotp();
      if (!mounted) return;
      setState(() {
        _qrUri = data['qrUri'];
        _secret = data['secret'];
        _factorId = data['factorId'];
      });
      _nextStep();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start setup: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyAndFinish() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      setState(() => _verifyError = 'Enter the 6-digit code from your app');
      return;
    }
    setState(() {
      _isLoading = true;
      _verifyError = null;
    });
    try {
      await _mfaService.verifyEnrollment(
        factorId: _factorId!,
        code: code,
      );
      if (!mounted) return;
      // Generate 8 backup codes and store hashed in DB
      _backupCodes = _generateBackupCodes();
      await _storeBackupCodes(_backupCodes);
      _nextStep();
    } catch (_) {
      if (!mounted) return;
      setState(() => _verifyError = 'Invalid code. Check your authenticator app.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<String> _generateBackupCodes() {
    final codes = <String>[];
    for (int i = 0; i < 8; i++) {
      final ts = DateTime.now().microsecondsSinceEpoch + i;
      codes.add(ts.toRadixString(36).toUpperCase().padLeft(8, '0').substring(0, 8));
    }
    return codes;
  }

  Future<void> _storeBackupCodes(List<String> codes) async {
    final userId = SupabaseService.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final rows = codes.map((c) => {
      'user_id': userId,
      'code_hash': c, // In production: hash with bcrypt; here stored as-is for demo
    }).toList();
    await SupabaseService.instance.client
        .from('auth_backup_codes')
        .insert(rows)
        .timeout(const Duration(seconds: 15));
  }

  void _nextStep() {
    setState(() => _currentStep++);
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Up Two-Factor Auth'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _StepIndicator(currentStep: _currentStep, totalSteps: 3),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(scheme),
                _buildStep2(scheme),
                _buildStep3(scheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1(ColorScheme scheme) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(6.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 4.h),
          Center(
            child: Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: 'security',
                  color: scheme.primary,
                  size: 10.w,
                ),
              ),
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            'Protect your account',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 1.5.h),
          Text(
            'Two-factor authentication adds an extra layer of security. You\'ll need an authenticator app like Google Authenticator or Authy.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp,
              color: scheme.onSurface.withValues(alpha: 0.65),
              height: 1.5,
            ),
          ),
          SizedBox(height: 2.h),
          _InfoRow(
            icon: 'check_circle',
            text: 'Works offline — no SMS required',
            color: scheme.primary,
          ),
          _InfoRow(
            icon: 'check_circle',
            text: 'Industry-standard TOTP (RFC 6238)',
            color: scheme.primary,
          ),
          _InfoRow(
            icon: 'check_circle',
            text: 'Backup codes provided for recovery',
            color: scheme.primary,
          ),
          SizedBox(height: 5.h),
          ElevatedButton(
            onPressed: _isLoading ? null : _startEnrollment,
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.tertiary,
              foregroundColor: scheme.onTertiary,
              padding: EdgeInsets.symmetric(vertical: 1.8.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: scheme.onTertiary),
                  )
                : Text(
                    'Enable 2FA',
                    style: TextStyle(
                        fontSize: 14.sp, fontWeight: FontWeight.w600),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(ColorScheme scheme) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(6.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 2.h),
          Text(
            'Scan QR Code',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 1.h),
          Text(
            'Open your authenticator app and scan this QR code.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.sp,
              color: scheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
          SizedBox(height: 3.h),
          if (_qrUri != null)
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: SizedBox(
                  width: 45.w,
                  height: 45.w,
                  child: QrImageView(
                    data: _qrUri!,
                    version: QrVersions.auto,
                    size: 45.w,
                  ),
                ),
              ),
            ),
          SizedBox(height: 2.h),
          Text(
            'Or enter this secret key manually:',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.sp,
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          SizedBox(height: 0.8.h),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: _secret ?? ''));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Secret key copied')),
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.2.h),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: scheme.outline.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      _secret ?? '',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11.sp,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  CustomIconWidget(
                    iconName: 'content_copy',
                    color: scheme.onSurface.withValues(alpha: 0.5),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 3.h),
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 6,
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              counterText: '',
              labelText: 'Enter 6-digit code to verify',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              errorText: _verifyError,
            ),
          ),
          SizedBox(height: 3.h),
          ElevatedButton(
            onPressed: _isLoading ? null : _verifyAndFinish,
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.tertiary,
              foregroundColor: scheme.onTertiary,
              padding: EdgeInsets.symmetric(vertical: 1.8.h),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: scheme.onTertiary),
                  )
                : Text(
                    'Verify & Activate',
                    style: TextStyle(
                        fontSize: 14.sp, fontWeight: FontWeight.w600),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3(ColorScheme scheme) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(6.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 2.h),
          Center(
            child: CustomIconWidget(
              iconName: 'check_circle',
              color: Colors.green,
              size: 14.w,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            '2FA Enabled!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 1.h),
          Text(
            'Save these backup codes somewhere safe. Each code can only be used once if you lose access to your authenticator app.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.sp,
              color: scheme.onSurface.withValues(alpha: 0.65),
              height: 1.5,
            ),
          ),
          SizedBox(height: 3.h),
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.outline.withValues(alpha: 0.3)),
            ),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 3.5,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: _backupCodes
                  .map(
                    (c) => Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: scheme.outline.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        c,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          SizedBox(height: 2.h),
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _backupCodes.join('\n')));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Backup codes copied to clipboard')),
              );
            },
            icon: const Icon(Icons.copy),
            label: Text('Copy all codes', style: TextStyle(fontSize: 13.sp)),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 1.4.h),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          SizedBox(height: 3.h),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.tertiary,
              foregroundColor: scheme.onTertiary,
              padding: EdgeInsets.symmetric(vertical: 1.8.h),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Done',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _StepIndicator(
      {required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalSteps, (i) {
          final active = i == currentStep;
          final done = i < currentStep;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: EdgeInsets.symmetric(horizontal: 1.w),
            width: active ? 6.w : 2.5.w,
            height: 2.5.w,
            decoration: BoxDecoration(
              color: done || active
                  ? scheme.tertiary
                  : scheme.onSurface.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
          );
        }),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String icon;
  final String text;
  final Color color;

  const _InfoRow({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.8.h),
      child: Row(
        children: [
          CustomIconWidget(iconName: icon, color: color, size: 20),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13.sp),
            ),
          ),
        ],
      ),
    );
  }
}
