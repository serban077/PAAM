import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class GenerationProgressWidget extends StatefulWidget {
  final double progressValue;
  final String progressMessage;
  final VoidCallback onCancel;
  final String? streamingText;

  const GenerationProgressWidget({
    super.key,
    required this.progressValue,
    required this.progressMessage,
    required this.onCancel,
    this.streamingText,
  });

  @override
  State<GenerationProgressWidget> createState() =>
      _GenerationProgressWidgetState();
}

class _GenerationProgressWidgetState extends State<GenerationProgressWidget>
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
                      theme.colorScheme.primary,
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
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 3.h),
                LinearProgressIndicator(
                  value: widget.progressValue,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
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
          if (widget.streamingText != null && widget.streamingText!.isNotEmpty)
            // Live token preview while streaming
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(180),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.primary.withAlpha(51),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Generating...',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    widget.streamingText!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontFamily: 'monospace',
                      fontSize: 10.sp,
                    ),
                    maxLines: 8,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            )
          else ...[
            // Shimmer skeleton cards — shown before streaming starts
            Text(
              'Preparing your workout plan...',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 2.h),
            AnimatedBuilder(
              animation: _shimmerAnimation,
              builder: (context, child) {
                return Column(
                  children: List.generate(3, (index) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 2.h),
                      child: Opacity(
                        opacity: (index == 0)
                            ? _shimmerAnimation.value
                            : (index == 1)
                                ? (_shimmerAnimation.value * 0.85).clamp(0.1, 0.6)
                                : (_shimmerAnimation.value * 0.7).clamp(0.1, 0.6),
                        child: _buildSkeletonCard(theme),
                      ),
                    );
                  }),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSkeletonCard(ThemeData theme) {
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
          // Day title
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
                width: 30.w,
                height: 2.h,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Spacer(),
              Container(
                width: 15.w,
                height: 1.5.h,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          // Exercise rows
          ...List.generate(2, (_) {
            return Padding(
              padding: EdgeInsets.only(bottom: 1.h),
              child: Row(
                children: [
                  Container(
                    width: 40.w,
                    height: 1.5.h,
                    decoration: BoxDecoration(
                      color: shimmerColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 20.w,
                    height: 1.5.h,
                    decoration: BoxDecoration(
                      color: shimmerColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
