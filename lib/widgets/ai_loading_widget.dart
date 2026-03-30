import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sizer/sizer.dart';

import 'custom_icon_widget.dart';

/// A premium, animated loading widget for AI-powered operations.
///
/// Shows a pulsating ring with icon center, animated step progress dots,
/// crossfading status messages, and detailed shimmer skeletons.
class AILoadingWidget extends StatefulWidget {
  /// The icon displayed in the center of the pulsating ring.
  final String iconName;

  /// The main title displayed below the animation (e.g. "Analyzing ingredients...").
  final String title;

  /// Status messages that rotate every 3 seconds with a crossfade.
  final List<String> statusMessages;

  /// Step labels shown as progress dots (e.g. ["Scan", "Match", "Build"]).
  final List<String> stepLabels;

  /// Which step is currently active (0-indexed).
  final int activeStep;

  /// Shimmer skeleton builder for the content preview below.
  /// If null, uses default rectangular skeletons.
  final Widget Function(ThemeData theme)? skeletonBuilder;

  const AILoadingWidget({
    super.key,
    required this.iconName,
    required this.title,
    required this.statusMessages,
    this.stepLabels = const [],
    this.activeStep = 0,
    this.skeletonBuilder,
  });

  @override
  State<AILoadingWidget> createState() => _AILoadingWidgetState();
}

