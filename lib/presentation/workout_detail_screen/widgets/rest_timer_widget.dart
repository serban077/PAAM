import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Widget for displaying rest timer between sets
class RestTimerWidget extends StatefulWidget {
  final int restSeconds;
  final VoidCallback onTimerComplete;
  final VoidCallback onSkip;

  const RestTimerWidget({
    super.key,
    required this.restSeconds,
    required this.onTimerComplete,
    required this.onSkip,
  });

  @override
  State<RestTimerWidget> createState() => _RestTimerWidgetState();
}

class _RestTimerWidgetState extends State<RestTimerWidget>
    with SingleTickerProviderStateMixin {
  late int _remainingSeconds;
  Timer? _timer;
  bool _isPaused = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.restSeconds;
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.restSeconds),
    );
    _startTimer();
  }

  void _startTimer() {
    _animationController.forward();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
        if (_remainingSeconds == 3) {
          HapticFeedback.mediumImpact();
        }
      } else {
        _timer?.cancel();
        _animationController.stop();
        HapticFeedback.heavyImpact();
        widget.onTimerComplete();
      }
    });
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
    if (_isPaused) {
      _timer?.cancel();
      _animationController.stop();
    } else {
      _startTimer();
    }
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary, width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pauză între seturi',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              IconButton(
                icon: CustomIconWidget(
                  iconName: 'close',
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 24,
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  widget.onSkip();
                },
                tooltip: 'Închide',
              ),
            ],
          ),
          SizedBox(height: 2.h),
          SizedBox(
            width: 40.w,
            height: 40.w,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 40.w,
                  height: 40.w,
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return CircularProgressIndicator(
                        value: _animationController.value,
                        strokeWidth: 8,
                        backgroundColor: theme.colorScheme.outline.withValues(
                          alpha: 0.3,
                        ),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      );
                    },
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _formatTime(_remainingSeconds),
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                        fontSize: 48,
                      ),
                    ),
                    Text(
                      'secunde',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 3.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _togglePause,
                  icon: CustomIconWidget(
                    iconName: _isPaused ? 'play_arrow' : 'pause',
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  label: Text(_isPaused ? 'Reia' : 'Pauză'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    widget.onSkip();
                  },
                  icon: CustomIconWidget(
                    iconName: 'skip_next',
                    color: theme.colorScheme.onPrimary,
                    size: 24,
                  ),
                  label: const Text('Omite'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return minutes > 0
        ? '$minutes:${remainingSeconds.toString().padLeft(2, '0')}'
        : remainingSeconds.toString();
  }
}
