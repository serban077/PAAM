import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Account Management Section Widget
/// Includes security options, data export, and account deletion
class AccountManagementSectionWidget extends StatefulWidget {
  const AccountManagementSectionWidget({super.key});

  @override
  State<AccountManagementSectionWidget> createState() =>
      _AccountManagementSectionWidgetState();
}

class _AccountManagementSectionWidgetState
    extends State<AccountManagementSectionWidget> {
  bool _isExpanded = false;

  void _handleChangePassword() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => _buildChangePasswordDialog(),
    );
  }

  void _handleExportData() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => _buildExportDataDialog(),
    );
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
                          'Gestionare Cont',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          'Securitate și confidențialitate',
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
                          // Change Password
                          _buildActionTile(
                            icon: 'lock',
                            title: 'Schimbă Parola',
                            description: 'Actualizează parola contului tău',
                            onTap: _handleChangePassword,
                            theme: theme,
                          ),
                          SizedBox(height: 2.h),

                          // Export Data
                          _buildActionTile(
                            icon: 'download',
                            title: 'Exportă Date',
                            description: 'Descarcă toate datele tale personale',
                            onTap: _handleExportData,
                            theme: theme,
                          ),
                          SizedBox(height: 2.h),

                          // Privacy Policy
                          _buildActionTile(
                            icon: 'privacy_tip',
                            title: 'Politica de Confidențialitate',
                            description:
                                'Conformitate GDPR pentru utilizatorii români',
                            onTap: () {
                              HapticFeedback.lightImpact();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Deschidere politică de confidențialitate...',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            theme: theme,
                          ),
                          SizedBox(height: 3.h),

                          // Delete Account
                          _buildActionTile(
                            icon: 'delete_forever',
                            title: 'Șterge Cont',
                            description:
                                'Șterge permanent contul și toate datele',
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

  Widget _buildChangePasswordDialog() {
    final theme = Theme.of(context);
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    return AlertDialog(
      title: Text('Schimbă Parola'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Parola Curentă',
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
                labelText: 'Parola Nouă',
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
                labelText: 'Confirmă Parola Nouă',
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
          onPressed: () => Navigator.pop(context),
          child: Text('Anulează'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Parola a fost schimbată cu succes'),
                backgroundColor: theme.colorScheme.primary,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: Text('Salvează'),
        ),
      ],
    );
  }

  Widget _buildExportDataDialog() {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text('Exportă Date'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vei primi un fișier cu toate datele tale personale în format JSON.',
            style: theme.textTheme.bodyMedium,
          ),
          SizedBox(height: 2.h),
          Text(
            'Acest fișier va include:',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text('• Informații profil', style: theme.textTheme.bodySmall),
          Text('• Istoric antrenamente', style: theme.textTheme.bodySmall),
          Text('• Date nutriționale', style: theme.textTheme.bodySmall),
          Text('• Progres și măsurători', style: theme.textTheme.bodySmall),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Anulează'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Datele tale sunt în curs de pregătire pentru export',
                ),
                backgroundColor: theme.colorScheme.primary,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: Text('Exportă'),
        ),
      ],
    );
  }

  Widget _buildDeleteAccountDialog() {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(
        'Șterge Cont',
        style: TextStyle(color: theme.colorScheme.error),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Această acțiune este permanentă și nu poate fi anulată.',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.error,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Toate datele tale vor fi șterse definitiv:',
            style: theme.textTheme.bodyMedium,
          ),
          SizedBox(height: 1.h),
          Text('• Profil și setări', style: theme.textTheme.bodySmall),
          Text('• Istoric antrenamente', style: theme.textTheme.bodySmall),
          Text('• Date nutriționale', style: theme.textTheme.bodySmall),
          Text('• Fotografii progres', style: theme.textTheme.bodySmall),
          SizedBox(height: 2.h),
          Text(
            'Ești sigur că vrei să continui?',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Anulează'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Contul tău a fost șters'),
                backgroundColor: theme.colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          child: Text('Șterge Cont'),
        ),
      ],
    );
  }
}