class _AILoadingWidgetState extends State<AILoadingWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _pulseScale;
  late Animation<double> _pulseOpacity;
  late Animation<double> _glowOpacity;
  int _messageIndex = 0;

  @override
  void initState() {
    super.initState();

    // Pulsating ring animation — spring-like feel
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutCubic),
    );
    _pulseOpacity = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _glowOpacity = Tween<double>(begin: 0.08, end: 0.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Slow rotating arc
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _cycleMessages();
  }

  Future<void> _cycleMessages() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      setState(() {
        _messageIndex = (_messageIndex + 1) % widget.statusMessages.length;
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5.w),
      child: Column(
        children: [
          SizedBox(height: 5.h),

          // ── Pulsating ring + icon center ──
          AnimatedBuilder(
            animation: Listenable.merge([_pulseController, _rotateController]),
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseScale.value,
                child: SizedBox(
                  width: 28.w,
                  height: 28.w,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer glow
                      Container(
                        width: 28.w,
                        height: 28.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primary.withValues(
                                  alpha: _glowOpacity.value),
                              blurRadius: 32,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      // Outer track ring
                      SizedBox(
                        width: 26.w,
                        height: 26.w,
                        child: CircularProgressIndicator(
                          value: 1.0,
                          strokeWidth: 3,
                          color: primary.withValues(alpha: 0.1),
                        ),
                      ),
                      // Rotating arc
                      Transform.rotate(
                        angle: _rotateController.value * 2 * math.pi,
                        child: SizedBox(
                          width: 26.w,
                          height: 26.w,
                          child: CircularProgressIndicator(
                            value: 0.3,
                            strokeWidth: 3,
                            strokeCap: StrokeCap.round,
                            color: primary.withValues(
                                alpha: _pulseOpacity.value),
                            backgroundColor: Colors.transparent,
                          ),
                        ),
                      ),
                      // Inner frosted circle + icon
                      Container(
                        width: 18.w,
                        height: 18.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primary.withValues(alpha: 0.08),
                          border: Border.all(
                            color: primary.withValues(alpha: 0.15),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: CustomIconWidget(
                            iconName: widget.iconName,
                            size: 28,
                            color: primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          SizedBox(height: 3.h),

          // ── Title ──
          Text(
            widget.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),

          SizedBox(height: 0.8.h),

          // ── Animated status text ──
          SizedBox(
            height: 3.h,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: Text(
                widget.statusMessages[_messageIndex],
                key: ValueKey(_messageIndex),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),

          // ── Step dots ──
          if (widget.stepLabels.isNotEmpty) ...[
            SizedBox(height: 2.5.h),
            _StepDots(
              labels: widget.stepLabels,
              activeStep: widget.activeStep,
              primary: primary,
              theme: theme,
            ),
          ],

          SizedBox(height: 3.h),

          // ── Shimmer skeleton ──
          Expanded(
            child: widget.skeletonBuilder != null
                ? widget.skeletonBuilder!(theme)
                : _DefaultSkeleton(theme: theme),
          ),
        ],
      ),
    );
  }
}

// ── Step Dots ─────────────────────────────────────────────────────────────────

class _StepDots extends StatelessWidget {
  final List<String> labels;
  final int activeStep;
  final Color primary;
  final ThemeData theme;

  const _StepDots({
    required this.labels,
    required this.activeStep,
    required this.primary,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(labels.length, (i) {
        final isActive = i == activeStep;
        final isDone = i < activeStep;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (i > 0)
              Container(
                width: 6.w,
                height: 1.5,
                color: isDone
                    ? primary.withValues(alpha: 0.5)
                    : theme.colorScheme.outlineVariant,
              ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  width: isActive ? 10 : 8,
                  height: isActive ? 10 : 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone || isActive
                        ? primary
                        : theme.colorScheme.outlineVariant,
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: primary.withValues(alpha: 0.4),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 8.5.sp,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isDone || isActive
                        ? primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }
}

// ── Default Skeleton ──────────────────────────────────────────────────────────

class _DefaultSkeleton extends StatelessWidget {
  final ThemeData theme;

  const _DefaultSkeleton({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: theme.colorScheme.surfaceContainerHighest,
      highlightColor: theme.colorScheme.surfaceContainerLow,
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        separatorBuilder: (_, __) => SizedBox(height: 1.5.h),
        itemBuilder: (_, __) => Container(
          height: 10.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

// ── Ingredient Skeleton ───────────────────────────────────────────────────────

/// Detailed shimmer skeleton mimicking the ingredient list layout.
class IngredientListSkeleton extends StatelessWidget {
  final ThemeData theme;

  const IngredientListSkeleton({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: theme.colorScheme.surfaceContainerHighest,
      highlightColor: theme.colorScheme.surfaceContainerLow,
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        separatorBuilder: (_, __) => SizedBox(height: 1.h),
        itemBuilder: (_, index) => Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.2.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Category icon placeholder
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Container(
                      height: 1.6.h,
                      width: (30 + index * 8).w.clamp(30.w, 55.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    SizedBox(height: 0.6.h),
                    // Category + quantity
                    Row(
                      children: [
                        Container(
                          height: 1.2.h,
                          width: 14.w,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Container(
                          height: 1.2.h,
                          width: 10.w,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Action icons placeholder
              Container(
                width: 8.w,
                height: 3.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Recipe Card Skeleton ──────────────────────────────────────────────────────

/// Detailed shimmer skeleton mimicking the recipe card layout.
class RecipeCardSkeleton extends StatelessWidget {
  final ThemeData theme;

  const RecipeCardSkeleton({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: theme.colorScheme.surfaceContainerHighest,
      highlightColor: theme.colorScheme.surfaceContainerLow,
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 1.w),
        itemCount: 3,
        separatorBuilder: (_, __) => SizedBox(height: 1.5.h),
        itemBuilder: (_, __) => Container(
          padding: EdgeInsets.all(3.5.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + difficulty badge
              Row(
                children: [
                  Container(
                    height: 2.h,
                    width: 45.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    height: 2.h,
                    width: 12.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 1.h),
              // Description
              Container(
                height: 1.4.h,
                width: 65.w,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(height: 1.5.h),
              // Macro chips
              Row(
                children: List.generate(
                  4,
                  (_) => Padding(
                    padding: EdgeInsets.only(right: 2.w),
                    child: Container(
                      height: 2.4.h,
                      width: 16.w,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 1.5.h),
              // Time + button row
              Row(
                children: [
                  Container(
                    height: 1.4.h,
                    width: 18.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Container(
                    height: 1.4.h,
                    width: 20.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    height: 4.h,
                    width: 20.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
