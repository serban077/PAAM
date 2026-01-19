import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Notification Settings Section Widget
/// Provides granular control over workout reminders, progress updates, and motivational messages
class NotificationSettingsSectionWidget extends StatefulWidget {
  final bool workoutReminders;
  final bool progressUpdates;
  final bool motivationalMessages;
  final Function(Map<String, bool>) onUpdate;

  const NotificationSettingsSectionWidget({
    super.key,
    required this.workoutReminders,
    required this.progressUpdates,
    required this.motivationalMessages,
    required this.onUpdate,
  });

  @override
  State<NotificationSettingsSectionWidget> createState() =>
      _NotificationSettingsSectionWidgetState();
}

class _NotificationSettingsSectionWidgetState
    extends State<NotificationSettingsSectionWidget> {
  bool _isExpanded = false;
  late bool _workoutReminders;
  late bool _progressUpdates;
  late bool _motivationalMessages;

  @override
  void initState() {
    super.initState();
    _workoutReminders = widget.workoutReminders;
    _progressUpdates = widget.progressUpdates;
    _motivationalMessages = widget.motivationalMessages;
  }

  void _handleToggle(String type, bool value) {
    setState(() {
      switch (type) {
        case 'workout':
          _workoutReminders = value;
          break;
        case 'progress':
          _progressUpdates = value;
          break;
        case 'motivational':
          _motivationalMessages = value;
          break;
      }
    });

    // Auto-save on toggle
    widget.onUpdate({
      'workoutReminders': _workoutReminders,
      'progressUpdates': _progressUpdates,
      'motivationalMessages': _motivationalMessages,
    });
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
                      color: theme.colorScheme.tertiary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomIconWidget(
                      iconName: 'notifications',
                      color: theme.colorScheme.tertiary,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Setări Notificări',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          _getActiveNotificationsCount(),
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
                          // Workout Reminders
                          _buildNotificationToggle(
                            title: 'Memento-uri Antrenament',
                            description:
                                'Primește notificări pentru antrenamentele programate',
                            value: _workoutReminders,
                            onChanged: (value) =>
                                _handleToggle('workout', value),
                            theme: theme,
                          ),
                          SizedBox(height: 2.h),

                          // Progress Updates
                          _buildNotificationToggle(
                            title: 'Actualizări Progres',
                            description:
                                'Notificări săptămânale despre progresul tău',
                            value: _progressUpdates,
                            onChanged: (value) =>
                                _handleToggle('progress', value),
                            theme: theme,
                          ),
                          SizedBox(height: 2.h),

                          // Motivational Messages
                          _buildNotificationToggle(
                            title: 'Mesaje Motivaționale',
                            description:
                                'Primește citate și sfaturi motivaționale zilnice',
                            value: _motivationalMessages,
                            onChanged: (value) =>
                                _handleToggle('motivational', value),
                            theme: theme,
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

  Widget _buildNotificationToggle({
    required String title,
    required String description,
    required bool value,
    required Function(bool) onChanged,
    required ThemeData theme,
  }) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
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
          SizedBox(width: 3.w),
          Switch(
            value: value,
            onChanged: (newValue) {
              HapticFeedback.lightImpact();
              onChanged(newValue);
            },
          ),
        ],
      ),
    );
  }

  String _getActiveNotificationsCount() {
    int count = 0;
    if (_workoutReminders) count++;
    if (_progressUpdates) count++;
    if (_motivationalMessages) count++;

    return count == 0 ? 'Toate dezactivate' : '$count active';
  }
}
