import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Account Management Section Widget
/// Includes security options, data export, and account deletion
class AccountManagementSectionWidget extends StatefulWidget {
  final VoidCallback onLogout;

  const AccountManagementSectionWidget({
    super.key,
    required this.onLogout,
  });

  @override
  State<AccountManagementSectionWidget> createState() =>
      _AccountManagementSectionWidgetState();
}

class _AccountManagementSectionWidgetState
    extends State<AccountManagementSectionWidget> {
  bool _isExpanded = false;

  void _handleChangePassword() async {
    HapticFeedback.lightImpact();

    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Change Password'),
          content: IntrinsicHeight(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: 2.h),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: 2.h),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (newPasswordController.text !=
                    confirmPasswordController.text) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text('Passwords do not match'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }

                Navigator.pop(dialogContext, true);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password changed successfully'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleExportData() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => _buildExportDataDialog(),
    );
  }

  void _handleSignOut() async {
    HapticFeedback.lightImpact();
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Sign Out'),
        content: Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('Sign Out'),
          ),
        ],
      ),
    );

    if (shouldSignOut != true) return;

    widget.onLogout();
  }

  void _handleDeleteAccount() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => _buildDeleteAccountDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomIconWidget(
                      iconName: 'settings',
                      color: theme.colorScheme.error,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account Management',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          'Security & privacy',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CustomIconWidget(
                    iconName: _isExpanded ? 'expand_less' : 'expand_more',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content
          _isExpanded
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Divider(height: 1, color: theme.colorScheme.outline),
                    Padding(
                      padding: EdgeInsets.all(4.w),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildActionTile(
                            icon: 'lock',
                            title: 'Change Password',
                            description: 'Update your account password',
                            onTap: _handleChangePassword,
                            theme: theme,
                          ),
                          SizedBox(height: 2.h),

                          _buildActionTile(
                            icon: 'download',
                            title: 'Export Data',
                            description: 'Download all your personal data',
                            onTap: _handleExportData,
                            theme: theme,
                          ),
                          SizedBox(height: 2.h),

                          _buildActionTile(
                            icon: 'privacy_tip',
                            title: 'Privacy Policy',
                            description: 'View our privacy policy',
                            onTap: () {
                              HapticFeedback.lightImpact();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Opening privacy policy...'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            theme: theme,
                          ),
                          SizedBox(height: 3.h),

                          _buildActionTile(
                            icon: 'logout',
                            title: 'Sign Out',
                            description: 'Sign out of your account',
                            onTap: _handleSignOut,
                            theme: theme,
                            isDestructive: true,
                          ),
                          SizedBox(height: 2.h),

                          _buildActionTile(
                            icon: 'delete_forever',
                            title: 'Delete Account',
                            description:
                                'Permanently delete your account and all data',
                            onTap: _handleDeleteAccount,
                            theme: theme,
                            isDestructive: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required String icon,
    required String title,
    required String description,
    required VoidCallback onTap,
    required ThemeData theme,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDestructive
                ? theme.colorScheme.error.withValues(alpha: 0.3)
                : theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: isDestructive
                    ? theme.colorScheme.error.withValues(alpha: 0.1)
                    : theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomIconWidget(
                iconName: icon,
                color: isDestructive
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
                size: 20,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isDestructive ? theme.colorScheme.error : null,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            CustomIconWidget(
              iconName: 'chevron_right',
              color: theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportDataDialog() {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text('Export Data'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You will receive a file with all your personal data in JSON format.',
            style: theme.textTheme.bodyMedium,
          ),
          SizedBox(height: 2.h),
          Text(
            'This file will include:',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text('• Profile information', style: theme.textTheme.bodySmall),
          Text('• Workout history', style: theme.textTheme.bodySmall),
          Text('• Nutrition data', style: theme.textTheme.bodySmall),
          Text('• Progress & measurements', style: theme.textTheme.bodySmall),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Your data is being prepared for export'),
                backgroundColor: theme.colorScheme.primary,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: Text('Export'),
        ),
      ],
    );
  }

  Widget _buildDeleteAccountDialog() {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(
        'Delete Account',
        style: TextStyle(color: theme.colorScheme.error),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This action is permanent and cannot be undone.',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.error,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'All your data will be permanently deleted:',
            style: theme.textTheme.bodyMedium,
          ),
          SizedBox(height: 1.h),
          Text('• Profile & settings', style: theme.textTheme.bodySmall),
          Text('• Workout history', style: theme.textTheme.bodySmall),
          Text('• Nutrition data', style: theme.textTheme.bodySmall),
          Text('• Progress photos', style: theme.textTheme.bodySmall),
          SizedBox(height: 2.h),
          Text(
            'Are you sure you want to continue?',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Your account has been deleted'),
                backgroundColor: theme.colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          child: Text('Delete Account'),
        ),
      ],
    );
  }
}
