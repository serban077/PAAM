import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class NutritionGenerationProgressWidget extends StatefulWidget {
  final double progressValue;
  final String progressMessage;
  final VoidCallback onCancel;

  const NutritionGenerationProgressWidget({
    super.key,
    required this.progressValue,
    required this.progressMessage,
    required this.onCancel,
  });

  @override
  State<NutritionGenerationProgressWidget> createState() =>
      _NutritionGenerationProgressWidgetState();
}

class _NutritionGenerationProgressWidgetState
    extends State<NutritionGenerationProgressWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _shimmerAnimation = Tween<double>(begin: 0.25, end: 0.6).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          // Progress card
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(26),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: CircularProgressIndicator(
                    value: widget.progressValue,
                    strokeWidth: 6,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.secondary,
                    ),
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  widget.progressMessage,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 1.h),
                Text(
                  '${(widget.progressValue * 100).round()}%',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 3.h),
                LinearProgressIndicator(
                  value: widget.progressValue,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.secondary,
                  ),
                ),
                SizedBox(height: 3.h),
                OutlinedButton.icon(
                  onPressed: widget.onCancel,
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(color: theme.colorScheme.error),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 3.h),
          // Shimmer skeleton cards — preview of upcoming nutrition plan
          Text(
            'Preparing your nutrition plan...',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 2.h),
          AnimatedBuilder(
            animation: _shimmerAnimation,
            builder: (context, child) {
              return Column(
                children: [
                  // Macro summary skeleton
                  Opacity(
                    opacity: _shimmerAnimation.value,
                    child: _buildMacroSkeletonCard(theme),
                  ),
                  SizedBox(height: 2.h),
                  // Meal cards skeleton
                  ...List.generate(3, (index) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 2.h),
                      child: Opacity(
                        opacity: (index == 0)
                            ? _shimmerAnimation.value
                            : (index == 1)
                                ? (_shimmerAnimation.value * 0.85)
                                    .clamp(0.1, 0.6)
                                : (_shimmerAnimation.value * 0.7)
                                    .clamp(0.1, 0.6),
                        child: _buildMealSkeletonCard(theme),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMacroSkeletonCard(ThemeData theme) {
    final shimmerColor = theme.colorScheme.onSurface.withAlpha(26);
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(3, (_) {
          return Column(
            children: [
              Container(
                width: 12.w,
                height: 12.w,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(height: 1.h),
              Container(
                width: 15.w,
                height: 1.5.h,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildMealSkeletonCard(ThemeData theme) {
    final shimmerColor = theme.colorScheme.onSurface.withAlpha(26);
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meal title row
          Row(
            children: [
              Container(
                width: 8.w,
                height: 8.w,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              SizedBox(width: 3.w),
              Container(
                width: 25.w,
                height: 2.h,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Spacer(),
              Container(
                width: 18.w,
                height: 1.5.h,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          // Food items
          ...List.generate(2, (_) {
            return Padding(
              padding: EdgeInsets.only(bottom: 1.h),
              child: Container(
                width: double.infinity,
                height: 1.5.h,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
          SizedBox(height: 1.h),
          // Macro chips row
          Row(
            children: List.generate(3, (i) {
              return Padding(
                padding: EdgeInsets.only(right: 2.w),
                child: Container(
                  width: 18.w,
                  height: 3.h,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
