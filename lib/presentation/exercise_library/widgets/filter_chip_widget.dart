import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class FilterChipWidget extends StatelessWidget {
  final String label;
  final VoidCallback onDeleted;

  const FilterChipWidget({
    super.key,
    required this.label,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(right: 2.w),
      child: Chip(
        label: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        deleteIcon: CustomIconWidget(
          iconName: 'close',
          color: theme.colorScheme.primary,
          size: 16,
        ),
        onDeleted: onDeleted,
        backgroundColor: theme.colorScheme.primaryContainer,
        side: BorderSide.none,
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      ),
    );
  }
}
