import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/supabase_service.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Weight Progress Card — animated circular arc progress
class WeightProgressCard extends StatefulWidget {
  const WeightProgressCard({super.key});

  @override
  State<WeightProgressCard> createState() => _WeightProgressCardState();
}

class _WeightProgressCardState extends State<WeightProgressCard>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  double _startWeight = 0;
  double _currentWeight = 0;
  double _targetWeight = 0;
  late AnimationController _arcController;
  late Animation<double> _arcAnim;

  @override
  void initState() {
    super.initState();
    _arcController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _arcAnim = CurvedAnimation(
      parent: _arcController,
      curve: Curves.easeOutCubic,
    );
    _loadWeightData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadWeightData();
  }

  @override
  void dispose() {
    _arcController.dispose();
    super.dispose();
  }

  Future<void> _loadWeightData() async {
    try {
      setState(() => _isLoading = true);
      final userId =
          SupabaseService.instance.client.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final profile = await SupabaseService.instance.client
          .from('user_profiles')
          .select('weight_kg, current_weight_kg, target_weight_kg')
          .eq('id', userId)
          .single();
      if (mounted) {
        setState(() {
          _startWeight =
              (profile['weight_kg'] as num?)?.toDouble() ?? 0;
          _currentWeight =
              (profile['current_weight_kg'] as num?)?.toDouble() ??
                  _startWeight;
          _targetWeight =
              (profile['target_weight_kg'] as num?)?.toDouble() ?? 0;
          _isLoading = false;
        });
        _arcController.forward(from: 0);
      }
    } catch (e) {
      debugPrint('Error loading weight data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return _buildLoadingCard(theme);
    }

    // Determine goal direction
    final isGainingWeight = _targetWeight > _startWeight;
    final totalChange = (_targetWeight - _startWeight).abs();
    final currentChange = (_currentWeight - _startWeight).abs();
    final progress = totalChange != 0
        ? (currentChange / totalChange).clamp(0.0, 1.0)
        : 0.0;
    final progressPct = (progress * 100).round();
    final remaining = (_currentWeight - _targetWeight).abs();
    final isGoalReached = isGainingWeight
        ? _currentWeight >= _targetWeight
        : _currentWeight <= _targetWeight;
    final remainingLabel = isGoalReached
        ? 'Goal reached!'
        : isGainingWeight
            ? '${remaining.toStringAsFixed(1)} kg to gain'
            : '${remaining.toStringAsFixed(1)} kg to lose';

    final Color arcColor = progressPct >= 80
        ? theme.colorScheme.primary
        : theme.colorScheme.tertiary;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Card header
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        theme.colorScheme.primaryContainer
                            .withValues(alpha: 0.4),
                        theme.colorScheme.surface,
                      ]
                    : [
                        theme.colorScheme.primaryContainer
                            .withValues(alpha: 0.35),
                        theme.colorScheme.surface,
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20)),
            ),
            padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 2.h),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CustomIconWidget(
                    iconName: 'monitor_weight',
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                SizedBox(width: 3.w),
                Text(
                  'Weight Progress',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 3.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: isGoalReached
                        ? theme.colorScheme.primary.withValues(alpha: 0.12)
                        : theme.colorScheme.tertiary
                            .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isGoalReached ? 'Goal reached!' : 'In progress',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: isGoalReached
                          ? theme.colorScheme.primary
                          : theme.colorScheme.tertiary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 2.5.h),
            child: Row(
              children: [
                // Circular arc progress
                _buildCircularProgress(
                    theme, progress, progressPct, arcColor),
                SizedBox(width: 5.w),
                // Stats column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWeightRow(
                        theme,
                        label: 'Start',
                        value: _startWeight,
                        iconName: 'flag',
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      SizedBox(height: 1.2.h),
                      _buildWeightRow(
                        theme,
                        label: 'Current',
                        value: _currentWeight,
                        iconName: 'person',
                        color: theme.colorScheme.secondary,
                      ),
                      SizedBox(height: 1.2.h),
                      _buildWeightRow(
                        theme,
                        label: 'Target',
                        value: _targetWeight,
                        iconName: 'emoji_events',
                        color: theme.colorScheme.primary,
                      ),
                      SizedBox(height: 1.8.h),
                      // Remaining pill
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                            vertical: 1.h, horizontal: 3.w),
                        decoration: BoxDecoration(
                          color: isGoalReached
                              ? theme.colorScheme.primary
                                  .withValues(alpha: 0.1)
                              : theme.colorScheme.tertiary
                                  .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isGoalReached
                                ? theme.colorScheme.primary
                                    .withValues(alpha: 0.3)
                                : theme.colorScheme.tertiary
                                    .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CustomIconWidget(
                              iconName: isGoalReached
                                  ? 'check_circle'
                                  : 'trending_down',
                              color: isGoalReached
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.tertiary,
                              size: 14,
                            ),
                            SizedBox(width: 1.5.w),
                            Flexible(
                              child: Text(
                                remainingLabel,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.bold,
                                  color: isGoalReached
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.tertiary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularProgress(
    ThemeData theme,
    double progress,
    int progressPct,
    Color arcColor,
  ) {
    return SizedBox(
      width: 28.w,
      height: 28.w,
      child: AnimatedBuilder(
        animation: _arcAnim,
        builder: (_, __) {
          final animatedProgress = progress * _arcAnim.value;
          return CustomPaint(
            painter: _ArcProgressPainter(
              progress: animatedProgress,
              trackColor: theme.colorScheme.outline.withValues(alpha: 0.15),
              arcColor: arcColor,
              strokeWidth: 8,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<int>(
                    tween: IntTween(
                        begin: 0,
                        end: (progressPct * _arcAnim.value).round()),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOut,
                    builder: (_, val, __) => Text(
                      '$val%',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: arcColor,
                      ),
                    ),
                  ),
                  Text(
                    'done',
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeightRow(
    ThemeData theme, {
    required String label,
    required double value,
    required String iconName,
    required Color color,
  }) {
    return Row(
      children: [
        CustomIconWidget(iconName: iconName, color: color, size: 14),
        SizedBox(width: 2.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          '${value.toStringAsFixed(1)} kg',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingCard(ThemeData theme) {
    return Container(
      height: 20.h,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: CircularProgressIndicator(
          color: theme.colorScheme.primary,
          strokeWidth: 2.5,
        ),
      ),
    );
  }
}

/// Custom arc painter for circular progress
class _ArcProgressPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color arcColor;
  final double strokeWidth;

  const _ArcProgressPainter({
    required this.progress,
    required this.trackColor,
    required this.arcColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    const startAngle = -math.pi * 0.8;
    const sweepFull = math.pi * 1.6;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final arcPaint = Paint()
      ..color = arcColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepFull,
      false,
      trackPaint,
    );

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepFull * progress,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcProgressPainter old) =>
      old.progress != progress || old.arcColor != arcColor;
}
