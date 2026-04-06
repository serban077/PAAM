import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../../services/supabase_service.dart';

class WeeklyCalendarWidget extends StatefulWidget {
  final Function(String sessionId) onSessionSelected;

  const WeeklyCalendarWidget({
    super.key,
    required this.onSessionSelected,
  });

  @override
  State<WeeklyCalendarWidget> createState() => _WeeklyCalendarWidgetState();
}

class _WeeklyCalendarWidgetState extends State<WeeklyCalendarWidget> {
  DateTime _selectedDate = DateTime.now();
  Map<DateTime, Map<String, dynamic>> _scheduledSessions = {};
  Map<DateTime, bool> _completedSessions = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWeeklySchedule();
  }

  Future<void> _loadWeeklySchedule() async {
    try {
      final userId = SupabaseService.instance.client.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final scheduleResponse = await SupabaseService.instance.client
          .from('user_workout_schedules')
          .select('plan_id, start_date')
          .eq('user_id', userId)
          .eq('is_active', true)
          .maybeSingle();

      if (scheduleResponse == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final planId = scheduleResponse['plan_id'];

      final sessionsResponse = await SupabaseService.instance.client
          .from('workout_sessions')
          .select('id, day_number, session_name, focus_area')
          .eq('plan_id', planId);

      final Map<DateTime, Map<String, dynamic>> sessionMap = {};
      final List<dynamic> sessions = sessionsResponse as List<dynamic>;

      final now = DateTime.now();
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final startOfWeek = DateTime(monday.year, monday.month, monday.day);
      final endOfWeek = startOfWeek.add(const Duration(days: 7));

      for (var session in sessions) {
        final dayNum = session['day_number'] as int;
        if (dayNum >= 1 && dayNum <= 7) {
          final sessionDate = startOfWeek.add(Duration(days: dayNum - 1));
          sessionMap[sessionDate] = session;
        }
      }

      final logsResponse = await SupabaseService.instance.client
          .from('workout_logs')
          .select('completed_at, session_id')
          .eq('user_id', userId)
          .gte('completed_at', startOfWeek.toIso8601String())
          .lt('completed_at', endOfWeek.toIso8601String());

      final Map<DateTime, bool> completedMap = {};
      for (var log in logsResponse) {
        final completedDate =
            DateTime.parse(log['completed_at']).toLocal();
        final dateKey = DateTime(
            completedDate.year, completedDate.month, completedDate.day);
        completedMap[dateKey] = true;
      }

      if (mounted) {
        setState(() {
          _scheduledSessions = sessionMap;
          _completedSessions = completedMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading schedule: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Container(
        height: 17.h,
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

    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final today = DateTime(now.year, now.month, now.day);

    // Compute week stats
    int completedThisWeek = 0;
    int scheduledThisWeek = 0;
    for (int i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));
      final dateOnly = DateTime(date.year, date.month, date.day);
      final hasWorkout = _scheduledSessions.entries.any(
        (e) => e.key.isAtSameMomentAs(dateOnly) && e.value.isNotEmpty,
      );
      if (hasWorkout) {
        scheduledThisWeek++;
        if (_completedSessions.containsKey(dateOnly)) completedThisWeek++;
      }
    }

    final weekProgress = scheduledThisWeek > 0
        ? completedThisWeek / scheduledThisWeek
        : 0.0;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: EdgeInsets.fromLTRB(4.w, 2.h, 3.w, 0.5.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'This Week',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: EdgeInsets.symmetric(
                      horizontal: 3.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$completedThisWeek / $scheduledThisWeek done',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Day chips
          SizedBox(
            height: 11.5.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 3.w),
              itemCount: 7,
              itemBuilder: (context, index) {
                final date = startOfWeek.add(Duration(days: index));
                final dateOnly =
                    DateTime(date.year, date.month, date.day);
                final isSelected = _selectedDate.day == date.day &&
                    _selectedDate.month == date.month;
                final isToday = today.isAtSameMomentAs(dateOnly);

                final session = _scheduledSessions.entries.firstWhere(
                  (entry) => entry.key.isAtSameMomentAs(dateOnly),
                  orElse: () => MapEntry(dateOnly, {}),
                ).value;

                final hasWorkout = session.isNotEmpty;
                final isCompleted =
                    _completedSessions.containsKey(dateOnly);
                final isMissed = hasWorkout &&
                    !isCompleted &&
                    dateOnly.isBefore(today);

                Color dotColor;
                if (isCompleted) {
                  dotColor = theme.colorScheme.primary;
                } else if (isMissed) {
                  dotColor = theme.colorScheme.error;
                } else if (hasWorkout) {
                  dotColor = theme.colorScheme.tertiary;
                } else {
                  dotColor =
                      theme.colorScheme.outline.withValues(alpha: 0.25);
                }

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedDate = dateOnly);
                    if (hasWorkout) {
                      widget.onSessionSelected(session['id']);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                              'No workout scheduled for this day.'),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    width: 11.5.w,
                    margin: EdgeInsets.symmetric(
                        horizontal: 1.w, vertical: 1.h),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : isToday
                              ? theme.colorScheme.primaryContainer
                                  .withValues(alpha: 0.55)
                              : theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(14),
                      border: isToday && !isSelected
                          ? Border.all(
                              color: theme.colorScheme.primary,
                              width: 1.5,
                            )
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.38),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('E', 'en_US')
                              .format(date)
                              .toUpperCase()
                              .substring(0, 1),
                          style: GoogleFonts.inter(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.8)
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: 0.4.h),
                        Text(
                          date.day.toString(),
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: hasWorkout ? 6.0 : 4.0,
                          height: hasWorkout ? 6.0 : 4.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? Colors.white : dotColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Week progress bar
          Padding(
            padding: EdgeInsets.fromLTRB(4.w, 0.5.h, 4.w, 2.h),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Week completion',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: weekProgress),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOut,
                      builder: (_, value, __) => Text(
                        '${(value * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 0.7.h),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: weekProgress),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOut,
                  builder: (_, value, __) => ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: 7,
                      backgroundColor:
                          theme.colorScheme.outline.withValues(alpha: 0.18),
                      valueColor: AlwaysStoppedAnimation(
                        value >= 0.8
                            ? theme.colorScheme.primary
                            : theme.colorScheme.tertiary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
