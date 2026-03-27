import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../widgets/custom_icon_widget.dart';

/// A single set input row: set label | weight field | reps field | check button.
/// Once completed, fields become read-only and row turns green.
class SetRowWidget extends StatefulWidget {
  final int setNumber;
  final int repsMin;
  final int repsMax;
  final bool isCompleted;
  final double? previousWeight; // prefill hint from last completed set

  /// Called when user taps the checkmark. reps is guaranteed non-null;
  /// weightKg is null for bodyweight exercises.
  final void Function(int reps, double? weightKg) onCompleted;

  const SetRowWidget({
    super.key,
    required this.setNumber,
    required this.repsMin,
    required this.repsMax,
    required this.isCompleted,
    required this.onCompleted,
    this.previousWeight,
  });

  @override
  State<SetRowWidget> createState() => _SetRowWidgetState();
}

class _SetRowWidgetState extends State<SetRowWidget> {
  late final TextEditingController _weightCtrl;
  late final TextEditingController _repsCtrl;

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(
      text: widget.previousWeight != null
          ? widget.previousWeight!.toStringAsFixed(
              widget.previousWeight! % 1 == 0 ? 0 : 1)
          : '',
    );
    _repsCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    super.dispose();
  }

  void _handleComplete() {
    final reps = int.tryParse(_repsCtrl.text.trim());
    if (reps == null || reps <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter the number of reps completed'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    final weight = double.tryParse(_weightCtrl.text.trim());
    HapticFeedback.lightImpact();
    widget.onCompleted(reps, weight);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completed = widget.isCompleted;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.2.h),
      decoration: BoxDecoration(
        color: completed
            ? theme.colorScheme.primary.withValues(alpha: 0.08)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: completed
              ? theme.colorScheme.primary.withValues(alpha: 0.4)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          // Set number label
          SizedBox(
            width: 10.w,
            child: Text(
              'Set ${widget.setNumber}',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: completed
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          SizedBox(width: 2.w),

          // Weight field
          Expanded(
            child: TextFormField(
              controller: _weightCtrl,
              enabled: !completed,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'BW',
                suffixText: 'kg',
                suffixStyle: theme.textTheme.labelSmall,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                    vertical: 1.h, horizontal: 2.w),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                filled: completed,
                fillColor: completed
                    ? theme.colorScheme.primary.withValues(alpha: 0.05)
                    : null,
              ),
            ),
          ),
          SizedBox(width: 2.w),

          // Reps field
          Expanded(
            child: TextFormField(
              controller: _repsCtrl,
              enabled: !completed,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: '${widget.repsMin}–${widget.repsMax}',
                suffixText: 'reps',
                suffixStyle: theme.textTheme.labelSmall,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                    vertical: 1.h, horizontal: 2.w),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                filled: completed,
                fillColor: completed
                    ? theme.colorScheme.primary.withValues(alpha: 0.05)
                    : null,
              ),
            ),
          ),
          SizedBox(width: 2.w),

          // Check / done button
          SizedBox(
            width: 10.w,
            height: 10.w,
            child: completed
                ? CustomIconWidget(
                    iconName: 'check_circle',
                    color: theme.colorScheme.primary,
                    size: 28,
                  )
                : IconButton(
                    onPressed: _handleComplete,
                    padding: EdgeInsets.zero,
                    icon: CustomIconWidget(
                      iconName: 'check_circle_outline',
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 28,
                    ),
                    tooltip: 'Mark set done',
                  ),
          ),
        ],
      ),
    );
  }
}
