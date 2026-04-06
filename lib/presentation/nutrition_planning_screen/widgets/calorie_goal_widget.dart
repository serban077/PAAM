import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:percent_indicator/percent_indicator.dart';

/// Calorie ring card.
/// [onGradient] = true → glass card style for use on gradient header.
/// [onGradient] = false (default) → surface card style.
class CalorieGoalWidget extends StatelessWidget {
  final double dailyGoal;
  final double consumed;
  final bool onGradient;

  const CalorieGoalWidget({
    super.key,
    required this.dailyGoal,
    required this.consumed,
    this.onGradient = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final remaining = dailyGoal - consumed;
    final percentage = dailyGoal > 0 ? (consumed / dailyGoal).clamp(0.0, 1.0) : 0.0;
    final isOver = consumed > dailyGoal;

    // Colors vary by mode
    final ringProgress = onGradient
        ? Colors.white
        : (isOver ? theme.colorScheme.error : theme.colorScheme.primary);
    final ringBg = onGradient
        ? Colors.white.withValues(alpha: 0.25)
        : theme.colorScheme.primaryContainer.withValues(alpha: 0.30);
    final textColor = onGradient ? Colors.white : theme.colorScheme.onSurface;
    final mutedColor = onGradient
        ? Colors.white.withValues(alpha: 0.72)
        : theme.colorScheme.onSurfaceVariant;
    final accentColor = onGradient
        ? const Color(0xFFFFD54F)    // amber on gradient
        : (isOver ? theme.colorScheme.error : theme.colorScheme.secondary);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5.w),
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: onGradient
          ? BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
            )
          : BoxDecoration(
              color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.10),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
      child: Row(
        children: [
          // ── Ring ──
          CircularPercentIndicator(
            radius: 13.w,
            lineWidth: 2.2.w,
            percent: percentage,
            progressColor: ringProgress,
            backgroundColor: ringBg,
            circularStrokeCap: CircularStrokeCap.round,
            animation: true,
            animationDuration: 900,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  consumed.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    height: 1.0,
                  ),
                ),
                Text(
                  'kcal',
                  style: TextStyle(
                    fontSize: 9.sp,
                    color: mutedColor,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 4.w),
          // ── Stats ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _statRow('Goal', '${dailyGoal.toStringAsFixed(0)} kcal', mutedColor, textColor),
                SizedBox(height: 1.h),
                _statRow('Consumed', '${consumed.toStringAsFixed(0)} kcal', mutedColor, ringProgress),
                SizedBox(height: 1.h),
                _statRow(
                  isOver ? 'Over budget' : 'Remaining',
                  '${remaining.abs().toStringAsFixed(0)} kcal',
                  mutedColor,
                  isOver ? (onGradient ? const Color(0xFFFF5252) : theme.colorScheme.error) : accentColor,
                ),
                SizedBox(height: 1.2.h),
                // ── Progress bar ──
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage,
                    minHeight: 0.6.h,
                    backgroundColor: ringBg,
                    valueColor: AlwaysStoppedAnimation<Color>(ringProgress),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value, Color labelColor, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10.sp, color: labelColor),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
